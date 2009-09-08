--****
-- == News database helpers

namespace news_db

include std/datetime.e
include std/error.e
include std/get.e
include std/map.e

include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

include db.e

include templates/news/index.etml as t_index

--**
-- Get the number of news items
-- 
-- Returns:
--   An ##integer##
--

sequence dbtable = "news"

sequence index_invars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

public enum ID,SUBMITTED_BY_ID,APPROVED,APPROVED_BY_ID,PUBLISH_AT,SUBJECT,CONTENT,AUTHOR_NAME

public function article_count()
	return db:record_count(dbtable)
end function

--**
-- Get the thread list
-- 

sequence fields = "n.id,n.submitted_by_id,n.approved,n.approved_by_id,n.publish_at,n.subject,n.content,u.user"

public function get_article_list(integer page, integer per_page)
	sequence sql = `SELECT ` & fields & ` FROM news as n
		INNER JOIN users as u on n.submitted_by_id = u.id
		WHERE publish_at < NOW()
		ORDER BY publish_at DESC
		LIMIT %d OFFSET %d`

	object data = edbi:query_rows(sql, { per_page, (page - 1) * per_page })
	if atom(data) then
		crash("Couldn't query the " & dbtable & " table: %s", { edbi:error_message() })
	end if

	return data
end function

--**
-- Get an article
--

public function get(integer id)
	return edbi:query_row("SELECT * FROM news WHERE id=%d", { id })
end function

--**
-- Save an article

public procedure save(integer id, sequence subject, sequence content)
	if edbi:execute("UPDATE news SET subject=%s, content=%s WHERE id=%d", 
		{ subject, content, id })
	then
		crash("Could not update news article.")
	end if
end procedure

public function insert(sequence subject, sequence content)
	if edbi:execute(`INSERT INTO news 
		(submitted_by_id, approved, approved_by_id, publish_at, subject, content) VALUES (
		%d, 1, %d, %T, %s, %s)`, { 
			current_user[USER_ID], current_user[USER_ID], datetime:now(), 
			subject, content })
	then
		crash("Could not create news article.")
	end if

	return edbi:last_insert_id()
end function

