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

enum FMT_PLAIN, FMT_EUCODE, FMT_CREOLE

sequence index_vars = {
	{ wc:INTEGER,  "page",      1 },
	{ wc:INTEGER,  "per_page", 20 },
	{ wc:INTEGER,  "submit",   "" },
	{ wc:SEQUENCE, "title"        },
	{ wc:SEQUENCE, "body"         },
	{ wc:INTEGER,  "format",    1 },
    { wc:SEQUENCE, "preview",  "" },
	$
}

function index(map data, map request)
	map:put(data, "page", map:get(request, "page"))
	map:put(data, "per_page", map:get(request, "per_page"))

    -- Put in request via "create" when submit=Preview
    map:put(data, "preview", map:get(request, "preview"))
    map:put(data, "format", map:get(request, "format"))

	map:put(data, "total_count", pastey_db:count())
	map:put(data, "items", pastey_db:recent(map:get(request, "page"), map:get(request, "per_page")))
	map:put(data, "eucode", map:get(request, "eucode"))

	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "pastey", "index", index_vars)

sequence create_vars = {
	{ wc:SEQUENCE, "title"      },
	{ wc:SEQUENCE, "body"       },
	{ wc:INTEGER,  "format",  1 },
	{ wc:SEQUENCE, "submit", "" },
	$
}

function validate_create(map data, map request)
	sequence errors = wc:new_errors("pastey", "index")

    if equal(map:get(request, "submit"), "Preview") then
    	return errors
    end if

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
    sequence preview = ""
    integer is_preview = equal(map:get(request, "submit"), "Preview")

    switch map:get(request, "format") do
        case FMT_PLAIN then
            if is_preview then
                preview = "<pre>" & body & "</pre>"
            end if

        case FMT_EUCODE then
            body = "<eucode>\n" & body & "\n</eucode>"
            preview = format_body(body)

        case FMT_CREOLE then
            preview = format_body(body)
    end switch

    if is_preview then
        map:put(request, "preview", preview)
        map:put(data, "body", map:get(request, "body"))
        map:put(data, "title", map:get(request, "title"))

        return index(data, request)
    end if

	object pastey = pastey_db:create(map:get(request, "title"), preview)

	return { REDIRECT_303, sprintf("/pastey/%d.wc", { pastey }) }
end function
wc:add_handler(routine_id("create"), routine_id("validate_create"), "pastey", "create", create_vars)

sequence view_vars = {
	{ wc:INTEGER, "id", 0 },
	{ wc:SEQUENCE, "body", "" },
	{ wc:INTEGER, "remove_comment", 0 },
	$
}

function view(map data, map request)
	object pastey = pastey_db:get(map:get(request, "id"))

	if atom(pastey) then
		return { REDIRECT_303, "/pastey/index.wc?message=" & edbi:error_message() }
	end if

	if has_role("user") and length(map:get(request, "body")) then
		comment_db:add_comment(
			pastey_db:MODULE_ID,
			pastey[pastey_db:ID],
			pastey[pastey_db:TITLE],
			map:get(request, "body"))

		integer id = edbi:last_insert_id()

		return { REDIRECT_303, sprintf("/pastey/%d.wc#%d", { pastey[pastey_db:ID], id }) }
	end if

	if has_role("forum_moderator") and map:get(request, "remove_comment") > 0 then
		comment_db:remove_comment(map:get(request, "remove_comment"))

		return { REDIRECT_303, sprintf("/pastey/%d.wc", { pastey[pastey_db:ID] }) }
	end if

	map:put(data, "pastey", pastey)
	map:put(data, "comment_count",
		edbi:query_object("SELECT COUNT(id) FROM comment WHERE module_id=%d AND item_id=%d",
			{ pastey_db:MODULE_ID, pastey[pastey_db:ID] }))
	map:put(data, "comments", comment_db:get_all(pastey_db:MODULE_ID, pastey[pastey_db:ID]))

	return { TEXT, t_view:template(data) }
end function
wc:add_handler(routine_id("view"), -1, "pastey", "view", view_vars)

