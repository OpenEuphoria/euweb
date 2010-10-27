--****
-- == User database support
--

namespace user_db

include std/convert.e
include std/error.e
include std/get.e
include std/sequence.e
include std/datetime.e
include std/text.e

include edbi/edbi.e

include webclay/logging.e as log
include db.e
include md5.e

global object current_user = 0
global enum USER_ID, USER_NAME, USER_FULL_NAME, USER_LOCATION, USER_EMAIL, USER_SHOW_EMAIL,
	USER_LAST_LOGIN_AT, USER_DISABLED, USER_DISABLED_REASON, USER_IP_ADDR,
	USER_FORUM_DEFAULT_VIEW, USER_LOCAL_JS, USER_ROLES

constant select_fields = `id, user, name, location, email, show_email, login_time, disabled,
	disabled_reason, ip_addr, forum_default_view, local_js`

function salt(sequence salt, sequence message)
  integer s = 1, m = 1, ret
  sequence new = ""

  if length(salt) = 0 then
  	-- someone put in an empty username
	salt = " "
  end if

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
	return edbi:query_object("SELECT COUNT(id) FROM users WHERE LOWER(user)=LOWER(%s) LIMIT 1", { code })
end function

public function is_email_used(sequence email)
	return edbi:query_object("SELECT COUNT(id) FROM users WHERE LOWER(email)=LOWER(%s) LIMIT 1", { email })
end function

function get_roles(integer id)
	object roles = edbi:query_rows("SELECT role_name FROM user_roles WHERE user_id=%d", { id })
	if atom(roles) then
		return {}
	end if

	for i = 1 to length(roles) do
		roles[i] = roles[i][1]
	end for

	return roles
end function

public function get(integer id)
    object user = edbi:query_row("SELECT " & select_fields & " FROM users WHERE id=%d", { id })
    if atom(user) then
    	return 0
	end if

	user &= { get_roles(id) }

	return user
end function

public function get_by_sess_id(sequence sess_id, sequence ip)
	object user = edbi:query_row("SELECT " & select_fields & " FROM users WHERE sess_id=%s", { sess_id })
	if atom(user) then
		return 0
	end if

	user &= { get_roles(user[USER_ID]) }

	return user
end function

public function get_by_login(sequence code, sequence password)
	-- try the new method first, it's hoped that it will become the most common
	object u = edbi:query_row("SELECT " & select_fields &
		" FROM users WHERE (LOWER(user)=LOWER(%s) OR LOWER(email)=LOWER(%s)) AND password=SHA1(%s)",
		{ code, code, password })

	if atom(u) then
		ifdef X86_64 then
			u = edbi:query_row("SELECT " & select_fields &
				" FROM users WHERE user=%s AND password=md5(%s) LIMIT 1",
				{ code, salt(code,password) })
		elsedef
			u = edbi:query_row("SELECT " & select_fields &
				" FROM users WHERE user=%s AND password=%s LIMIT 1",
				{ code, md5hex(salt(code,password)) })
		end ifdef
		if atom(u) then
			return { 0, "Invalid account" }
		end if

		-- if we are here, then there was a successful MD5 password match
		-- we can safely update the password to the new SHA1 format now
		update_password(code, password)
	end if

	if u[USER_DISABLED] then
		return { 0, "Your account is disabled. Reason: " & u[USER_DISABLED_REASON] }
	end if

	u &= { get_roles(u[USER_ID]) }

	return u
end function

public function get_by_code(sequence code)
	object user = edbi:query_row("SELECT " & select_fields & " FROM users WHERE LOWER(user)=LOWER(%s) OR LOWER(email)=LOWER(%s)", { code, code })
    if atom(user) then
    	return 0
	end if

	user &= { get_roles(user[USER_ID]) }

	return user
end function

global function has_role(sequence role, object user=current_user)
	if atom(user) then
		return 0
	end if

	if length(user) >= USER_ROLES and sequence(user[USER_ROLES]) then
		if find("admin", user[USER_ROLES]) then
			return 1
		end if

		return find(role, user[USER_ROLES])
	else
		-- user must be just a user name
		object o = edbi:query_object(`SELECT ur.role_name
			FROM user_roles ur, users u
			WHERE u.id=ur.user_id AND ur.role_name=%s AND u.user=%s`, { role, user })
		return sequence(o)
	end if
end function

