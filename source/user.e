--****
-- == User module
--

-- StdLib includes
include std/datetime.e as dt
include std/error.e
include std/map.e
include std/search.e
include std/net/http.e
include std/net/url.e
include std/types.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

-- Templates
include templates/security.etml as t_security
include templates/user/profile.etml as t_profile
include templates/user/profile_edit.etml as t_profile_edit
include templates/user/profile_edit_ok.etml as t_profile_edit_ok
include templates/user/login_form.etml as t_login_form
include templates/user/login_ok.etml as t_login_ok
include templates/user/logout_ok.etml as t_logout_ok
include templates/user/signup.etml as t_signup
include templates/user/signup_ok.etml as t_signup_ok
include templates/user/old_account.etml as t_old_account
include templates/user/update_ok.etml as t_update_ok
include templates/user/forgot_password.etml as t_forgot_password
include templates/user/forgot_password_ok.etml as t_forgot_password_ok
include templates/user/list.etml as t_list

-- Local includes
include config.e
include db.e
include format.e
include fuzzydate.e
include user_db.e
include dump.e

procedure _login(sequence u)
	datetime rightnow = dt:now(), expire
	sequence sess_id = set_user_ip(u, server_var("REMOTE_ADDR"))
	expire = dt:add(rightnow, 1, YEARS)

	wc:add_cookie("euweb_sessinfo", sess_id, "/", expire)
end procedure

sequence profile_invars = {
	{ wc:SEQUENCE, "user" }
}

public function profile(map data, map invars)
	if atom(current_user) then
		return { TEXT, t_security:template(data) }
	end if

	sequence uname = map:get(invars, "user")

	-- If the current user is an admin, check on the query string for admin
	-- actions that may take place
	if has_role("user_admin") then
		log:log("User adim, yes")
		if sequence(map:get(invars, "remove_role")) then
			user_db:remove_role(uname, map:get(invars, "remove_role"))
		elsif sequence(map:get(invars, "add_role")) then
			log:log("add_role, yes")
			user_db:add_role(uname, map:get(invars, "add_role"))
		elsif sequence(map:get(invars, "disabled_reason")) then
			user_db:disable(uname, map:get(invars, "disabled_reason"))
		elsif sequence(map:get(invars, "enable")) then
			user_db:enable(uname)
		elsif sequence(map:get(invars, "password")) then
			user_db:set_password(uname, map:get(invars, "password"))
		end if
	end if

	object user = user_db:get_by_code(map:get(invars, "user"))
	if atom(user) then
		map:put(data, "invalid_profile", 1)
		map:put(data, "user_name", map:get(invars, "user"))

		return { TEXT, t_profile:template(data) }
	end if

	map:put(data, "invalid_profile", 0)

	user[USER_LAST_LOGIN_AT] = fuzzy_ago(user[USER_LAST_LOGIN_AT])

	map:put(data, "user", user)
	map:put(data, "user_id", user[USER_ID])
	map:put(data, "user_name", user[USER_NAME])
	map:put(data, "user_location", user[USER_LOCATION])
	map:put(data, "user_full_name", user[USER_FULL_NAME])
	map:put(data, "user_show_email", user[USER_SHOW_EMAIL])
	map:put(data, "user_email", user[USER_EMAIL])
	map:put(data, "user_last_seen", user[USER_LAST_LOGIN_AT])
	map:put(data, "user_disabled", user[USER_DISABLED])
	map:put(data, "user_disabled_reason", user[USER_DISABLED_REASON])
	map:put(data, "user_ip_addr", user[USER_IP_ADDR])
	map:put(data, "user_local_js", user[USER_LOCAL_JS])
	map:put(data, "user_roles", user[USER_ROLES])

	return { TEXT, t_profile:template(data) }
end function
wc:add_handler(routine_id("profile"), -1, "user", "profile", profile_invars)

