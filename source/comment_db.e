--****
-- == Comment database helpers 
--

namespace comment_db

include std/error.e

include webclay/logging.e as log
include edbi/edbi.e

include format.e
include fuzzydate.e
include user_db.e

public enum ID, MODULE_ID, ITEM_ID, USER_ID, CREATED_AT, SUBJECT, BODY, USER

function isdel()
	if atom(current_user) then
		return "(is_deleted = 0)"
	end if
	if equal(current_user[USER_NAME], "unknown") then
		return "(is_deleted = 0 or is_deleted = 4 or is_deleted = 2)"
	else
		return "is_deleted = 0"
	end if
end function

--**
-- Get all comments for a module/id pair

public function get_all(integer module_id, integer id)
	object rows = edbi:query_rows("SELECT c.id, c.module_id, c.item_id, c.user_id, c.created_at, c.subject, c.body, "&
	"u.user FROM comment AS c, users AS u \n"&
		" WHERE "&isdel()&" and u.id = c.user_id AND c.module_id=%d AND item_id=%d ORDER BY id", { module_id, id })
	for i = 1 to length(rows) do
		rows[i][CREATED_AT] = fuzzy_ago(rows[i][CREATED_AT])
		rows[i][BODY] = format_body(rows[i][BODY], 0)
	end for
	return rows
end function

--**
-- Add a comment

public function add_comment(integer module_id, integer id, sequence subject, sequence comment)
	integer is_deleted = 0
	return edbi:execute("""INSERT INTO comment 
		(module_id, item_id, user_id, created_at, subject, body, is_deleted)
		VALUES (%d, %d, %d, NOW(), %s, %s, %d)""", { module_id, id, current_user[user_db:USER_ID], 
		subject, comment, is_deleted })
end function

--**
-- Remove a comment

public function remove_comment(integer id)
	return edbi:execute("UPDATE comment SET is_deleted = 1 WHERE id=%d", { id })
end function

public function erase_comment(integer id)
	return edbi:execute("DELETE FROM comment WHERE id=%d", { id })
end function