public function set_user_ip(sequence user, sequence ip)
	datetime rnd = datetime:now()
	sequence sk = datetime:format(rnd, "%S.#%m") & ip &
		datetime:format(rnd, "%S%Y&(*") & user[USER_NAME] &
		datetime:format(rnd, "%s$%M!%H#%Y@%m*%de.<\"")

	edbi:execute("UPDATE users SET sess_id=SHA1(%s), ip_addr=%s, login_time=CURRENT_TIMESTAMP WHERE id=%d", {
		sk, ip, user[USER_ID] })

	return edbi:query_object("SELECT sess_id FROM users WHERE id=%d", { user[USER_ID] })
end function

public function create(sequence code, sequence password, sequence email)
	if edbi:execute("INSERT INTO users (user, password, email) VALUES (%s,SHA1(%s),%s)", {
		code, password, email })
	then
		crash("Couldn't insert user into the database: %s", { edbi:error_message() })
	end if

	integer id = edbi:last_insert_id()
	edbi:execute("INSERT INTO user_roles (role_name, user_id) VALUES ('user', %d)", { id })

	return id
end function

public procedure remove_role(sequence uname, sequence role)
	edbi:execute("DELETE ur FROM user_roles ur, users u WHERE u.user=%s AND ur.user_id=u.id AND ur.role_name=%s",
		{ uname, role })
end procedure

public procedure add_role(sequence uname, sequence role)
	object uid = edbi:query_object("SELECT id FROM users WHERE user=%s", { uname })
	if uid > 0 then
		edbi:execute("INSERT INTO user_roles (user_id, role_name) VALUES (%d,%s)", { uid, role })
	end if
end procedure

public procedure disable(sequence uname, sequence reason)
	edbi:execute("UPDATE users SET disabled=1, disabled_reason=%s WHERE user=%s", {
		reason, uname })
end procedure

public procedure enable(sequence uname)
	edbi:execute("UPDATE users SET disabled=0 WHERE user=%s", { uname })
end procedure

public procedure set_password(sequence uname, sequence password)
	edbi:execute("UPDATE users SET password=SHA1(%s) WHERE user=%s", {
		password, uname })
end procedure

public function is_old_account(sequence user)
	object o = edbi:query_row("SELECT LENGTH(password), LENGTH(security_question), LENGTH(security_answer) FROM users WHERE user=%s", { user[USER_NAME] })
	if sequence(o) then
		-- OLD password
		if o[1] < 40 then
			return 1
		end if

		-- No security question
		if sequence(o[2]) or o[2] = 0 then
			return 1
		end if

		-- No security answer
		if sequence(o[3]) or o[3] = 0 then
			return 1
		end if
	end if

	return 0
end function

public function update_security(sequence uname, sequence security_question, sequence security_answer,
		sequence password)
	object result = edbi:execute(`UPDATE users SET security_question=%s,
		security_answer=SHA1(LOWER(%s)), password=SHA1(%s) WHERE LOWER(user)=LOWER(%s)`, {
			security_question, security_answer, password, uname})

	if result then
		return 0
	end if

	return 1
end function

public function get_security_question(sequence uname)
	return edbi:query_object("SELECT security_question FROM users WHERE user=%s", { uname })
end function

public function is_security_ok(sequence uname, sequence security_answer)
	return sequence(edbi:query_object("SELECT user FROM users WHERE user=%s AND security_answer=SHA1(LOWER(%s))", {
		uname, security_answer }))
end function

public function update_password(sequence uname, sequence password)
	return edbi:execute("UPDATE users SET password=SHA1(%s) WHERE user=%s", { password, uname })
end function

public procedure update_last_login(sequence user)
 	edbi:execute("UPDATE users SET login_time=CURRENT_TIMESTAMP WHERE user=%s", { user[USER_NAME] })
end procedure

public function get_recent_users(integer limit=10)
	return edbi:query_rows("SELECT user, login_time FROM users ORDER BY login_time DESC LIMIT %d", {
		limit })
end function

--**
-- Get the number of users

public function count(sequence where = "")
    sequence sql = "SELECT COUNT(id) FROM users"
    if length(where) > 0 then
		sql &= " WHERE " & where
    end if

	return edbi:query_object(sql)
end function

--**
-- Get a list of users

public function get_list(integer offset=0, integer per_page=10, sequence where="",
		sequence sort="")
	sequence sql = "SELECT " & select_fields & " FROM users"
	if length(where) then
		sql &= " WHERE " & where
	end if
	sql &= " ORDER BY " & sort
	sql &= " LIMIT %d OFFSET %d"

	log:log(sql, { per_page, offset })

	return edbi:query_rows(sql, { per_page, offset })
end function
