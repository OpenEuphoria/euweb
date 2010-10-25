-- StdLib includes
include std/map.e
include std/sequence.e 

include edbi/edbi.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/logging.e as log
include webclay/escape.e as esc

-- Local includes
include templates/search/result.etml as t_result

include fuzzydate.e

sequence result_vars = {
	{ wc:INTEGER, "page", 1 },
	{ wc:INTEGER, "per_page", 20 },
	{ wc:SEQUENCE, "s" },
	{ wc:INTEGER, "ticket", 0 },
	{ wc:INTEGER, "news", 0 },
	{ wc:INTEGER, "forum", 0 }
}

public enum S_TYPE, S_ID, S_DATE, S_SUBJECT

constant 
	q_forum = `SELECT 'forum', id, created_at, subject FROM messages 
		WHERE MATCH(subject, body) AGAINST(%s IN BOOLEAN MODE)`,
	q_news = `SELECT 'news', id, publish_at AS created_at, subject FROM news 
		WHERE MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE)`,
	q_ticket = `SELECT 'ticket', id, created_at, subject FROM ticket 
		WHERE MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE)`

function result(map:map data, map:map request)
	sequence search_term = map:get(request, "s")
	integer 	
		page_no = map:get(request, "page"),
		per_page = map:get(request, "per_page"),
		s_news = map:get(request, "news"),
		s_ticket = map:get(request, "ticket"),
		s_forum = map:get(request, "forum")
	
	sequence params = {}
	sequence queries = {}
	
	if (s_news + s_ticket + s_forum) = 0 then
		s_news = 1
		s_ticket = 1
		s_forum = 1
	end if
	
	if s_news then
		params = append(params, search_term)
		queries = append(queries, q_news)
	end if
	
	if s_ticket then
		params = append(params, search_term)
		queries = append(queries, q_ticket)
	end if
	
	if s_forum then
		params = append(params, search_term)
		queries = append(queries, q_forum)
	end if

	sequence sql = join(queries, " UNION ALL ") & 
		" ORDER BY created_at DESC LIMIT %d OFFSET %d"
	params = append(params, per_page)
	params = append(params, (page_no - 1) * per_page)
	
	object rows = edbi:query_rows(sql, params)
	
	for i = 1 to length(rows) do
		rows[i][S_DATE] = fuzzy_ago(rows[i][S_DATE])
	end for

	map:put(data, "items", rows)
	map:put(data, "s", htmlspecialchars(search_term))
	map:put(data, "search_term", htmlspecialchars(search_term))
	map:put(data, "page", page_no)
	map:put(data, "per_page", per_page)
	map:put(data, "s_news", s_news)
	map:put(data, "s_ticket", s_ticket)
	map:put(data, "s_forum", s_forum)
	map:put(data, "is_search", 1)

	return { TEXT, t_result:template(data) }
end function
wc:add_handler(routine_id("result"), -1, "search", "results", result_vars)
