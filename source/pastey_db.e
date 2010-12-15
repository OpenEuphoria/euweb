--****
-- == Pastey database helpers

namespace pastey_db

include std/datetime.e
include std/error.e
include std/get.e
include std/map.e

include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

include db.e

public constant MODULE_ID=5

sequence dbtable = "pastey"

--**
-- Get the number of pastey items
-- 
-- Returns:
--   An ##integer##
--

public function count()
	return db:record_count(dbtable)
end function

public enum ID, USER_ID, CREATED_AT, TITLE, BODY, USERNAME

sequence fields = "p.id, p.user_id, p.created_at, p.title, p.body, u.user"
sequence base_sql = `SELECT ` & fields & ` FROM pastey as p
	INNER JOIN users as u on p.user_id = u.id `

public function recent(integer page, integer per_page)
	sequence sql = base_sql & "ORDER BY id DESC LIMIT %d OFFSET %d"

	object data = edbi:query_rows(sql, { per_page, (page - 1) * per_page })
	if atom(data) then
		crash("Couldn't query the " & dbtable & " table: %s", { edbi:error_message() })
	end if

	return data
end function

