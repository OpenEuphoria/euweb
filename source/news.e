--****
-- == News module
-- 

-- StdLib includes
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc

-- Local includes
include templates/news/index.etml as t_index

sequence index_invars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map invars)
	map:put(data, "page", map:get(invars, "page"))
	map:put(data, "per_page", map:get(invars, "per_page"))
	--map:put(data, "message_count", news_db:message_count())
	--map:put(data, "thread_count", news_db:thread_count())

	--map:put(data, "news_items", 
	--	news_db:get_news(map:get(invars, "page"), map:get(invars, "per_page")))

	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "news", "index", index_invars)
wc:add_handler(routine_id("index"), -1, "index", "index", index_invars)
wc:set_default_handler(routine_id("greet_form"))
