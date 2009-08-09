--****
-- == User module
-- 

-- StdLib includes
include std/error.e
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

-- Templates
include templates/user/profile.etml as t_profile
include templates/user/login_form.etml as t_login_form
include templates/user/signup.etml as t_signup

-- Local includes
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
	return { TEXT, t_signup:template(data) }
end function
wc:add_handler(routine_id("signup"), -1, "user", "signup")
wc:add_handler(routine_id("signup"), -1, "signup", "index")
