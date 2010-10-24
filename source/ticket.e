--****
-- Ticket System

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

include dump.e
include config.e
include db.e
include comment_db.e
include ticket_db.e
include user_db.e
include fuzzydate.e
include format.e

sequence index_vars = {
	{ wc:INTEGER,  "page",         1 },
	{ wc:INTEGER,  "per_page",    20 },
	{ wc:INTEGER,  "category_id", -1 },
	{ wc:INTEGER,  "severity_id", -1 },
	{ wc:INTEGER,  "state_id",    -1 },
	{ wc:INTEGER,  "status_id",   -1 },
	{ wc:INTEGER,  "type_id",     -1 },
	{ wc:INTEGER,  "product_id",  -1 },
    { wc:SEQUENCE, "milestone",   "" }
}

function real_index(map data, map request, sequence where="", integer append_to_where=1)
	integer page        = map:get(request, "page")
	integer per_page    = map:get(request, "per_page")
	integer category_id = map:get(request, "category_id")
	integer severity_id = map:get(request, "severity_id")
	integer state_id    = map:get(request, "state_id")
	integer status_id   = map:get(request, "status_id")
	integer type_id     = map:get(request, "type_id")
	integer product_id  = map:get(request, "product_id")
    sequence milestone  = map:get(request, "milestone")

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

	if edbi:error_code() then
		map:put(data, "error_code", edbi:error_code())
		map:put(data, "error_message", edbi:error_message())
	else
		for i = 1 to length(tickets) do
			tickets[i][ticket_db:CREATED_AT] = fuzzy_ago(tickets[i][ticket_db:CREATED_AT])
		end for

		map:put(data, "error_code", 0)
		map:put(data, "tickets", tickets)
		map:put(data, "ticket_count", ticket_db:count())
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
	{ wc:INTEGER,  "type_id",     -1 },
	{ wc:INTEGER,  "product_id",   1 },
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
    
	map:put(data, "id", "-1")
	map:copy(request, data)
	
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
	
	if map:get(request, "product_id") = -1 then
		errors = wc:add_error(errors, "product_id", "You must select a valid product.")
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
		map:get(request, "product_id"),
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
	
	ticket[ticket_db:CONTENT] = format_body(ticket[ticket_db:CONTENT], 0)
	ticket[ticket_db:CREATED_AT] = fuzzy_ago(ticket[ticket_db:CREATED_AT])

	map:put(data, "ticket", ticket)	
	map:put(data, "comments", comment_db:get_all(ticket_db:MODULE_ID, map:get(request, "id")))
	
	return { TEXT, t_detail:template(data) }
end function
wc:add_handler(routine_id("detail"), -1, "ticket", "view", detail_vars)

sequence update_vars = {
	{ wc:INTEGER,  "id" },
	{ wc:INTEGER,  "type_id" },
	{ wc:INTEGER,  "product_id" },
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
			map:get(request, "product_id"),
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

