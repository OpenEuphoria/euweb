--****
-- Ticket System

include std/convert.e
include std/error.e
include std/get.e
include std/map.e
include std/search.e
include std/sequence.e

include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include templates/security.etml as t_security
include templates/ticket/index.etml as t_index
include templates/ticket/create.etml as t_create
include templates/ticket/create_ok.etml as t_create_ok
include templates/ticket/detail.etml as t_detail
include templates/ticket/update_ok.etml as t_update_ok
include templates/ticket/change_product.etml as t_change_product

include dump.e
include config.e
include db.e
include comment_db.e
include ticket_db.e
include user_db.e
include fuzzydate.e
include format.e

constant EUPHORIA_PRODUCT_ID = 1

function get_product_id(map request, object data = 0)
	integer product_id	= map:get(request, "product_id", -1)

	if product_id = -1 and wc:cookie_has("product_id") then
		-- set to -1 by default in case product cannot be parsed.
		-- it'll be caught later
		product_id = to_integer(wc:cookie("product_id"), -1)
	end if

	if product_id = -1 then
		product_id = EUPHORIA_PRODUCT_ID
	end if

	wc:add_cookie("product_id", sprintf("%d", { product_id }))
	map:put(request, "product_id", product_id)

	if atom(data) and (not data = 0) then
		map:put(data, "product_id", product_id)
		map:put(data, "category_sql", sprintf("SELECT id,name FROM ticket_category WHERE product_id=%d ORDER BY name",
			{ product_id }))
		map:put(data, "milestone_sql",
			sprintf("SELECT name,name FROM ticket_milestone WHERE product_id=%d ORDER BY name", {
				product_id }))
	end if

	return product_id
end function

sequence index_vars = {
	{ wc:INTEGER,  "page",		   1 },
	{ wc:INTEGER,  "per_page",	  20 },
	{ wc:INTEGER,  "category_id", -1 },
	{ wc:INTEGER,  "severity_id", -1 },
	{ wc:INTEGER,  "state_id",	  -1 },
	{ wc:INTEGER,  "status_id",	  -1 },
	{ wc:INTEGER,  "type_id",	  -1 },
	{ wc:INTEGER,  "product_id",  -1 },
	{ wc:SEQUENCE, "milestone",	  "" }
}

function real_index(map data, map request, sequence where="", integer append_to_where=1)
	-- If no cookie is set, send them to the change product page. This page will
	-- describe how the ticket system works with products.
	if not map:has(request, "product_id") and not wc:cookie_has("product_id") then
		map:put(data, "no_product_id", 1)
		return change_product(data, request)
	end if

	integer page		= map:get(request, "page")
	integer per_page	= map:get(request, "per_page")
	integer category_id = map:get(request, "category_id")
	integer severity_id = map:get(request, "severity_id")
	integer state_id	= map:get(request, "state_id")
	integer status_id	= map:get(request, "status_id")
	integer type_id		= map:get(request, "type_id")
	sequence milestone	= map:get(request, "milestone")
	integer product_id	= get_product_id(request, data)

	map:copy(request, data)

	sequence local_where = {}
	if category_id > -1 then
		local_where = append(local_where, sprintf("tcat.id=%d", { category_id }))
	end if
	if severity_id > -1 then
		local_where = append(local_where, sprintf("tsev.id=%d", { severity_id }))
	end if
	if state_id > -1 then
		local_where = append(local_where, sprintf("tstate.id=%d", { state_id }))
	end if
	if status_id > -1 then
		local_where = append(local_where, sprintf("tstat.id=%d", { status_id }))
	end if
	if type_id > -1 then
		local_where = append(local_where, sprintf("ttype.id=%d", { type_id }))
	end if
	if product_id > -1 then
		local_where = append(local_where, sprintf("tprod.id=%d", { product_id }))
	end if
	if length(milestone) > 0 then
		local_where = append(local_where, sprintf("t.milestone='%s'", {
				match_replace("\\",
					match_replace("'", milestone, "''", 0),
				"\\\\")
			}))
	end if

	if length(local_where) then
		local_where = join(local_where, " AND ")
		if append_to_where then
			if length(where) then
				where &= " AND "
			end if
			where &= local_where
		else
			where = local_where
		end if
	end if

	object tickets = ticket_db:get_list((page - 1) * per_page, per_page, where)

	-- Get the product name. If we have tickets we can get it from there, otherwise
	-- we will have to query the db specifically for the product name.
	if length(tickets) > 0 then
		map:put(data, "product_name", tickets[1][ticket_db:PRODUCT])
	else
		map:put(data, "product_name", edbi:query_object("SELECT name FROM ticket_product WHERE id=%d", {
			product_id }))
	end if

	if edbi:error_code() then
		map:put(data, "error_code", edbi:error_code())
		map:put(data, "error_message", edbi:error_message())
	else
		for i = 1 to length(tickets) do
			tickets[i][ticket_db:CREATED_AT] = fuzzy_ago(tickets[i][ticket_db:CREATED_AT])
		end for

		map:put(data, "error_code", 0)
		map:put(data, "tickets", tickets)
		map:put(data, "ticket_count", ticket_db:count(where))
	end if

	return { TEXT, t_index:template(data) }
