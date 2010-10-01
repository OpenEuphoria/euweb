global atom time_start = time()

without warning

include std/get.e
include std/map.e

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
include news.e
include preview.e
include recent.e
include rss.e
include search.e
include security.e
include ticket.e
include user.e
include wiki.e

constant
	EUWEB_JS = `
	<script src="/js/prototype.js" type="text/javascript"></script> 
	<script src="/js/scriptaculous.js" type="text/javascript"></script> 
	`,
	
	GOOGLE_JS = `
	<script src="http://ajax.googleapis.com/ajax/libs/prototype/1.6.1.0/prototype.js" type="text/javascript"></script> 
	<script src="http://ajax.googleapis.com/ajax/libs/scriptaculous/1.8.3/scriptaculous.js" type="text/javascript"></script
	`
	

procedure app(object data, object vars)
    map:put( data, "js_libs", GOOGLE_JS )
    -- Auto Login trumps a cookie that may exist.
    if AUTO_LOGIN_UID = 0 then
        sequence user_cookie = wc:cookie("euweb_sessinfo")
    
        if length(user_cookie) then
            object u = user_db:get_by_sess_id(user_cookie, server_var("REMOTE_ADDR"))
            if sequence(u) then
                current_user = u
                user_db:update_last_login(u)
                if u[USER_LOCAL_JS] then
					map:put( data, "js_libs", EUWEB_JS )
				end if
            end if
        end if
    end if
    
    map:put(data, "s_news", 1)
    map:put(data, "s_ticket", 1)
    map:put(data, "s_forum", 1)
    map:put(data, "is_search", 0)
end procedure

-- Open our database
db:open()

include ip_track.e

-- For developers use. Define AUTO_LOGIN_UID in your config file and 
-- populate it with your user.id value from the database.

if AUTO_LOGIN_UID > 0 then
    current_user = user_db:get(AUTO_LOGIN_UID)
end if

-- Handle the request
wc:handle_request(routine_id("app"))

-- Close our database
db:close()

