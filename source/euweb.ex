include std/get.e

-- WebClay includes
include webclay/webclay.e as wc
include webclay/logging.e as log
include webclay/url.e as url

log:open("euweb.log")

-- Configuration includes
include config.e

-- Database includes
include db.e
include user_db.e

-- Module includes
include about.e
include download.e
include forum.e
include greeter.e
include news.e
include security.e
include wiki.e
include user.e

procedure app(object data, object vars)
    -- Auto Login trumps a cookie that may exist.
    if AUTO_LOGIN_UID = 0 then
        sequence user_cookie = wc:cookie("euweb_sessinfo")
    
        if length(user_cookie) then
            object u = user_db:get(defaulted_value(user_cookie, 0))
            if sequence(u) then
                -- ensure we have the correct user by checking the IP
                if equal(u[USER_IP_ADDR], server_var("REMOTE_ADDR")) then
                    current_user = u
                end if
            end if
        end if
    end if
end procedure

-- Open our database
db:open()

-- For developers use. Define AUTO_LOGIN_UID in your config file and 
-- populate it with your user.id value from the database.

include user_db.e
if AUTO_LOGIN_UID > 0 then

    current_user = user_db:get(AUTO_LOGIN_UID)

end if




-- Handle the request
wc:handle_request(routine_id("app"))

-- Close our database
db:close()
