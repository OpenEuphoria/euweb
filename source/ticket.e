--****
-- Ticket System

namespace ticket

include std/convert.e
include std/error.e
include std/get.e
include std/map.e
include std/search.e
include std/sequence.e
include std/text.e

include webclay/webclay.e as wc
include webclay/logging.e as log
include webclay/validate.e as valid

include edbi/edbi.e

include templates/security.etml as t_security
include templates/ticket/index.etml as t_index
include templates/ticket/create.etml as t_create
include templates/ticket/create_ok.etml as t_create_ok
include templates/ticket/detail.etml as t_detail
include templates/ticket/update_ok.etml as t_update_ok
include templates/ticket/change_product.etml as t_change_product
include templates/ticket/not_found.etml as t_not_found

include dump.e
include config.e
include db.e
include comment_db.e
include ticket_db.e as ticket_db
include user_db.e as user_db
include fuzzydate.e
include format.e

constant EUPHORIA_PRODUCT_ID = 1

function get_product_id(map request, object data = 0)
    integer product_id  = map:get(request, "product_id", -1)

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
	{ wc:INTEGER, "id", 0 },
    { wc:INTEGER,  "page",         1 },
    { wc:INTEGER,  "per_page",    20 },
    { wc:INTEGER,  "category_id", -1 },
    { wc:INTEGER,  "severity_id", -1 },
    { wc:INTEGER,  "status_id",   -1 },
    { wc:INTEGER,  "type_id",     -1 },
    { wc:INTEGER,  "product_id",  -1 },
    { wc:INTEGER,  "user_id",     -1 },
    { wc:SEQUENCE, "milestone",   "" },
	{ wc:SEQUENCE, "actiontype",  "" }
}

function real_index(map data, map request, sequence where="")
    -- If no cookie is set, send them to the change product page. This page will
    -- describe how the ticket system works with products.
    if not map:has(request, "product_id") and not wc:cookie_has("product_id") then
        map:put(data, "no_product_id", 1)
        return change_product(data, request)
    end if

	-- Special case where New Ticket button is pressed.
	if equal(map:get(request, "actiontype"), "New Ticket") then
		return ticket_create(data, request)
	end if

	if map:get(request, "id") > 0 then
		return { REDIRECT_303, sprintf("/ticket/%d.wc", { map:get(request, "id") }) }
	end if

    sequence milestone  = map:get(request, "milestone")
    integer page        = map:get(request, "page")
    integer per_page    = map:get(request, "per_page")
    integer category_id = map:get(request, "category_id")
    integer severity_id = map:get(request, "severity_id")
    integer status_id   = map:get(request, "status_id")
    integer type_id     = map:get(request, "type_id")
    integer user_id     = map:get(request, "user_id")
    integer product_id  = get_product_id(request, data)

    map:copy(request, data)

    sequence local_where = {}
    if category_id > -1 then
        local_where = append(local_where, sprintf("tcat.id=%d", { category_id }))
    end if
    if severity_id > -1 then
        local_where = append(local_where, sprintf("tsev.id=%d", { severity_id }))
    end if
    if status_id > -1 then
        local_where = append(local_where, sprintf("tstat.id=%d", { status_id }))
    elsif status_id = -2 then
        local_where = append(local_where, "tstat.is_open=1")
    elsif status_id = -3 then
        local_where = append(local_where, "tstat.is_open=0")
	elsif status_id = -4 then
		local_where = append(local_where, "tstat.is_open=1 AND tstat.id != 10")
    end if
    if type_id > -1 then
        local_where = append(local_where, sprintf("ttype.id=%d", { type_id }))
    end if
    if product_id > -1 then
        local_where = append(local_where, sprintf("tprod.id=%d", { product_id }))
    end if
    if user_id > -1 then
        local_where = append(local_where,
            sprintf("(t.submitted_by_id=%d OR t.assigned_to_id=%d)", {
                    user_id, user_id }))
    end if

    integer by_milestone = 0
    integer milestone_progress = 0
    sequence milestone_progress_text = ""

	if equal(milestone, "None") then
		local_where = append(local_where, "(t.milestone IS NULL or t.milestone='')")
    elsif length(milestone) > 0 then
        sequence safe_milestone = match_replace("\\",
            match_replace("'", milestone, "''", 0),
            "\\\\")
        local_where = append(local_where, sprintf("t.milestone='%s'", {
                    safe_milestone
        }))

        by_milestone = 1
        integer total_count = edbi:query_object("""
            SELECT COUNT(t.id) FROM ticket AS t
            WHERE product_id=%d AND milestone=%s
            """,
            { product_id, safe_milestone  } )
        integer active_count = edbi:query_object("""
            SELECT COUNT(t.id)
            FROM ticket AS t
            INNER JOIN ticket_status AS tstat ON (tstat.id=t.status_id)
            WHERE tstat.is_open=1 AND
            t.product_id=%d AND t.milestone=%s
            """,
            { product_id, safe_milestone })

		if total_count > 0 then
			milestone_progress = 100 - floor((active_count / total_count) * 100)
			milestone_progress_text = sprintf("%d of %d complete (%d%%)", {
					total_count - active_count, total_count, milestone_progress })
		else
			milestone_progress_text = "No assigned tickets"
		end if
    end if

    if length(local_where) then
        local_where = join(local_where, " AND ")
        if length(where) then
            where &= " AND "
        end if
        where &= local_where
    end if

    object tickets = ticket_db:get_list((page - 1) * per_page, per_page, where)

    -- Get the product name. If we have tickets we can get it from there, otherwise
    -- we will have to query the db specifically for the product name.
    if length(tickets) > 0 then
        map:put(data, "product_name", tickets[1][ticket_db:PRODUCT])

		for i = 1 to length(tickets) do
			switch tickets[i][TYPE_ID] do
				case 1 then
					tickets[i][ticket_db:ICON] = "bug"
				case 2 then
					tickets[i][ticket_db:ICON] = "bell"
				case 3 then
					tickets[i][ticket_db:ICON] = "script_gear"
			end switch
		end for

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

    map:put(data, "static_status_items", {
        { -2, "** All Opened **", "active_ticket" },
        { -3, "** All Closed **", "closed_ticket" },
		{ -4, "** Not Blocked **", "active_ticket" }
    })

    sequence static_developer_items = {}
    if has_role("developer") or has_role("admin") then
        static_developer_items = { { current_user[user_db:USER_ID], "** Me **", "me" } }
    end if

    map:put(data, "static_developer_items", static_developer_items)
    map:put(data, "by_milestone", by_milestone)
    map:put(data, "milestone_progress", milestone_progress)
    map:put(data, "milestone_progress_text", milestone_progress_text)

    return { TEXT, t_index:template(data) }
