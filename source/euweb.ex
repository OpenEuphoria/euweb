-- WebClay includes
include webclay/webclay.e as wc

-- Module includes
include about.e
include download.e
include forum.e
include greeter.e
include news.e
include wiki.e

-- Handle the request
wc:handle_request()
