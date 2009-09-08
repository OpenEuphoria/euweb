--****
-- Ticket System

include std/error.e
include std/get.e
include std/map.e
include std/search.e

include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include templates/security.etml as t_security
include templates/ticket/index.etml as t_index
include templates/ticket/create.etml as t_create
include templates/ticket/create_ok.etml as t_create_ok

include config.e
include db.e
include ticket_db.e
include fuzzydate.e

sequence index_vars = {
	{ wc:INTEGER, "page",       1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map request)
	object tickets = ticket_db:get_list(0, 10)

	log:log("Ticket count: %d", { length(tickets) })

	if edbi:error_code() then
		map:put(data, "error_code", edbi:error_code())
		map:put(data, "error_message", edbi:error_message())
	else

		for i = 1 to length(tickets) do
			tickets[i][ticket_db:CREATED_AT] = fuzzy_ago(tickets[i][ticket_db:CREATED_AT])
		end for

		map:put(data, "error_code", 0)
		map:put(data, "page", map:get(request, "page"))
		map:put(data, "per_page", map:get(request, "per_page"))
		map:put(data, "tickets", tickets)
		map:put(data, "ticket_count", ticket_db:count())
	end if

	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "ticket", "index", index_vars)

sequence create_vars = {
	{ wc:INTEGER, "severity_id" },
	{ wc:INTEGER, "category_id" },
	{ wc:INTEGER, "reported_release_id" },
	{ wc:SEQUENCE, "body" },
	{ wc:SEQUENCE, "subject" }
}

function create(map data, map request)
	map:put(data, "id", "-1")

	return { TEXT, t_create:template(data) }
end function
wc:add_handler(routine_id("create"), -1, "ticket", "create", create_vars)

function do_create(map data, map request)
	ticket_db:create(
		map:get(request, "severity_id"),
		map:get(request, "category_id"),
		map:get(request, "reported_release_id"),
		map:get(request, "body"),
		map:get(request, "subject"))

	if edbi:error_code() then
		map:put(data, "error_code", edbi:error_code())
		map:put(data, "error_message", edbi:error_message())
	else
		integer id = edbi:last_insert_id()
		map:put(data, "error_code", 0)
		map:put(data, "id", id)
	end if

	return { TEXT, t_create_ok:template(data) }
end function
wc:add_handler(routine_id("do_create"), -1, "ticket", "do_create", create_vars)

