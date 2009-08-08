--****
-- == Forum database helpers
-- 

namespace forum_db

include std/error.e
include std/get.e

include webclay/logging.e as log

include db.e

--**
-- Get the number of messages
-- 
-- Returns:
--   An ##integer##
--

public function message_count()
 	return defaulted_value(mysql_query_object(db, "SELECT COUNT(id) FROM messages"), 0)
end function

--**
-- Get the number of threads
-- 
-- Returns:
--   An ##integer##
--

public function thread_count()
 	return defaulted_value(
		mysql_query_object(db, "SELECT COUNT(id) FROM messages WHERE parent_id=0"), 0)
end function

public enum THREAD_ID, THREAD_CREATED_AT, THREAD_AUTHOR_NAME, THREAD_SUBJECT,
	THREAD_VIEWS, THREAD_REPLIES, THREAD_LAST_POST_ID, THREAD_LAST_POST_BY,
	THREAD_LAST_POST_AT

--**
-- Get the thread list
-- 

public function get_thread_list(integer page, integer per_page)
	sequence sql = `SELECT m.id, m.created_at, m.author_name, m.subject, m.views, m.replies, 
			m.last_post_id, m.last_post_by, m.last_post_at 
		FROM 
			messages AS m
		WHERE
			m.parent_id = 0
		ORDER BY m.last_post_at DESC 
		LIMIT %d OFFSET %d`

	object data = mysql_query_rows(db, sql, { per_page, page * per_page })
	if atom(data) then
		crash("Couldn't query the messages table: %s", { mysql_error(db) })
	end if

	return data
end function

public enum MSG_ID, MSG_CREATED_AT, MSG_PARENT_ID, MSG_AUTHOR_NAME, MSG_AUTHOR_EMAIL,
	MSG_SUBJECT, MSG_BODY, MSG_VIEWS, MSG_IP, MSG_LAST_POST_ID, MSG_REPLIES,
	MSG_LAST_POST_BY, MSG_LAST_POST_AT, MSG_LAST_POST_BY_ID, POST_BY

--**
-- Get a message
--

public function get(integer id)
	return mysql_query_one(db, "SELECT * FROM messages WHERE id=%d", { id })
end function
