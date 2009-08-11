--****
-- == User module
-- 

-- StdLib includes
include std/error.e
include std/map.e
include std/net/http.e
include std/types.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

-- Templates
include templates/user/profile.etml as t_profile
include templates/user/login_form.etml as t_login_form
include templates/user/signup.etml as t_signup
include templates/user/signup_ok.etml as t_signup_ok

-- Local includes
include config.e 
include db.e
include format.e
include user_db.e

sequence profile_invars = {
	{ wc:SEQUENCE, "user" }
}

public function profile(map data, map invars)
	object user = user_db:get_by_code(map:get(invars, "user"))
	if atom(user) then
		crash("User record could not be located")
	end if

	map:put(data, "user", user)

	return { TEXT, t_profile:template(data) }
end function
wc:add_handler(routine_id("profile"), -1, "user", "profile", profile_invars)

public function login_form(map data, map invars)

	return { TEXT, t_login_form:template(data) }
end function
wc:add_handler(routine_id("login_form"), -1, "user", "login")
wc:add_handler(routine_id("login_form"), -1, "login", "index")

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
	return { TEXT, t_signup_ok:template(data) }
end function
wc:add_handler(routine_id("do_signup"), routine_id("validate_do_signup"), "user", "do_signup")
