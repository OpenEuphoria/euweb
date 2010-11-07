--****
-- == Forum database helpers
-- 

namespace forum_db

include std/datetime.e
include std/error.e
include std/get.e

include webclay/logging.e as log
include edbi/edbi.e

include config.e
include db.e

public constant MODULE_ID = 4

--**
-- Get the number of messages
-- 
-- Returns:
--   An ##integer##
--

public function message_count()
 	return edbi:query_object("SELECT COUNT(id) FROM messages")
end function

--**
-- Get the number of threads
-- 
-- Returns:
--   An ##integer##
--

public function thread_count()
 	return edbi:query_object("SELECT COUNT(id) FROM messages WHERE parent_id=0")
end function

public procedure inc_view_counter(integer topic_id)
	if edbi:execute("UPDATE messages SET views=views+1 WHERE topic_id=%d", { topic_id }) then
		crash("Could not update message view counter")
	end if
end procedure

public procedure inc_message_view_counter(integer id)
	edbi:execute("UPDATE messages SET views=views+1 WHERE id=%d", { id })
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

	object data = edbi:query_rows(sql, { per_page, (page - 1) * per_page })
	if atom(data) then
		crash("Couldn't query the messages table: %s", { edbi:error_message() })
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
	return edbi:query_row("SELECT " & message_select_fields & "FROM messages WHERE id=%d", { id })
end function

--**
-- Get a message list for an index
-- 

public function get_list(integer page, integer per_page)
	return edbi:query_rows("SELECT " & message_select_fields & " FROM messages ORDER BY id DESC LIMIT %d OFFSET %d", { per_page, (page - 1) * per_page })
end function

public function get_topic_messages(integer topic_id)
	object messages = edbi:query_rows("SELECT " & message_select_fields &
		" FROM messages WHERE topic_id=%d ORDER BY id", { topic_id })
	if length(messages) then
		return messages
	end if

	object msg = get(topic_id)
	if sequence(msg) then
		messages = edbi:query_rows("SELECT " & message_select_fields &
			" FROM messages WHERE topic_id=%d ORDER BY id", { msg[MSG_TOPIC_ID] })
	end if

	return messages
end function

public function create(integer parent_id, integer topic_id, sequence subject,
		sequence body)	
	sequence sql
	sequence params
	datetime now = datetime:now()

	if parent_id = -1 then
		sql = `INSERT INTO messages (parent_id, author_name, author_email, 
				subject, body, post_by, last_post_at, last_edit_at) 
				VALUES (0, %s, %s, %s, %s, %d, %T, %T)`
		params = { current_user[USER_NAME], current_user[USER_EMAIL], subject, body, 
			current_user[USER_ID], now, now }
	else
		sql = `INSERT INTO messages (topic_id, parent_id, author_name, author_email, 
			subject, body, post_by, last_edit_at) VALUES (%d, %d, %s, %s, %s, %s, %d, %T)`
		params = { topic_id, parent_id, current_user[USER_NAME], current_user[USER_EMAIL], 
			subject, body, current_user[USER_ID], now }
	end if

	if edbi:execute(sql, params) then
		crash("Couldn't insert new message: %s", { edbi:error_message() })
	end if

	integer id = edbi:last_insert_id()
	
	-- Update the original
	if edbi:execute(`UPDATE messages SET last_post_id=%d, replies=replies+1, last_post_by=%s,
		last_post_at=%T, last_post_by_id=%d WHERE id=%d`, { 
			id, current_user[USER_NAME], now, current_user[USER_ID], topic_id })
	then
		crash("Couldn't update parent message: %s", { edbi:error_message() })
	end if
	
	object message = get(id)
	if atom(message) then
		crash("Saved message could not be accessed: %s", { edbi:error_message() })
	end if
	
	if topic_id = -1 then
		edbi:execute("UPDATE messages SET topic_id=%d WHERE id=%d", { id, id })
		message[MSG_TOPIC_ID] = message[MSG_ID]
	end if
	
	return message
end function

public procedure update(sequence message)
	if edbi:execute(`UPDATE messages SET last_edit_at=CURRENT_TIMESTAMP, subject=%s,
			body=%s WHERE id=%d`, { message[MSG_SUBJECT], message[MSG_BODY], message[MSG_ID] })
	then
		crash("Couldn't update message: %s", { edbi:error_message() })
	end if
end procedure

public procedure remove_post(integer id)
	object topic_id = edbi:query_object("SELECT topic_id FROM messages WHERE id=%d", { id })

	if edbi:execute("DELETE FROM messages WHERE id=%d", { id }) then
		crash("Couldn't remove forum post: %s", { edbi:error_message() })
	end if
	if edbi:execute("DELETE FROM messages WHERE topic_id=%d", { id }) then
		crash("Couldn't remove children from forum post: %s", { edbi:error_message() })
	end if
	
	object message_count = edbi:query_object("SELECT COUNT(*) FROM messages WHERE topic_id=%d",
		{ topic_id })
	object last_post_id = edbi:query_object("""SELECT id FROM messages 
		WHERE topic_id=%d ORDER BY created_at DESC LIMIT 1""", { topic_id })
	object last_post = get(last_post_id)

	if message_count then
		edbi:execute("""UPDATE messages SET last_post_id=%d, last_post_by=%s, last_post_by_id=%d, 
			last_post_at=%T, replies=%d WHERE id=%d""", { 
				last_post[MSG_ID], last_post[MSG_AUTHOR_NAME], last_post[MSG_POST_BY_ID],
	 			last_post[MSG_CREATED_AT], message_count, topic_id
			})
	end if
end procedure

public procedure update_forked_body(integer fork_id, integer orig_id, sequence subject)
	sequence fork_message = sprintf("\n\\\\**Forked into: [[%s/forum/%d.wc|%s]]**", { 
		ROOT_URL, fork_id, subject })
	
	edbi:execute(`UPDATE messages SET body = CONCAT(body, %s) WHERE id=%d`, {
		fork_message, orig_id })
end procedure

