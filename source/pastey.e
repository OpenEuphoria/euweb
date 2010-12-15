--****
-- == Pastey Module
--

include std/map.e
include std/search.e
include std/datetime.e as dt
include std/rand.e
include std/sequence.e
include std/text.e

include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include templates/security.etml as t_security
include templates/pastey/index.etml as t_index

include comment_db.e
include pastey_db.e
include format.e
include fuzzydate.e

sequence index_vars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 },
	$
}

function index(map data, map request)
	map:put(data, "page", map:get(request, "page"))
	map:put(data, "per_page", map:get(request, "per_page"))

	map:put(data, "total_count", pastey_db:count())
	map:put(data, "items", pastey_db:recent(map:get(request, "page"), map:get(request, "per_page")))	

	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "pastey", "index", index_vars)

