--****
-- == User database support
-- 

namespace user_db

include std/convert.e
include std/error.e
include std/get.e
include std/sequence.e
include std/datetime.e

include webclay/logging.e as log
include db.e
include md5.e

global object current_user = 0
global enum USER_ID, USER_NAME, USER_EMAIL, USER_LAST_LOGIN_AT, USER_DISABLED, 
	USER_DISABLED_REASON, USER_IP_ADDR, USER_ROLES

constant select_fields = "id, user, email, login_time, disabled, disabled_reason, ip_addr"

function salt(sequence salt, sequence message)
  integer s = 1, m = 1, ret
  sequence new = ""
  while m < length(message) do
    if s > length(salt) then
      s = 1
    end if
    ret = salt[s] + message[m]
    new &= int_to_bytes(ret)
    s += 1
    m += 1
  end while
  return new
end function

public function is_code_used(sequence code)
	return defaulted_value(mysql_query_object(db, "SELECT COUNT(id) FROM users WHERE LOWER(user)=LOWER(%s) LIMIT 1", { code }), 0)
end function

public function is_email_used(sequence email)
	return defaulted_value(mysql_query_object(db, "SELECT COUNT(id) FROM users WHERE LOWER(email)=LOWER(%s) LIMIT 1", { email }), 0)
end function

function get_roles(integer id)
	object roles = mysql_query_rows(db, "SELECT role_name FROM user_roles WHERE user_id=%d", { id })
	if atom(roles) then
		return {}
	else
		for i = 1 to length(roles) do
			roles[i] = roles[i][1] 
		end for

		return roles
	end if
end function

public function get(integer id)
    object user = mysql_query_one(db, "SELECT " & select_fields & " FROM users WHERE id=%d", { id })
    if atom(user) then
    	return 0
	end if
	
	user &= { get_roles(id) }

	return user
end function

public function get_by_sess_id(sequence sess_id, sequence ip)
	object user = mysql_query_one(db, "SELECT " & select_fields & " FROM users WHERE sess_id=%s AND ip_addr=%s", {
		sess_id, ip })
	if atom(user) then
		return 0
	end if
	
	user &= { get_roles(defaulted_value(user[USER_ID], 0)) }
	
	return user
end function

public function get_by_login(sequence code, sequence password)
	object u
	
	-- try the new method first, it's hoped that it will become the most common
	u = mysql_query_one(db, "SELECT " & select_fields & 
		" FROM users WHERE (LOWER(user)=LOWER(%s) OR LOWER(email)=LOWER(%s)) AND password=SHA1(%s)",
		{ code, code, password })
	
	if atom(u) then
		u = mysql_query_one(db, "SELECT " & select_fields & 
			" FROM users WHERE user=%s AND password=%s LIMIT 1", 
			{ code, md5hex(salt(code,password)) })
		
		if atom(u) then
			return { 0, "Invalid account" }
		end if
	end if
	
	if equal(u[USER_DISABLED], "1") then
		return { 0, "Your account is disabled. Reason: " & u[USER_DISABLED_REASON] }
	end if
	
	u &= { get_roles(defaulted_value(u[USER_ID], -1)) }

	return u
end function

public function get_by_code(sequence code)
	object user = mysql_query_one(db, "SELECT " & select_fields & " FROM users WHERE LOWER(user)=LOWER(%s) OR LOWER(email)=LOWER(%s)", { code, code })
    if atom(user) then
    	return 0
	end if
	
	user &= { get_roles(defaulted_value(user[USER_ID], 0)) }

	return user
end function

global function has_role(sequence role, object user=current_user)
	if atom(user) then 
		return 0
	end if
		
	if find("admin", user[USER_ROLES]) then
		return 1
	end if 

	return find(role, user[USER_ROLES])
end function

public function set_user_ip(sequence user, sequence ip)
	datetime rnd = datetime:now()
	sequence sk = datetime:format(rnd, "%S.#%m") & ip & 
		datetime:format(rnd, "%S%Y&(*") & user[USER_NAME] &
		datetime:format(rnd, "%s$%M!%H#%Y@%m*%de.<\"")

	mysql_query(db, "UPDATE users SET sess_id=SHA1(%s), ip_addr=%s, login_time=CURRENT_TIMESTAMP WHERE id=%s", { 
		sk, ip, user[USER_ID] })
	
	return mysql_query_object(db, "SELECT sess_id FROM users WHERE id=%s", { user[USER_ID] })
end function

public function create(sequence code, sequence password, sequence email)
	if mysql_query(db, "INSERT INTO users (user, password, email) VALUES (%s,%s,%s)", {
		code, md5hex(salt(code,password)), email })
	then
		crash("Couldn't insert user into the database: %s", { mysql_error(db) })
	end if
	
	integer id = mysql_insert_id(db)
	mysql_query(db, "INSERT INTO user_roles (role_name, user_id) VALUES ('user', %d)", { id })
	
	return id
end function

public procedure remove_role(sequence uname, sequence role)
	mysql_query(db, "DELETE ur FROM user_roles ur, users u WHERE u.user=%s AND ur.user_id=u.id AND ur.role_name=%s",
		{ uname, role })
end procedure

public procedure add_role(sequence uname, sequence role)
	object uid = mysql_query_object(db, "SELECT id FROM users WHERE user=%s", { uname })
	if atom(uid) then
		return
	end if

	mysql_query(db, "INSERT INTO user_roles (user_id, role_name) VALUES (%s,%s)",
		{ uid, role })
end procedure

public procedure disable(sequence uname, sequence reason)
	mysql_query(db, "UPDATE users SET disabled=1, disabled_reason=%s WHERE user=%s", {
		reason, uname })
end procedure

public procedure enable(sequence uname)
	mysql_query(db, "UPDATE users SET disabled=0 WHERE user=%s", { uname })
end procedure

public procedure set_password(sequence uname, sequence password)
	mysql_query(db, "UPDATE users SET password=%s WHERE user=%s", { 
		md5hex(salt(uname,password)), uname })
end procedure

public function is_old_account(sequence user)
	object o = mysql_query_object(db, "SELECT LENGTH(password) FROM users WHERE user=%s", { user[USER_NAME] })
	if sequence(o) then
		if defaulted_value(o, 0) < 40 then
			return 1
		end if
	end if
	
	return 0
end function

public function update_security(sequence uname, sequence security_question, sequence security_answer,
		sequence password)
	object result = mysql_query(db, `UPDATE users SET security_question=%s, 
		security_answer=SHA1(LOWER(%s)), password=SHA1(%s) WHERE LOWER(user)=LOWER(%s)`, {
			security_question, security_answer, password, uname})

	if result then
		return 0
	end if
	
	return 1
end function

public function get_security_question(sequence uname)
	return mysql_query_object(db, "SELECT security_question FROM users WHERE user=%s", { uname })
end function

public function is_security_ok(sequence uname, sequence security_answer)
	return sequence(mysql_query_object(db, "SELECT id FROM users WHERE user=%s AND security_answer=SHA1(LOWER(%s))", {
		uname, security_answer }))
end function

public function update_password(sequence uname, sequence password)
	return mysql_query(db, "UPDATE users SET password=SHA1(%s) WHERE user=%s", { password, uname })
end function
