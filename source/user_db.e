--****
-- == User database support
-- 

namespace user_db

include std/convert.e
include std/error.e
include std/get.e
include std/sequence.e

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
	return defaulted_value(mysql_query_object(db, "SELECT COUNT(id) FROM users WHERE user=%s LIMIT 1", { code }), 0)
end function

public function is_email_used(sequence email)
	return defaulted_value(mysql_query_object(db, "SELECT COUNT(id) FROM users WHERE email=%s LIMIT 1", { email }), 0)
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

public function get_by_login(sequence code, sequence password)
	object u = mysql_query_one(db, "SELECT " & select_fields & 
		" FROM users WHERE (user=%s OR email=%s) AND password=%s LIMIT 1", 
		{ code, code, md5hex(salt(code,password)) })
	
	if atom(u) then
		return { 0, "Invalid account" }
	end if
	
	if equal(u[USER_DISABLED], "1") then
		return { 0, "Your account is disabled. Reason: " & u[USER_DISABLED_REASON] }
	end if
	
	u &= { get_roles(defaulted_value(u[USER_ID], -1)) }

	return u
end function

public function get_by_code(sequence code)
	object user = mysql_query_one(db, "SELECT " & select_fields & " FROM users WHERE user=%s", { code })
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

public procedure set_user_ip(sequence user, sequence ip)
	mysql_query(db, "UPDATE users SET ip_addr=%s, login_time=CURRENT_TIMESTAMP WHERE id=%s", { 
		ip, user[USER_ID] })
end procedure

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
