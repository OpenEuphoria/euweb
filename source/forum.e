--****
-- == Forum module
--

-- StdLib includes
include std/error.e
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

-- Templates
include templates/forum/index.etml as t_index
include templates/forum/view.etml as t_view

-- Local includes
include db.e
include format.e
include forum_db.e

sequence index_invars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map invars)
	map:put(data, "page", map:get(invars, "page"))
	map:put(data, "per_page", map:get(invars, "per_page"))
	map:put(data, "message_count", forum_db:message_count())
	map:put(data, "thread_count", forum_db:thread_count())

	map:put(data, "threads", 
		forum_db:get_thread_list(map:get(invars, "page"), map:get(invars, "per_page")))

	log:log("Page: %d Per Page: %d", { map:get(invars, "page"), map:get(invars, "per_page") })
	
	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "forum", "index", index_invars)

sequence view_invars = {
	{ wc:INTEGER, "id", -1 }
}

function view(map data, map invars)
	object messages = forum_db:get_topic_messages(map:get(invars, "id"))
	if atom(messages) then
		crash("Couldn't get message: %s", { mysql_error(db) })
	end if
	
	for i = 1 to length(messages) do
		messages[i] = append(messages[i], format_body(messages[i][MSG_BODY]))
	end for
	
	map:put(data, "messages", messages)

	return { TEXT, t_view:template(data) }
end function
wc:add_handler(routine_id("view"), -1, "forum", "view", view_invars)
