--****
-- == News database helpers

namespace news_db

include std/error.e
include std/get.e
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

include db.e

-- Templates
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
	return db:record_count( dbtable )
end function

--**
-- Get the thread list
-- 

sequence fields = "n.id,n.submitted_by_id,n.approved,n.approved_by_id,n.publish_at,n.subject,n.content,u.user"

public function get_article_list(integer page, integer per_page)
	sequence sql = `SELECT ` & fields & ` FROM news as n
		INNER JOIN users as u on n.submitted_by_id = u.id
		ORDER BY publish_at DESC
		LIMIT %d OFFSET %d`

	object data = mysql_query_rows(db, sql, { per_page, (page - 1) * per_page })
	if atom(data) then
		crash("Couldn't query the " & dbtable & " table: %s", { mysql_error(db) })
	end if

	return data
end function

--**
-- Get an article
--

public function get(integer id)
	return mysql_query_one(db, "SELECT * FROM news WHERE id=%d", { id })
end function