public function login_form(map data, map invars)

	return { TEXT, t_login_form:template(data) }
end function
wc:add_handler(routine_id("login_form"), -1, "user", "login")
wc:add_handler(routine_id("login_form"), -1, "login", "index")

sequence login_invars = {
	{ wc:SEQUENCE, "code" },
	{ wc:SEQUENCE, "password" }
}

public function validate_do_login(integer data, map vars)
	sequence errors = wc:new_errors("user", "login")

	if atom(map:get(vars, "code")) then
		dump_map("user_login", vars)
	end if

	sequence code = map:get(vars, "code")

	-- Only do data validation if doing a login, the other option here is that
	-- the user has forgotten their password.

	if equal(map:get(vars, "login"), "Login") then
		sequence password = map:get(vars, "password")
		sequence u = user_db:get_by_login(code, password)
		if atom(u[1]) and u[1] = 0 then
			errors = wc:add_error(errors, "form", u[2])
		end if
	else
		object u = user_db:get_by_code(code)
		if atom(u) then
			errors = wc:add_error(errors, "form", "Invalid user code")
		elsif is_old_account(u) then
			errors = wc:add_error(errors, "user", `User account is an old account and
				does not support password resetting. You must contact a system
				administrator for assistance`)
		end if
	end if

	return errors
end function

public function do_login(map data, map invars)
	if equal(map:get(invars, "login"), "Forgot Password") or
		sequence(map:get(invars, "security_answer", 0))
	then
		object u = user_db:get_by_code(map:get(invars, "code"))

		map:put(data, "re_public_key", RECAPTCHA_PUBLIC_KEY)
		map:put(data, "security_question", user_db:get_security_question(u[USER_NAME]))
		map:put(data, "security_answer", map:get(invars, "security_answer", ""))
		map:put(data, "code", u[USER_NAME])

		return { TEXT, t_forgot_password:template(data) }

	elsif sequence(map:get(invars, "update_account")) then
		map:copy(invars, data)

		return { TEXT, t_old_account:template(data) }
	else
		current_user = user_db:get_by_login(map:get(invars, "code"), map:get(invars, "password"))

		_login(current_user)

		if user_db:is_old_account(current_user) then
			return { TEXT, t_old_account:template(data) }
		else
			return { TEXT, t_login_ok:template(data) }
		end if
	end if
end function
wc:add_handler(routine_id("do_login"), routine_id("validate_do_login"), "user", "do_login", login_invars)

public function signup(map data, map invars)
	map:copy(invars, data)
	map:put(data, "re_public_key", RECAPTCHA_PUBLIC_KEY)

	return { TEXT, t_signup:template(data) }
end function
wc:add_handler(routine_id("signup"), -1, "user", "signup")
wc:add_handler(routine_id("signup"), -1, "signup", "index")

sequence signup_invars = {
	{ wc:SEQUENCE, "code" },
	{ wc:SEQUENCE, "password" },
	{ wc:SEQUENCE, "password_confirm" },
	{ wc:SEQUENCE, "email" },
	{ wc:SEQUENCE, "recaptcha_challenge_field" },
	{ wc:SEQUENCE, "recaptcha_response_field" },
	{ wc:SEQUENCE, "login" },
	{ wc:SEQUENCE, "forgot_password" }
}

