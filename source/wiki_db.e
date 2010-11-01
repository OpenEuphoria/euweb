--****
-- == Wiki database helpers
--

namespace wiki_db

include std/datetime.e as dt
include std/error.e
include std/get.e
include std/regex.e as re

include webclay/logging.e as log

include edbi/edbi.e

include user_db.e as user_db

public constant MODULE_ID=3

public enum WIKI_REV, WIKI_NAME, WIKI_CREATED_AT, WIKI_CREATED_BY_ID, WIKI_CHANGE_MSG,
	WIKI_TEXT, WIKI_CREATED_BY, WIKI_TEXT_FORMATTED

constant BASE_FROM = """
FROM
    wiki_page AS w
	INNER JOIN users AS uc ON (w.created_by_id = uc.id)
"""

constant BASE_QUERY = """SELECT
    w.rev, w.name, w.created_at, w.created_by_id, w.change_msg, w.wiki_text, uc.user
""" & BASE_FROM

--**
-- Get the number of wiki pages

public function count(sequence where = "")
	sequence sql = "SEELCT COUNT(w.name) " & BASE_FROM & " WHERE w.rev = 0"
	if length(where) > 0 then
		sql &= " AND " & where
	end if

	return edbi:query_object(sql)
end function

--**
-- Get a given wiki page

public function get(sequence name, integer rev = 0)
	sequence sql = BASE_QUERY & " WHERE w.name=%s AND w.rev=%d"
	return edbi:query_row(sql, { name, rev })
end function

--**
-- Create a wiki page

public function create(sequence wiki)
	return edbi:execute("""
		INSERT INTO wiki_page (
			rev, name, created_at, created_by_id, change_msg, wiki_text
		) VALUES (%d, %s, %T, %d, %s, %s)""", wiki[1..6])
end function

--**
-- Update a wiki page
--

public function update(sequence name, sequence wiki_text, sequence change_msg,
			sequence user=current_user, integer in_tx = 0)
	integer status
	
	if not in_tx then
		status = edbi:execute("begin")
	end if
	
	sequence wiki = { 0, name, dt:now(), user[USER_ID], change_msg, wiki_text }
	integer new_rev = edbi:query_object("SELECT MAX(rev) + 1 FROM wiki_page WHERE name=%s", { name })
	if new_rev > 0 then
		status = edbi:execute("UPDATE wiki_page SET rev=%d WHERE rev=0 AND name=%s", { new_rev, name })
	end if

	integer result = create(wiki)
	
	if not in_tx then
		status = edbi:execute("commit")
	end if
	
	return result
end function

--**
-- Revert a wiki page to a prior revision

public function revert(sequence name, integer revision, sequence modify_reason,
			sequence user=current_user)
	object wiki = get(name, revision)
	if atom(wiki) then
		return 0
	end if

	return update(name, wiki[WIKI_TEXT], modify_reason, user)
end function

--**
-- Remove a wiki page
--
-- This does not really remove it, it simply updates the tip to the newest
-- revision number. This makes it "headless" and it no longer appears anywhere
--

public function remove(sequence name, sequence modify_reason="removed",
			sequence user=current_user)
	object new_rev = edbi:query_object("SELECT MAX(rev) + 1 FROM wiki_page WHERE name=%s", { name })
	if new_rev > 0 then
		return edbi:execute("UPDATE wiki_page SET rev=%d WHERE name=%s and rev=0", {
			new_rev, name })
	end if

	return 0
end function

constant q_category_wiki = """
SELECT 
w.name AS name, 'world.png', CONCAT('/wiki/view/', w.name, '.wc')
FROM wiki_page AS w
INNER JOIN users AS u ON (w.created_by_id=u.id)
WHERE w.rev = 0 AND MATCH(w.name,w.wiki_text) AGAINST(%s IN BOOLEAN MODE)
"""

constant q_category_forum = """
SELECT m.subject AS name, 'email.png', CONCAT('/forum/', m.id, '.wc')
FROM messages AS m
WHERE m.parent_id = 0 AND MATCH(m.subject,m.body) AGAINST(%s IN BOOLEAN MODE)
"""

--**
-- Get a list of pages belonging to a given category
--
-- Parameters:
--   * category - category nameame to query for
--   * all - try to categorize wiki pages, forum messages and tickets
--

public function get_category_list(sequence category, integer all = 0)
	sequence sql, params = {}
	
	if all then
		sql = q_category_wiki & " UNION ALL " & 
		q_category_forum
		params = { "+" & category, "+" & category }
	else
		sql = q_category_wiki
		params = { "+" & category }
	end if

	sql &= " ORDER BY name"
	
	return edbi:query_rows(sql, params)
end function

--**
-- Get the history for a page

public function get_history(sequence page)
	return edbi:query_rows(BASE_QUERY &
		" WHERE w.name = %s ORDER BY IF(w.rev=0,9999999,w.rev) DESC", { page })
end function

--**
-- Rename a wiki page 

public function rename(sequence page, sequence new_page, sequence user=current_user)
	object current_page = get(page)
	if atom(current_page) then
		return 0
	end if
	
	integer status
	status = edbi:execute("begin")

	-- rename the main page name
	status = edbi:execute("UPDATE wiki_page SET name=%s WHERE name=%s",
		{ new_page, page })

	-- update the page which will create a new revision with our change
	-- message
	status = update(new_page, current_page[WIKI_TEXT], 
		sprintf("Renamed from %s", { page }), user, 1)

	-- find each page referencing 'page' and rename their links
	object linking_pages = edbi:query_rows("""
		SELECT name, wiki_text
		FROM wiki_page
		WHERE MATCH(name, wiki_text) AGAINST(%s IN BOOLEAN MODE) AND rev=0
		""", 
		{  page } )
	
	re:regex page_re = re:new("(?<!~)" & page)
	
	sequence updated_pages = {}
	
	for i = 1 to length(linking_pages) do
		sequence name      = linking_pages[i][1]
		sequence wiki_text = linking_pages[i][2]
	
		updated_pages = append(updated_pages, name)
	
		wiki_text = re:find_replace(page_re, wiki_text, new_page)
		status = update(name, wiki_text, 
			sprintf("Referenced page renamed, %s to %s", { page, new_page }),
			user, 1)
	end for
	
	status = edbi:execute("commit")
	
	return updated_pages
end function