end function

function mine(map data, map request)
	return real_index(data, request, sprintf("(t.assigned_to_id=%d OR t.submitted_by_id=%d)",
		{ current_user[user_db:USER_ID], current_user[user_db:USER_ID] }))
end function
wc:add_handler(routine_id("mine"), -1, "ticket", "mine", index_vars)

function opened(map data, map request)
	if equal(map:get(request, "state_id"), -1) then
		map:put(request, "state_id", 1)
	end if
	return real_index(data, request, "tstate.closed=0", 0)
end function
wc:add_handler(routine_id("opened"), -1, "ticket", "index", index_vars)

function confirm_tickets(map data, map request)
	return real_index(data, request, "tstate.name='Confirm'")
end function
wc:add_handler(routine_id("confirm_tickets"), -1, "ticket", "confirm", index_vars)

function closed(map data, map request)
	return real_index(data, request, "tstate.closed=1")
end function
wc:add_handler(routine_id("closed"), -1, "ticket", "closed", index_vars)

sequence create_vars = {
	{ wc:INTEGER,  "type_id",	  -1 },
	{ wc:INTEGER,  "product_id",  -1 },
	{ wc:INTEGER,  "severity_id", -1 },
	{ wc:INTEGER,  "category_id", -1 },
	{ wc:SEQUENCE, "reported_release" },
	{ wc:SEQUENCE, "milestone" },
	{ wc:SEQUENCE, "content" },
	{ wc:SEQUENCE, "subject" }
}

function create(map data, map request)
	if not has_role("user") then
		return { TEXT, t_security:template(data) }
	end if

	integer product_id = get_product_id(request, data)
	log:log("product_id=%d", { product_id })

	map:put(data, "id", "-1")
	map:copy(request, data)
	map:put(data, "product_name", edbi:query_object("SELECT name FROM ticket_product WHERE id=%d", {
		product_id }))

	return { TEXT, t_create:template(data) }
end function
wc:add_handler(routine_id("create"), -1, "ticket", "create", create_vars)

function validate_do_create(map data, map request)
	sequence errors = wc:new_errors("ticket", "create")

	if not has_role("user") then
		errors = wc:add_error(errors, "form", "You are not authorized to add a new ticket")
	end if

	if map:get(request, "severity_id") = -1 then
		errors = wc:add_error(errors, "severity_id", "You must select a severity level.")
	end if

	if map:get(request, "category_id") = -1 then
		errors = wc:add_error(errors, "category_id", "You must select a category.")
	end if

	if map:get(request, "type_id") = -1 then
		errors = wc:add_error(errors, "type_id", "You must select a ticket type.")
	end if

	if atom(map:get(request, "subject")) or atom(map:get(request, "content")) then
		dump_map("ticket_create", request)
	end if

	if length(map:get(request, "subject")) = 0 then
		errors = wc:add_error(errors, "subject", "Subject cannot be empty.")
	end if

	if length(map:get(request, "content")) = 0 then
		errors = wc:add_error(errors, "content", "Content cannot be empty.")
	end if

	return errors
end function