function validate_do_signup(integer data, map:map vars)
	sequence errors = wc:new_errors("user", "signup")

	sequence code = map:get(vars, "code")
	if length(code) < 4 then
		errors = wc:add_error(errors, "code", "User code must be at least 4 characters long")
	elsif not t_identifier(code) then
		errors = wc:add_error(errors, "code", "User code contains an invalid character, please re-read the user code rules.")
	elsif is_code_used(code) then
		errors = wc:add_error(errors, "code", "User code is already in use.")
	end if

	sequence password=map:get(vars, "password"), password_confirm=map:get(vars, "password_confirm")
	if length(password) < 5 then
		errors = wc:add_error(errors, "password", "Password must be at least 5 characters long.")
	elsif not equal(password, password_confirm) then
		errors = wc:add_error(errors, "password", "Password and password confirmation do not match.")
	end if

	sequence email = map:get(vars, "email")
	if not valid:valid_email(email) then
		errors = wc:add_error(errors, "email", "Email is invalid")
	elsif is_email_used(email) then
		errors = wc:add_error(errors, "email", "Email is already in use.")
	end if

	-- No reason to do the costly tests if we already have errors.
	if not has_errors(errors) then
		sequence recaptcha_url = "http://api-verify.recaptcha.net/verify"
		sequence postdata = sprintf("privatekey=%s&remoteip=%s&challenge=%s&response=%s", {
			url:encode(RECAPTCHA_PRIVATE_KEY), url:encode(server_var("REMOTE_ADDR")),
			url:encode(map:get(vars, "recaptcha_challenge_field")),
			url:encode(map:get(vars, "recaptcha_response_field")) })

		if length(RECAPTCHA_PUBLIC_KEY) then
			object recaptcha_result = get_url(recaptcha_url, postdata)
			if length(recaptcha_result) < 2  then
				errors = wc:add_error(errors, "recaptcha", "Could not validate reCAPTCHA.")
			elsif not match("true", recaptcha_result[2]) = 1 then
				errors = wc:add_error(errors, "recaptcha", "reCAPTCHA response was incorrect.")
			end if
		end if
	end if

	return errors
end function

public function do_signup(map data, map invars)
	user_db:create(map:get(invars, "code"), map:get(invars, "password"),
		map:get(invars, "email"))

	current_user = user_db:get_by_login(map:get(invars, "code"), map:get(invars, "password"))
	_login(current_user)

	return { TEXT, t_signup_ok:template(data) }
end function
wc:add_handler(routine_id("do_signup"), routine_id("validate_do_signup"), "user", "do_signup",
	signup_invars)

public function logout(map data, map invars)
	datetime past = datetime:now()
	past = datetime:add(past, -2, YEARS)
	wc:add_cookie("euweb_sessinfo", "logout", "/", past)
	current_user = 0
	return { TEXT, t_logout_ok:template(data) }
end function
wc:add_handler(routine_id("logout"), -1, "user", "logout")
wc:add_handler(routine_id("logout"), -1, "logout", "index")

sequence update_account_invars = {
	{ wc:SEQUENCE, "security_question" },
	{ wc:SEQUENCE, "security_answer" },
	{ wc:SEQUENCE, "password" },
	{ wc:SEQUENCE, "password_confirm" }
}

function validate_update_account(integer data, map:map vars)
	sequence errors = wc:new_errors("user", "do_login")

	sequence security_question = map:get(vars, "security_question")
	if length(security_question) = 0 then
		errors = wc:add_error(errors, "security_question", "Security question cannot be empty.")
	end if

	sequence security_answer = map:get(vars, "security_answer")
	if length(security_answer) = 0 then
		errors = wc:add_error(errors, "security_answer", "Security answer cannot be empty.")
	end if

	sequence password=map:get(vars, "password"), password_confirm=map:get(vars, "password_confirm")
	if length(password) < 5 then
		errors = wc:add_error(errors, "password", "Password must be at least 5 characters long.")
	elsif not equal(password, password_confirm) then
		errors = wc:add_error(errors, "password", "Password and password confirmation do not match.")
	end if

	return errors
end function

public function update_account(map data, map invars)
	user_db:update_security(current_user[USER_NAME], map:get(invars, "security_question"),
		map:get(invars, "security_answer"), map:get(invars, "password"))

	return { TEXT, t_update_ok:template(data) }
end function
wc:add_handler(routine_id("update_account"), routine_id("validate_update_account"),
	"user", "update_account", update_account_invars)