end function

function mine(map data, map request)
    return real_index(data, request, sprintf("(t.assigned_to_id=%d OR t.submitted_by_id=%d)",
        { current_user[user_db:USER_ID], current_user[user_db:USER_ID] }))
end function
wc:add_handler(routine_id("mine"), -1, "ticket", "mine", index_vars)

function opened(map data, map request)
    if map:get(request, "status_id") = -1 then
        return real_index(data, request, "tstat.is_open=1")
    else
        return real_index(data, request)
    end if
end function
wc:add_handler(routine_id("opened"), -1, "ticket", "index", index_vars)

function unassigned_tickets(map data, map request)
    return real_index(data, request, "t.assigned_to_id=0 AND tstat.is_open=1")
end function
wc:add_handler(routine_id("unassigned_tickets"), -1, "ticket", "unassigned", index_vars)

function confirm_tickets(map data, map request)
    map:put(request, "status_id", 8)
    return real_index(data, request, "tstat.id=8")
end function
wc:add_handler(routine_id("confirm_tickets"), -1, "ticket", "confirm", index_vars)

function closed(map data, map request)
    return real_index(data, request, "tstat.is_open=0")
end function
wc:add_handler(routine_id("closed"), -1, "ticket", "closed", index_vars)

sequence create_vars = {
    { wc:INTEGER,  "type_id",        -1 },
    { wc:INTEGER,  "product_id",     -1 },
    { wc:INTEGER,  "severity_id",    -1 },
    { wc:INTEGER,  "category_id",    -1 },
	{ wc:INTEGER,  "status_id",       1 },
	{ wc:INTEGER,  "assigned_to_id", -1 },
    { wc:SEQUENCE, "reported_release"   },
    { wc:SEQUENCE, "milestone"          },
    { wc:SEQUENCE, "content"            },
    { wc:SEQUENCE, "subject"            }
}