function do_create(map data, map request)
	ticket_db:create(
		map:get(request, "type_id"),
		get_product_id(request),
		map:get(request, "severity_id"),
		map:get(request, "category_id"),
		map:get(request, "reported_release"),
		map:get(request, "milestone"),
		map:get(request, "subject"),
		map:get(request, "content"))

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
wc:add_handler(routine_id("do_create"), routine_id("validate_do_create"), "ticket", "do_create",
	create_vars)

sequence detail_vars = {
	{ wc:INTEGER, "id", -1 }
}

function detail(map data, map request)
	object ticket = ticket_db:get(map:get(request, "id"))

	-- Trick it for incoming links that may be switching between products
	map:put(request, "product_id", ticket[ticket_db:PRODUCT_ID])

	ticket[ticket_db:CONTENT] = format_body(ticket[ticket_db:CONTENT], 0)
	ticket[ticket_db:CREATED_AT] = fuzzy_ago(ticket[ticket_db:CREATED_AT])

	map:put(data, "ticket", ticket)
	map:put(data, "comments", comment_db:get_all(ticket_db:MODULE_ID, map:get(request, "id")))
	map:put(data, "product_name", ticket[ticket_db:PRODUCT])

	get_product_id(request, data)

	return { TEXT, t_detail:template(data) }
end function
wc:add_handler(routine_id("detail"), -1, "ticket", "view", detail_vars)

sequence update_vars = {
	{ wc:INTEGER,  "id" },
	{ wc:INTEGER,  "type_id" },
	{ wc:INTEGER,  "severity_id" },
	{ wc:INTEGER,  "category_id" },
	{ wc:SEQUENCE, "reported_release" },
	{ wc:SEQUENCE, "milestone" },
	{ wc:INTEGER,  "assigned_to_id" },
	{ wc:INTEGER,  "status_id" },
	{ wc:INTEGER,  "state_id" },
	{ wc:SEQUENCE, "svn_rev" },
	{ wc:SEQUENCE, "comment" }
}

function validate_update(map data, map request)
	sequence errors = wc:new_errors("ticket", "detail")

	if not has_role("user") then
		errors = wc:add_error(errors, "form", "You are not authorized to edit or comment on a ticket")
	end if

	return errors
end function

function update(map data, map request)
	map:put(data, "error_code", 0)

	if map:get(request, "assigned_to_id") = -1 then
		map:put(request, "assigned_to_id", 0)
	end if

	if has_role("developer") or
		(sequence(current_user) and
			current_user[user_db:USER_ID] =
				edbi:query_object("SELECT submitted_by_id FROM ticket WHERE id=%d", {
				map:get(request, "id") }))
	then
		-- Update some ticket values
		ticket_db:update(
			map:get(request, "id"),
			map:get(request, "type_id"),
			get_product_id(request),
			map:get(request, "severity_id"),
			map:get(request, "category_id"),
			map:get(request, "reported_release"),
			map:get(request, "milestone"),
			map:get(request, "assigned_to_id"),
			map:get(request, "status_id"),
			map:get(request, "state_id"),
			map:get(request, "svn_rev")
		)

		if edbi:error_code() then
			map:put(data, "error_code", edbi:error_code())
			map:put(data, "error_message", edbi:error_message())
		end if
	end if

	if length(map:get(request, "comment")) then
		-- Add a comment
		comment_db:add_comment(
			ticket_db:MODULE_ID,
			map:get(request, "id"),
			"",
			map:get(request, "comment")
		)

		if edbi:error_code() then
			map:put(data, "error_code", edbi:error_code())
			map:put(data, "error_message", edbi:error_message())
		end if
	end if

	map:put(data, "id", map:get(request, "id"))

	return { TEXT, t_update_ok:template(data) }
end function
wc:add_handler(routine_id("update"), routine_id("validate_update"), "ticket", "update", update_vars)

function change_product(map data, map request)
	sequence products = edbi:query_rows("SELECT id, name FROM ticket_product ORDER BY name")
	map:put(data, "products", products)
	return { TEXT, t_change_product:template(data) }
end function
wc:add_handler(routine_id("change_product"), -1, "ticket", "change_product", {})

