-- WebClay includes
include webclay/webclay.e as wc
include webclay/logging.e as log

log:open("euweb.log")

-- Configuration includes
include config.e

-- Database includes
include db.e

-- Module includes
include about.e
include download.e
include forum.e
include greeter.e
include news.e
include wiki.e
include user.e

-- Open our database
db:open()

-- For developers use. Define AUTO_LOGIN_UID in your config file and 
-- populate it with your user.id value from the database.

include user_db.e
if AUTO_LOGIN_UID > 0 then
    current_user = user_db:get(AUTO_LOGIN_UID)
end if

-- Handle the request
wc:handle_request()

-- Close our database
db:close()
