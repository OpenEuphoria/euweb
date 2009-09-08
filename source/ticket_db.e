--****
-- == Ticket database helpers 
--

namespace ticket_db

include std/datetime.e
include std/error.e
include std/get.e

include webclay/logging.e as log
include edbi/edbi.e

public enum ID, CREATED_AT, SUBMITTED_BY_ID, ASSIGNED_TO_ID, SEVERITY_ID, 
	CATEGORY_ID, STATUS_ID, REPORTED_RELEASE_ID, BODY, SUBJECT,
	RESOLVED_AT, SVN_REV, SUBMITTED_BY, ASSIGNED_TO, SEVERITY, CATEGORY, STATUS,
	REPORTED_RELEASE

--**
-- Get the number of tickets

public function count()
	return edbi:query_object("SELECT COUNT(id) FROM ticket")
end function

constant BASE_QUERY = """SELECT
	t.id, t.created_at, t.submitted_by_id, t.assigned_to_id, t.severity_id, 
	t.category_id, t.status_id, t.reported_release_id, t.body, t.subject,
	t.resolved_at, t.svn_rev, tsb.user AS submitted_by, tas.user AS assigned_to,
	tsev.name AS severity, tcat.name AS category, tstat.name AS status,
	rel.name AS reported_release
FROM
	ticket AS t, users AS tsb, users AS tas, ticket_severity AS tsev,
	ticket_category AS tcat, ticket_status AS tstat, releases AS rel
WHERE
	tsb.id = t.submitted_by_id AND
	tas.id = t.assigned_to_id AND
	tsev.id = t.severity_id AND
	tcat.id = t.category_id AND
	tstat.id = t.status_id AND
	rel.id = t.reported_release_id
"""

--**
-- Get a list of tickets for the given criteria

public function get_list(integer offset=0, integer per_page=10)
	return edbi:query_rows(BASE_QUERY & " LIMIT %d OFFSET %d", { per_page, offset })
end function

--**
-- Insert a new ticket

public function create(integer severity_id, integer category_id, integer reported_release_id, 
		sequence body, sequence subject)
	return edbi:execute("""INSERT INTO ticket (assigned_to_id, status_id, state_id, created_at, 
		submitted_by_id, 
		severity_id, category_id, reported_release_id, body, subject) 
		VALUES (0, 1, 1, NOW(), %d, %d, %d, %d, %s, %s)""", { current_user[USER_ID], severity_id, 
		category_id, reported_release_id, body, subject })
end function