function ticket_create(map data, map request)
    if not has_role("user") then
        return { TEXT, t_security:template(data) }
    end if

    integer product_id = get_product_id(request, data)

    map:put(data, "id", "-1")
    map:copy(request, data)
    map:put(data, "product_name", edbi:query_object("SELECT name FROM ticket_product WHERE id=%d", {
        product_id }))

    return { TEXT, t_create:template(data) }
end function
wc:add_handler(routine_id("ticket_create"), -1, "ticket", "create", create_vars)

function validate_do_create(map data, map request)
    sequence errors = wc:new_errors("ticket", "create")

    if not has_role("user") then
        errors = wc:add_error(errors, "form", "You are not authorized to add a new ticket")
    end if

   if not equal(map:get(request, "save"), "Preview") then
    if map:get(request, "severity_id") = -1 then
        errors = wc:add_error(errors, "severity_id", "You must select a severity level.")
    end if

    if map:get(request, "category_id") = -1 then
        errors = wc:add_error(errors, "category_id", "You must select a category.")
    end if

    if map:get(request, "type_id") = -1 then
        errors = wc:add_error(errors, "type_id", "You must select a ticket type.")
    end if

    if length(trim(map:get(request, "subject"))) = 0 then
        errors = wc:add_error(errors, "subject", "Subject cannot be blank.")
    end if

    if length(trim(map:get(request, "content"))) = 0 then
        errors = wc:add_error(errors, "content", "Content cannot be blank.")
    end if
   end if

    return errors
end function

function do_create(map data, map request)
	if equal(map:get(request, "save"), "Preview") then
		object s
		s = map:get(request, "content")
		if atom(s) then
			s = ""
		end if
		map:put(data, "content_formatted", format_body(s))
		s = map:get(request, "comment")
		if atom(s) then
			s = ""
		end if
		map:put(data, "comment_formatted", format_body(s))
		return ticket_create(data, request)
	end if
    ticket_db:create(
        map:get(request, "type_id"),
        get_product_id(request),
        map:get(request, "severity_id"),
        map:get(request, "category_id"),
		map:get(request, "status_id"),
		map:get(request, "assigned_to_id"),
        map:get(request, "reported_release"),
        map:get(request, "milestone"),
        map:get(request, "subject"),
        map:get(request, "content"))

    if edbi:error_code() then
        map:put(data, "error_code", edbi:error_code())
        map:put(data, "error_message", edbi:error_message())

		return { TEXT, t_update_ok:template(data) }
    end if

	integer id = edbi:last_insert_id()

	return { REDIRECT_303, sprintf("/ticket/%d.wc", { id }) }
end function
wc:add_handler(routine_id("do_create"), routine_id("validate_do_create"), "ticket", "do_create",
    create_vars)

sequence detail_vars = {
    { wc:INTEGER, "id",                -1 },
    { wc:INTEGER, "remove_comment_id", -1 },
	{ wc:INTEGER, "full_edit",          0 }
}

