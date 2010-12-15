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
include webclay/validate.e as valid

include edbi/edbi.e

include templates/security.etml as t_security
include templates/pastey/index.etml as t_index
include templates/pastey/view.etml as t_view

include comment_db.e
include pastey_db.e
include format.e
include fuzzydate.e

sequence index_vars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 },
	{ wc:SEQUENCE, "title"        },
	{ wc:SEQUENCE, "body"         },
	{ wc:INTEGER,  "eucode",    1 },
	$
}

function index(map data, map request)
	map:put(data, "page", map:get(request, "page"))
	map:put(data, "per_page", map:get(request, "per_page"))

	map:put(data, "total_count", pastey_db:count())
	map:put(data, "items", pastey_db:recent(map:get(request, "page"), map:get(request, "per_page")))	
	map:put(data, "eucode", map:get(request, "eucode"))

	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "pastey", "index", index_vars)

sequence create_vars = {
	{ wc:SEQUENCE, "title"     },
	{ wc:SEQUENCE, "body"      },
	{ wc:INTEGER,  "eucode", 0 },
	$
}

function validate_create(map data, map request)
	sequence errors = wc:new_errors("pastey", "index")

	if not valid:not_empty(map:get(request, "title")) then
		errors = wc:add_error(errors, "title", "Title is empty!")
	end if

	if not valid:not_empty(map:get(request, "body")) then
		errors = wc:add_error(errors, "body", "Body is empty!")
	end if

	return errors
end function

function create(map data, map request)
	if not has_role("user") then
		return { TEXT, t_security:template(data) }
	end if

	sequence body = map:get(request, "body")
	if map:get(request, "eucode") then
		body = "<eucode>\n" & body & "\n</eucode>"
	end if
	
	object pastey = pastey_db:create(map:get(request, "title"), body)

	return { REDIRECT_303, sprintf("/pastey/%d.wc", { pastey }) }
end function
wc:add_handler(routine_id("create"), routine_id("validate_create"), "pastey", "create", create_vars)

sequence view_vars = {
	{ wc:INTEGER, "id", 0 }	
}

function view(map data, map request)
	object pastey = pastey_db:get(map:get(request, "id"))

	if atom(pastey) then
		return { REDIRECT_303, "/pastey/index.wc?message=" & edbi:error_message() }
	end if

	pastey[pastey_db:BODY] = format_body(pastey[pastey_db:BODY])

	map:put(data, "pastey", pastey)

	return { TEXT, t_view:template(data) }
end function
wc:add_handler(routine_id("view"), -1, "pastey", "view", view_vars)

