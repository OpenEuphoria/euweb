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
	CATEGORY_ID, STATUS_ID, STATE_ID, REPORTED_RELEASE_ID, SUBJECT, CONTENT,
	RESOLVED_AT, SVN_REV, SUBMITTED_BY, ASSIGNED_TO, SEVERITY, CATEGORY, STATUS,
	STATE, REPORTED_RELEASE

--**
-- Get the number of tickets

public function count()
	return edbi:query_object("SELECT COUNT(id) FROM ticket")
end function

constant BASE_QUERY = """SELECT
	t.id, t.created_at, t.submitted_by_id, t.assigned_to_id, t.severity_id, 
	t.category_id, t.status_id, t.state_id, t.reported_release_id, t.subject, t.content, 
	t.resolved_at, t.svn_rev, tsb.user AS submitted_by, tas.user AS assigned_to,
	tsev.name AS severity, tcat.name AS category, tstat.name AS status,
	tstate.name AS state, rel.name AS reported_release
FROM
	ticket AS t, users AS tsb, users AS tas, ticket_severity AS tsev,
	ticket_category AS tcat, ticket_status AS tstat, ticket_state AS tstate, 
	releases AS rel
WHERE
	tsb.id = t.submitted_by_id AND
	tas.id = t.assigned_to_id AND
	tsev.id = t.severity_id AND
	tcat.id = t.category_id AND
	tstat.id = t.status_id AND
	tstate.id = t.state_id AND
	rel.id = t.reported_release_id
"""

--**
-- Get a list of tickets for the given criteria

public function get_list(integer offset=0, integer per_page=10, sequence where="")
	sequence sql = BASE_QUERY
	if length(where) then
		sql &= " AND " & where
	end if
	sql &= " ORDER BY tsev.position DESC, t.created_at"
	sql &= " LIMIT %d OFFSET %d"
	return edbi:query_rows(sql, { per_page, offset })
end function

--**
-- Get a single ticket

public function get(integer id)
	return edbi:query_row(BASE_QUERY & " AND t.id=%d", { id })
end function

--**
-- Insert a new ticket

public function create(integer severity_id, integer category_id, integer reported_release_id, 
		sequence subject, sequence content)
	return edbi:execute("""INSERT INTO ticket (assigned_to_id, status_id, state_id, created_at, 
		submitted_by_id, 
		severity_id, category_id, reported_release_id, subject, content) 
		VALUES (0, 1, 1, NOW(), %d, %d, %d, %d, %s, %s)""", { current_user[USER_ID], severity_id, 
		category_id, reported_release_id, subject, content })
end function

--**
-- Update a ticket

public function update(integer id, integer severity_id, integer category_id, 
		integer reported_release_id, integer assigned_to_id, integer status_id, 
		integer state_id, sequence svn_rev)
	return edbi:execute("""UPDATE ticket SET severity_id=%d, category_id=%d, 
 		reported_release_id=%d, assigned_to_id=%d, status_id=%d, state_id=%d,
		svn_rev=%s WHERE id=%d""", { severity_id, category_id, reported_release_id,
			assigned_to_id, status_id, state_id, svn_rev, id })
end function
