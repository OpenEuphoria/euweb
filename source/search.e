-- StdLib includes
include std/map.e

include edbi/edbi.e

-- Webclay includes
include webclay/webclay.e as wc

-- Local includes
include templates/search/result.etml as t_result

include fuzzydate.e

sequence result_vars = {
	{ wc:INTEGER, "page", 1 },
	{ wc:INTEGER, "per_page", 20 },
	{ wc:SEQUENCE, "s" }
}

public enum S_TYPE, S_ID, S_DATE, S_SUBJECT, S_SCORE

function result(map:map data, map:map request)
	sequence search_term = map:get(request, "s")
	integer page_no, per_page
	
	page_no = map:get(request, "page")
	per_page = map:get(request, "per_page")

	object rows = edbi:query_rows("""
			SELECT 'forum', id, created_at, subject, MATCH(subject,body) AGAINST(%s IN BOOLEAN MODE) AS score 
				FROM messages WHERE MATCH(subject, body) AGAINST(%s IN BOOLEAN MODE) 
		UNION ALL 
			SELECT 'news', id, publish_at, subject, MATCH(subject,content) AGAINST(%s IN BOOLEAN MODE) AS score 
				FROM news WHERE MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE) 
		UNION ALL 
			SELECT 'ticket', id, created_at, subject, MATCH(subject,content) AGAINST(%s IN BOOLEAN MODE) AS score 
				FROM ticket WHERE MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE) 
		ORDER BY score DESC LIMIT %d OFFSET %d""", {
 			search_term, search_term, search_term, search_term, search_term, search_term,
			per_page, (page_no-1) * per_page })
	
	for i = 1 to length(rows) do
		rows[i][S_DATE] = fuzzy_ago(rows[i][S_DATE])
	end for

	map:put(data, "items", rows)
	map:put(data, "search_term", search_term)
	map:put(data, "page", page_no)
	map:put(data, "per_page", per_page)

	return { TEXT, t_result:template(data) }
end function
wc:add_handler(routine_id("result"), -1, "search", "results", result_vars)
