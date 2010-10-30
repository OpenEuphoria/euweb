--****
-- == Wiki database helpers
--

namespace wiki_db

include std/datetime.e as dt
include std/error.e
include std/get.e

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
			sequence user=current_user)
	integer status

	status = edbi:execute("begin")

	sequence wiki = { 0, name, dt:now(), user[USER_ID], change_msg, wiki_text }
	integer new_rev = edbi:query_object("SELECT MAX(rev) + 1 FROM wiki_page WHERE name=%s", { name })
	if new_rev > 0 then
		status = edbi:execute("UPDATE wiki_page SET rev=%d WHERE rev=0 AND name=%s", { new_rev, name })
	end if

	integer result = create(wiki)

	status = edbi:execute("commit")

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
-- Get a list of pages belonging to a given category

public function get_category_list(sequence category)
	return edbi:query_rows("""
			SELECT w.name, w.created_at, u.user
			FROM wiki_page AS w
			INNER JOIN users AS u ON (w.created_by_id=u.id)
			WHERE w.rev = 0 AND MATCH(w.wiki_text) AGAINST(%s IN BOOLEAN MODE)
			ORDER BY w.name
		""", { "+" & category })
end function

--**
-- Get the history for a page

public function get_history(sequence page)
	return edbi:query_rows(BASE_QUERY &
		" WHERE w.name = %s ORDER BY IF(w.rev=0,9999999,w.rev) DESC", { page })
end function
