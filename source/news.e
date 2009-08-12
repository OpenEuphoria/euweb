--****
-- == News module
-- 

-- StdLib includes
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/logging.e as log

-- Local includes
include templates/news/index.etml as t_index
include news_db.e
include format.e
include fuzzydate.e

sequence index_invars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map invars)
	map:put(data, "page", map:get(invars, "page"))
	map:put(data, "per_page", map:get(invars, "per_page"))
	map:put(data, "article_count", news_db:article_count())

	object arts = news_db:get_article_list(map:get(invars, "page"), map:get(invars, "per_page"))
	for i = 1 to length(arts) do
		arts[i][news_db:CONTENT] = format_body(arts[i][news_db:CONTENT])
		arts[i][news_db:PUBLISH_AT] = fuzzy_ago(sqlDateTimeToDateTime(arts[i][news_db:PUBLISH_AT]))
	end for

	map:put(data, "articles", arts)

	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "news", "index", index_invars)
wc:add_handler(routine_id("index"), -1, "index", "index", index_invars)
wc:set_default_handler(routine_id("greet_form"))