function detail(map data, map request)
    object ticket = ticket_db:get(map:get(request, "id"))
    if atom(ticket) then
        return { TEXT, t_not_found:template(data) }
    end if

	if not equal(map:get(request, "save"), "Preview") then
    if map:get(request, "remove_comment_id") > -1 then
        if not has_role("admin") then
            return { TEXT, t_security:template(data) }
        end if

        ticket_db:remove_comment(map:get(request, "remove_comment_id"))
    end if
    end if

	if equal(map:get(request, "save"), "Preview") then
		map:copy(request, data)
	elsif map:get(data, "has_errors") then
		map:copy(request, data)
		map:put(data, "content", format_body(ticket[ticket_db:CONTENT], 0))
	else
		map:put(data, "id",               ticket[ticket_db:ID])
		map:put(data, "type_id",          ticket[ticket_db:TYPE_ID])
		map:put(data, "type",             ticket[ticket_db:TYPE])
		map:put(data, "severity_id",      ticket[ticket_db:SEVERITY_ID])
		map:put(data, "severity",         ticket[ticket_db:SEVERITY])
		map:put(data, "category_id",      ticket[ticket_db:CATEGORY_ID])
		map:put(data, "category",         ticket[ticket_db:CATEGORY])
		map:put(data, "reported_release", ticket[ticket_db:REPORTED_RELEASE])
		map:put(data, "milestone",        ticket[ticket_db:MILESTONE])
		map:put(data, "assigned_to_id",   ticket[ticket_db:ASSIGNED_TO_ID])
		map:put(data, "assigned_to",      ticket[ticket_db:ASSIGNED_TO])
		map:put(data, "submitted_by_id",  ticket[ticket_db:SUBMITTED_BY_ID])
		map:put(data, "submitted_by",     ticket[ticket_db:SUBMITTED_BY])
		map:put(data, "status_id",        ticket[ticket_db:STATUS_ID])
		map:put(data, "status",           ticket[ticket_db:STATUS])
		map:put(data, "svn_rev",          ticket[ticket_db:SVN_REV])
		map:put(data, "subject",          ticket[ticket_db:SUBJECT])

		if map:get(request, "full_edit") then
			map:put(data, "content", ticket[ticket_db:CONTENT])
		else
			map:put(data, "content", format_body(ticket[ticket_db:CONTENT], 0))
		end if
	end if

    map:put(data, "created_at", fuzzy_ago(ticket[ticket_db:CREATED_AT]))

    map:put(data, "comments", comment_db:get_all(ticket_db:MODULE_ID, map:get(request, "id")))
    map:put(data, "product_name", ticket[ticket_db:PRODUCT])
	map:put(data, "full_edit", map:get(request, "full_edit"))

	map:put(request, "product_id", ticket[ticket_db:PRODUCT_ID])
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
    { wc:SEQUENCE, "svn_rev" },
    { wc:SEQUENCE, "comment" },
	{ wc:INTEGER,  "full_edit", 0 },
	{ wc:SEQUENCE, "subject" },
	{ wc:SEQUENCE, "content" },
	{ wc:INTEGER, "submitted_by_id" }
}

function validate_update(map data, map request)
    sequence errors = wc:new_errors("ticket", "view")

    if not has_role("user") then
        errors = wc:add_error(errors, "form", "You are not authorized to edit or comment on a ticket")
    end if

    if not equal(map:get(request, "save"), "Preview") then
	if map:get(request, "full_edit") then
		if not valid:not_empty(map:get(request, "subject")) then
			errors = wc:add_error(errors, "subject", "Subject cannot be blank.")
		end if

		if not valid:not_empty(map:get(request, "content")) then
			errors = wc:add_error(errors, "content", "Content cannot be blank.")
		end if
	end if
    end if

    return errors
end function

function update(map data, map request)
    map:put(data, "error_code", 0)

    if map:get(request, "assigned_to_id") = -1 then
        map:put(request, "assigned_to_id", 0)
    end if

		   if equal(map:get(request, "save"), "Preview") then
			map:put(data, "content_formatted", format_body(map:get(request, "content")))
			map:put(data, "comment_formatted", format_body(map:get(request, "comment")))
			return detail(data, request)
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
            map:get(request, "severity_id"),
            map:get(request, "category_id"),
            map:get(request, "reported_release"),
            map:get(request, "milestone"),
            map:get(request, "assigned_to_id"),
            map:get(request, "status_id"),
            map:get(request, "svn_rev")
        )

		if map:get(request, "full_edit") then
			ticket_db:update_full(
				map:get(request, "id"),
					map:get(request, "subject"),
					map:get(request, "content"))
		end if

        if edbi:error_code() then
            map:put(data, "error_code", edbi:error_code())
            map:put(data, "error_message", edbi:error_message())
        end if
    end if

	sequence add_redirect = ""
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

			return { TEXT, t_update_ok:template(data) }
        end if

		add_redirect = sprintf("#%d", { edbi:last_insert_id() })
    end if

	return { REDIRECT_303, sprintf("/ticket/%d.wc%s", {
				map:get(request, "id"), add_redirect }) }
end function
wc:add_handler(routine_id("update"), routine_id("validate_update"), "ticket", "update", update_vars)

sequence change_product_vars = {
    { wc:SEQUENCE, "url", "/ticket/index.wc" }
}

function change_product(map data, map request)
    sequence products = edbi:query_rows("SELECT id, name FROM ticket_product ORDER BY name")

    map:copy(request, data)
    map:put(data, "products", products)

    return { TEXT, t_change_product:template(data) }
end function
wc:add_handler(routine_id("change_product"), -1, "ticket", "change_product", {})