sequence forgot_password_invars = {
	{ wc:SEQUENCE, "code", "" },
 	{ wc:SEQUENCE, "security_answer", "" },
	{ wc:SEQUENCE, "password", "" },
	{ wc:SEQUENCE, "password_confirm", "" },
	{ wc:SEQUENCE, "recaptcha_challenge_field", "" },
	{ wc:SEQUENCE, "recaptcha_response_field", "" }
}

public function validate_forgot_password(integer data, map vars)
	sequence errors = wc:new_errors("user", "do_login")

	sequence code = map:get(vars, "code")
	sequence password=map:get(vars, "password"), password_confirm=map:get(vars, "password_confirm")
	sequence security_answer = map:get(vars, "security_answer")

	if length(password) < 5 then
		errors = wc:add_error(errors, "password", "Password must be at least 5 characters long.")
	elsif not equal(password, password_confirm) then
		errors = wc:add_error(errors, "password", "Password and password confirmation do not match.")
	end if

	if not is_security_ok(code, security_answer) then
		errors = wc:add_error(errors, "security_answer", "Security answer is incorrect")
	end if

	-- No reason to do the costly tests if we already have errors.
	if not has_errors(errors) then
		sequence recaptcha_url = "http://api-verify.recaptcha.net/verify"
		sequence postdata = sprintf("privatekey=%s&remoteip=%s&challenge=%s&response=%s", {
			url:encode(RECAPTCHA_PRIVATE_KEY), url:encode(server_var("REMOTE_ADDR")),
			url:encode(map:get(vars, "recaptcha_challenge_field")),
			url:encode(map:get(vars, "recaptcha_response_field")) })

		object recaptcha_result = get_url(recaptcha_url, postdata)
		if length(recaptcha_result) < 2 then
	 		errors = wc:add_error(errors, "recaptcha", "Could not validate reCAPTCHA.")
		elsif not match("true", recaptcha_result[2]) = 1 then
			errors = wc:add_error(errors, "recaptcha", "reCAPTCHA response was incorrect.")
		end if
	end if

	return errors
end function

public function forgot_password(map data, map invars)
	user_db:update_password(map:get(invars, "code"), map:get(invars, "password"))

	current_user = user_db:get_by_login(map:get(invars, "code"), map:get(invars, "password"))
	_login(current_user)

	return { TEXT, t_forgot_password_ok:template(data) }
end function
wc:add_handler(routine_id("forgot_password"), routine_id("validate_forgot_password"),
	"user", "forgot_password", forgot_password_invars)

sequence profile_edit_invars = {
	{ wc:SEQUENCE, "user", "" }
}

function profile_edit(map data, map invars)
	object u = user_db:get_by_code(map:get(invars, "user"))
	if atom(u) then
		crash("Invalid user code %s", { map:get(invars, "user") })
	end if

	if not has_role("user_admin") then
		if not equal(current_user[USER_ID], u[USER_ID]) then
			return { TEXT, t_security:template(data) }
		end if
	end if

	map:put(data, "id", u[USER_ID])
	map:put(data, "user", u[USER_NAME])
	map:put(data, "full_name", u[USER_FULL_NAME])
	map:put(data, "location", u[USER_LOCATION])
	map:put(data, "email", u[USER_EMAIL])
	map:put(data, "show_email", u[USER_SHOW_EMAIL])
	map:put(data, "forum_default_view", u[USER_FORUM_DEFAULT_VIEW])
	map:put(data, "local_js", u[USER_LOCAL_JS])

	if map:has(invars, "post") then
		map:copy(invars, data)
	end if

	return { TEXT, t_profile_edit:template(data) }
end function
wc:add_handler(routine_id("profile_edit"), -1, "user", "profile_edit", profile_edit_invars)

