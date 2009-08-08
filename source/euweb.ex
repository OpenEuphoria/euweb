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

-- This is temporary
include user_db.e
current_user = user_db:get(1)

-- Handle the request
wc:handle_request()

-- Close our database
db:close()
