--****
-- == Forum database helpers
-- 

namespace forum_db

include std/datetime.e
include std/error.e
include std/get.e

include webclay/logging.e as log

include config.e
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

public procedure inc_view_counter(integer topic_id)
	if mysql_query(db, "UPDATE messages SET views=views+1 WHERE topic_id=%d", { topic_id }) then
		crash("Could not update message view counter")
	end if
end procedure

public enum THREAD_ID, THREAD_TOPIC_ID, THREAD_CREATED_AT, THREAD_AUTHOR_NAME, THREAD_SUBJECT,
	THREAD_VIEWS, THREAD_REPLIES, THREAD_LAST_POST_ID, THREAD_LAST_POST_BY,
	THREAD_LAST_POST_AT

--**
-- Get the thread list
-- 

public function get_thread_list(integer page, integer per_page)
	sequence sql = `SELECT m.id, m.topic_id, m.created_at, m.author_name, m.subject, 
			m.views, m.replies, m.last_post_id, m.last_post_by, m.last_post_at 
		FROM 
			messages AS m
		WHERE
			m.parent_id = 0
		ORDER BY m.last_post_at DESC 
		LIMIT %d OFFSET %d`

	object data = mysql_query_rows(db, sql, { per_page, (page - 1) * per_page })
	if atom(data) then
		crash("Couldn't query the messages table: %s", { mysql_error(db) })
	end if

	return data
end function

public enum MSG_ID, MSG_TOPIC_ID, MSG_PARENT_ID, MSG_CREATED_AT,  
	MSG_SUBJECT, MSG_BODY, MSG_IP, MSG_AUTHOR_NAME, MSG_AUTHOR_EMAIL, MSG_POST_BY_ID, 
	MSG_VIEWS, MSG_REPLIES, MSG_LAST_POST_ID, MSG_LAST_POST_BY, MSG_LAST_POST_AT, 
	MSG_LAST_POST_BY_ID, MSG_LAST_EDIT_AT, MSG_BODY_FORMATTED

constant message_select_fields = ` id, topic_id, parent_id, created_at, subject, body, ip,
	author_name, author_email, post_by, views, replies, last_post_id, last_post_by,
 	last_post_at, last_post_by_id, last_edit_at `

--**
-- Get a message
--

public function get(integer id)
	return mysql_query_one(db, "SELECT " & message_select_fields & 
 		"FROM messages WHERE id=%d", { id })
end function

public function get_topic_messages(integer topic_id)
	object messages = mysql_query_rows(db, "SELECT " & message_select_fields &
		" FROM messages WHERE topic_id=%d ORDER BY id", { topic_id })
	if length(messages) then
		return messages
	end if

	object msg = get(topic_id)
	if sequence(msg) then
		messages = mysql_query_rows(db, "SELECT " & message_select_fields &
			" FROM messages WHERE topic_id=%s ORDER BY id", { msg[MSG_TOPIC_ID] })
	end if

	return messages
end function

public function create(integer parent_id, integer topic_id, sequence subject,
		sequence body)	
	sequence sql
	sequence params
	datetime now = datetime:now()
	if length(subject) = 0 then
		subject = "no subject"
	end if
	if parent_id = -1 then
		sql = `INSERT INTO messages (parent_id, author_name, author_email, 
				subject, body, post_by, last_post_at, last_edit_at) 
				VALUES (0, %s, %s, %s, %s, %s, %T, %T)`
		params = { current_user[USER_NAME], current_user[USER_EMAIL], subject, body, 
			current_user[USER_ID], now, now }
	else
		sql = `INSERT INTO messages (topic_id, parent_id, author_name, author_email, 
			subject, body, post_by, last_edit_at) VALUES (%d, %d, %s, %s, %s, %s, %s, %T)`
		params = { topic_id, parent_id, current_user[USER_NAME], current_user[USER_EMAIL], 
			subject, body, current_user[USER_ID], now }
	end if

	if mysql_query(db, sql, params) then
		crash("Couldn't insert new message: %s", { mysql_error(db) })
	end if

	integer id = mysql_insert_id(db)
	
	-- Update the original
	if mysql_query(db, `UPDATE messages SET last_post_id=%d, replies=replies+1, last_post_by=%s,
		last_post_at=%T, last_post_by_id=%d WHERE id=%d`, { 
			id, current_user[USER_NAME], now, current_user[USER_ID], topic_id })
	then
		crash("Couldn't update parent message: %s", { mysql_error(db) })
	end if
	
	object message = get(id)
	if atom(message) then
		crash("Saved message could not be accessed: %s", { mysql_error(db) })
	end if
	
	if topic_id = -1 then
		mysql_query(db, "UPDATE messages SET topic_id=%d WHERE id=%d", { id, id })
		message[MSG_TOPIC_ID] = message[MSG_ID]
	end if
	
	return message
end function

public procedure update(sequence message)
	if mysql_query(db, `UPDATE messages SET last_edit_at=CURRENT_TIMESTAMP, subject=%s,
			body=%s WHERE id=%s`, { message[MSG_SUBJECT], message[MSG_BODY], message[MSG_ID] })
	then
		crash("Couldn't update message: %s", { mysql_error(db) })
	end if
end procedure

public procedure remove_post(integer id)
	if mysql_query(db, "DELETE FROM messages WHERE id=%d", { id }) then
		crash("Couldn't remove forum post: %s", { mysql_error(db) })
	end if
	if mysql_query(db, "DELETE FROM messages WHERE topic_id=%d", { id }) then
		crash("Couldn't remove children from forum post: %s", { mysql_error(db) })
	end if
end procedure

public procedure update_forked_body(integer fork_id, integer orig_id, sequence subject)
	sequence fork_message = sprintf("\n\\\\**Forked into: [[%s/forum/%d.wc|%s]]**", { 
		ROOT_URL, fork_id, subject })
	
	mysql_query(db, `UPDATE messages SET body = CONCAT(body, %s) WHERE id=%d`, {
		fork_message, orig_id })
end procedure
