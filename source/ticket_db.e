--****
-- == Ticket database helpers
--

namespace ticket_db

include std/datetime.e
include std/error.e
include std/get.e

include webclay/logging.e as log
include edbi/edbi.e

public constant MODULE_ID=1

public enum ID, CREATED_AT, SUBMITTED_BY_ID, ASSIGNED_TO_ID, SEVERITY_ID,
	CATEGORY_ID, STATUS_ID, REPORTED_RELEASE, MILESTONE, SUBJECT, CONTENT,
	RESOLVED_AT, SVN_REV, SUBMITTED_BY, ASSIGNED_TO, SEVERITY, CATEGORY, STATUS,
	PRODUCT_ID, PRODUCT, TYPE_ID, TYPE, ICON

function isdel()
	if not object(current_user) or atom(current_user) then
		return "(is_deleted = 0)"
	end if
	if equal(current_user[USER_NAME], "unknown") then
		return "(is_deleted = 0 or is_deleted = 4 or is_deleted = 2)"
	else
		return "is_deleted = 0"
	end if
end function

constant BASE_FROM = """
FROM
	ticket AS t
	join users AS tsb on tsb.id=t.submitted_by_id
	left join users AS tas on tas.id=t.assigned_to_id
	join ticket_severity AS tsev on tsev.id=t.severity_id
	join ticket_category AS tcat on tcat.id=t.category_id
	join ticket_status AS tstat on tstat.id=t.status_id
	join ticket_product AS tprod on tprod.id=t.product_id
	join ticket_type AS ttype on ttype.id=t.type_id
WHERE
	t.id != 0 and
"""

constant BASE_QUERY = """SELECT
	t.id, t.created_at, t.submitted_by_id, t.assigned_to_id, t.severity_id,
	t.category_id, t.status_id, t.reported_release, t.milestone, t.subject,
    t.content, t.resolved_at, t.svn_rev, tsb.user AS submitted_by,
    tas.user AS assigned_to, tsev.name AS severity, tcat.name AS category,
    tstat.name AS status, t.product_id, tprod.name, t.type_id,
    ttype.name, '' as icon
""" & BASE_FROM

--**
-- Get the number of tickets

public function count(sequence where = "")
    sequence sql = "SELECT COUNT(t.id) " & BASE_FROM & isdel()
    if length(where) > 0 then
        sql &= " AND " & where
    end if

	return edbi:query_object(sql)
end function

--**
-- Get a list of tickets for the given criteria

public function get_list(integer offset=0, integer per_page=10, sequence where="")
	sequence sql = BASE_QUERY & isdel()
	if length(where) then
		sql &= " AND " & where
	end if
	sql &= " ORDER BY tsev.position DESC, LENGTH(t.milestone) = 0, t.milestone"
	sql &= " LIMIT %d OFFSET %d"

	return edbi:query_rows(sql, { per_page, offset })
end function

--**
-- Get a single ticket

public function get(integer id)
	return edbi:query_row(BASE_QUERY & isdel() & " AND t.id=%d", { id })
end function

--**
-- Insert a new ticket

public function create(integer type_id, integer product_id, integer severity_id,
		integer category_id, integer status_id, integer assigned_to_id, 
		sequence reported_release, sequence milestone, sequence subject,
        sequence content, integer is_deleted)
	sequence assignment = "NULL"
	if assigned_to_id > -1 then
		assignment = sprintf("%d", { assigned_to_id })
	end if
	
	return edbi:execute(
		"""INSERT INTO ticket (created_at, status_id, submitted_by_id, assigned_to_id,
		type_id, product_id, severity_id, category_id, reported_release, milestone, 
		subject, content, is_deleted) 
		VALUES (NOW(), %d, %d, %S, %d, %d, %d, %d, %s, %s, %s, %s, %d)""", 
		{
			status_id, current_user[USER_ID], assignment, type_id, product_id, 
			severity_id, category_id, reported_release, milestone, subject, 
			content, is_deleted
		}
	)
end function

--**
-- Update a ticket
--
-- See Also:
--   [[:update_full]]
--

public function update(integer id, integer type_id, integer severity_id,
		integer category_id, sequence reported_release, sequence milestone, integer assigned_to_id,
        integer status_id, sequence svn_rev)
	return edbi:execute("""UPDATE ticket SET type_id=%d, severity_id=%d,
		category_id=%d, reported_release=%s, milestone=%s, assigned_to_id=%d, status_id=%d,
		svn_rev=%s WHERE id=%d""", { type_id, severity_id, category_id,
			reported_release, milestone, assigned_to_id, status_id, svn_rev, id })
end function

--**
-- Update the full details (subject and content) of a ticket
-- 
-- Parameters:
--    * ##ticket_id## - integer id for the ticket to update
--    * ##subject##   - new subject
--    * ##content##   - new content
--
-- Returns:
--   Integer success code   
--
-- See Also:
--   [[:update]]
--

public function update_full(integer id, sequence subject, sequence content)
	return edbi:execute("UPDATE ticket SET subject=%s, content=%s WHERE id=%d", {
			subject, content, id })
end function

--**
-- Update the product id of a ticket
-- 
-- Parameters:
--    * ##ticket_id## - integer id for the ticket to update
--    * ##product_id##   - new product
--
-- Returns:
--   Integer success code   
--
-- See Also:
--   [[:update]]
--

public function update_product_id(integer id, integer product_it)
	return edbi:execute("UPDATE ticket SET product_id=%d WHERE id=%d", {
			product_it, id })
end function

--**
-- Remove a ticket comment

public function remove_comment(integer id)
	return edbi:execute("DELETE FROM comment WHERE id=%d", { id })
end function

--**
-- Adds a ticket milestone

public function add_milestone(sequence milestone_name, integer product_it)
	return edbi:execute("INSERT INTO ticket_milestone VALUES (%s, %d)", {
			milestone_name, product_it })
end function
