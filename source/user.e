--****
-- == User module
-- 

-- StdLib includes
include std/datetime.e as dt
include std/error.e
include std/map.e
include std/net/http.e
include std/types.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log
include webclay/url.e as url

-- Templates
include templates/user/profile.etml as t_profile
include templates/user/login_form.etml as t_login_form
include templates/user/login_ok.etml as t_login_ok
include templates/user/logout_ok.etml as t_logout_ok
include templates/user/signup.etml as t_signup
include templates/user/signup_ok.etml as t_signup_ok

-- Local includes
include config.e 
include db.e
include format.e
include fuzzydate.e
include user_db.e

sequence profile_invars = {
	{ wc:SEQUENCE, "user" }
}

public function profile(map data, map invars)
	sequence uname = map:get(invars, "user")

	-- If the current user is an admin, check on the query string for admin
	-- actions that may take place
	if has_role("user_admin") then
		if sequence(map:get(invars, "remove_role")) then
			user_db:remove_role(uname, map:get(invars, "remove_role"))
		elsif sequence(map:get(invars, "add_role")) then
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
		crash("User %s could not be located", { map:get(invars, "user") })
	end if

	user[USER_LAST_LOGIN_AT] = fuzzy_ago(sqlDateTimeToDateTime(user[USER_LAST_LOGIN_AT]))

	map:put(data, "user", user)

	return { TEXT, t_profile:template(data) }
end function
wc:add_handler(routine_id("profile"), -1, "user", "profile", profile_invars)

public function login_form(map data, map invars)

	return { TEXT, t_login_form:template(data) }
end function
wc:add_handler(routine_id("login_form"), -1, "user", "login")
wc:add_handler(routine_id("login_form"), -1, "login", "index")

sequence login_invars = {
	{ wc:SEQUENCE, "code", "" },
	{ wc:SEQUENCE, "password", "" }
}

public function validate_do_login(integer data, map vars)
	sequence errors = wc:new_errors("user", "login")
	
	sequence code = map:get(vars, "code")
	sequence password = map:get(vars, "password")
	sequence u = user_db:get_by_login(code, password)
	if atom(u[1]) and u[1] = 0 then
		errors = wc:add_error(errors, "form", u[2])
	end if

	return errors	
end function

public function do_login(map data, map invars)
	datetime rightnow = dt:now(), expire

	current_user = user_db:get_by_login(map:get(invars, "code"), map:get(invars, "password"))
	set_user_ip(current_user, server_var("REMOTE_ADDR"))
	expire = dt:add(rightnow, 1, YEARS)

    wc:add_cookie("euweb_sessinfo", current_user[USER_ID], "/", expire)

	return { TEXT, t_login_ok:template(data) }
end function
wc:add_handler(routine_id("do_login"), routine_id("validate_do_login"), "user", "do_login")

public function signup(map data, map invars)
	map:copy(invars, data)

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
			urlencode(RECAPTCHA_PK), urlencode(server_var("REMOTE_ADDR")),
			urlencode(map:get(vars, "recaptcha_challenge_field")),
			urlencode(map:get(vars, "recaptcha_response_field")) })

		object recaptcha_result = get_url(recaptcha_url, postdata)
		if length(recaptcha_result) < 2 then
	 		errors = wc:add_error(errors, "recaptcha", "Could not validate reCAPTCHA.")
		elsif not match("true", recaptcha_result[2]) = 1 then
			errors = wc:add_error(errors, "recaptcha", "reCAPTCHA response was incorrect.")
		end if
	end if

	return errors
end function

public function do_signup(map data, map invars)
	user_db:create(map:get(invars, "code"), map:get(invars, "password"),
		map:get(invars, "email"))
	
	datetime rightnow = dt:now(), expire

	current_user = user_db:get_by_login(map:get(invars, "code"), map:get(invars, "password"))
	set_user_ip(current_user, server_var("REMOTE_ADDR"))
	expire = dt:add(rightnow, 1, YEARS)

    wc:add_cookie("euweb_sessinfo", current_user[USER_ID], "/", expire)

	return { TEXT, t_signup_ok:template(data) }
end function
wc:add_handler(routine_id("do_signup"), routine_id("validate_do_signup"), "user", "do_signup", 
	signup_invars)

public function logout(map data, map invars)
	datetime past = datetime:now()
	past = datetime:add(past, -2, YEARS)
	wc:add_cookie("euweb_sessinfo", current_user[USER_ID], "/", past)
	current_user = 0
	return { TEXT, t_logout_ok:template(data) }
end function
wc:add_handler(routine_id("logout"), -1, "user", "logout")
wc:add_handler(routine_id("logout"), -1, "logout", "index")