sequence profile_save_invars = {
	{ wc:SEQUENCE, "user", "" },
	{ wc:SEQUENCE, "full_name", "" },
	{ wc:SEQUENCE, "location", "" },
	{ wc:SEQUENCE, "show_email", "off" },
	{ wc:SEQUENCE, "forum_default_view", 1 },
	{ wc:INTEGER, "local_js", 0 },
	{ wc:SEQUENCE, "password", "" }
}

function validate_profile_save(map data, map vars)
	sequence errors = wc:new_errors("user", "profile_edit")

	object u = user_db:get_by_code(map:get(vars, "user"))
	if atom(u) then
		errors = wc:add_error(errors, "form", "Invalid user code")
	end if

	if not has_role("user_admin") then
		if not equal(current_user[USER_ID], u[USER_ID]) then
			errors = wc:add_error(errors, "form", "You are not authorized to edit this profile")
		end if
	end if

	if not valid:valid_email(map:get(vars, "email")) then
		errors = wc:add_error(errors, "email", "Email is invalid")
	end if

	sequence password=map:get(vars, "password"), password_confirm=map:get(vars, "password_confirm")

	-- Only validate password if they have supplied a new one.
	if length(password) > 0 then
		if length(password) < 5 then
			errors = wc:add_error(errors, "password", "Password must be at least 5 characters long.")
		elsif not equal(password, password_confirm) then
			errors = wc:add_error(errors, "password", "Password and password confirmation do not match.")
		end if
	end if

	return errors
end function

function profile_save(map data, map vars)
	object r = edbi:execute(`UPDATE users SET name=%s, location=%s, forum_default_view=%s,
		show_email=%d, email=%s, login_time=login_time, local_js=%d WHERE user=%s`, {
			map:get(vars, "full_name"),
			map:get(vars, "location"),
			map:get(vars, "forum_default_view"),
			equal("on", map:get(vars, "show_email")),
			map:get(vars, "email"),
			map:get(vars, "local_js" ),
			map:get(vars, "user")
		})
	if length(map:get(vars, "password")) then
		user_db:update_password(map:get(vars, "user"), map:get(vars, "password"))
	end if

	map:put(data, "user", map:get(vars, "user"))

	return { TEXT, t_profile_edit_ok:template(data) }
end function
wc:add_handler(routine_id("profile_save"), routine_id("validate_profile_save"),
	"user", "profile_save", profile_save_invars)

constant user_list_invars = {
	{ wc:INTEGER,  "per_page", 20 },
	{ wc:INTEGER,  "page",		1 },
	{ wc:SEQUENCE, "search",   "" },
	{ wc:INTEGER,  "sort_id",   1 }
}

constant user_list_sort = {
	"user",           -- 1
	"user DESC",      -- 2
	"login_time",     -- 3
	"login_time DESC" -- 4
}

function user_list(map data, map request)
	if not has_role("user_admin") then
		return { TEXT, t_security:template(data) }
	end if

	integer per_page = map:get(request, "per_page")
	integer page	 = map:get(request, "page")
	integer sort_id  = map:get(request, "sort_id")
	sequence search	 = map:get(request, "search")
	integer offset	 = (page - 1) * per_page

	map:copy(request, data)

	sequence users, where = ""

	if length(search) then
		sequence safeSearch = match_replace("\\",
					match_replace("'",
						match_replace("*", search, "%%", 0),
					"''", 0),
				"\\\\")

		where = sprintf("user LIKE '%s' OR email LIKE '%s'", {
			safeSearch, safeSearch })
	end if

	users = user_db:get_list(offset, per_page, where, user_list_sort[sort_id])

	for i = 1 to length(users) do
		users[i][USER_LAST_LOGIN_AT] = fuzzy_ago(users[i][USER_LAST_LOGIN_AT])
	end for

	map:put(data, "users", users)
	map:put(data, "user_count", user_db:count(where))

	return { TEXT, t_list:template(data) }
end function
wc:add_handler(routine_id("user_list"), -1, "user", "list", user_list_invars)
