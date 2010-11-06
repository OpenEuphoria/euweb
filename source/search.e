-- StdLib includes
include std/map.e
include std/sequence.e

include edbi/edbi.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/logging.e as log
include webclay/escape.e  as esc

-- Local includes
include templates/search/result.etml as t_result

include fuzzydate.e
include item_icons.e

sequence result_vars = {
	{ wc:INTEGER,  "page",      1 },
	{ wc:INTEGER,  "per_page", 20 },
	{ wc:INTEGER,  "ticket",    0 },
	{ wc:INTEGER,  "news",      0 },
	{ wc:INTEGER,  "forum",     0 },
	{ wc:INTEGER,  "wiki",      0 },
	{ wc:INTEGER,  "manual",    0 },
	{ wc:SEQUENCE, "s" }
}

public enum S_TYPE, S_ID, S_DATE, S_SUBJECT, S_ICON, S_URL, S_SCORE

constant q_forum = `SELECT 'forum', id, created_at, subject, '',
CONCAT('/forum/m/', id, '.wc'),
MATCH(subject, body) AGAINST(%s IN BOOLEAN MODE) as score
FROM messages
WHERE MATCH(subject, body) AGAINST(%s IN BOOLEAN MODE)`

constant q_news = `SELECT 'news', id, publish_at AS created_at, subject, '',
CONCAT('/news/', id, '.wc'),
MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE) as score
FROM news
WHERE MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE)`

constant q_ticket = `SELECT 'ticket', id, created_at, subject, '',
CONCAT('/ticket/', id, '.wc'),
MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE) as score
FROM ticket
WHERE MATCH(subject, content) AGAINST(%s IN BOOLEAN MODE)`

constant q_wiki = `SELECT 'wiki', name, created_at, name, '',
CONCAT('/wiki/view/', name, '.wc'),
MATCH(name, wiki_text) AGAINST(%s IN BOOLEAN MODE) as score
FROM wiki_page
WHERE rev=0 AND MATCH(name, wiki_text) AGAINST(%s IN BOOLEAN MODE)`

constant q_manual = `SELECT 'manual', name, created_at, name, '',
CONCAT('/docs/', filename, '#', a_name),
MATCH(content) AGAINST(%s IN BOOLEAN MODE) as score
FROM manual
WHERE MATCH(content) AGAINST(%s IN BOOLEAN MODE)`

function result(map:map data, map:map request)
	sequence search_term = map:get(request, "s")
	integer
		page_no  = map:get(request, "page"),
		per_page = map:get(request, "per_page"),
		s_news   = map:get(request, "news"),
		s_ticket = map:get(request, "ticket"),
		s_forum  = map:get(request, "forum"),
		s_wiki   = map:get(request, "wiki"),
		s_manual = map:get(request, "manual")

	sequence params  = {}
	sequence queries = {}

	if (s_news + s_ticket + s_forum + s_wiki + s_manual) = 0 then
		s_news   = 1
		s_ticket = 1
		s_forum  = 1
		s_wiki   = 1
		s_manual = 1
	end if

	if s_news then
		params  = append(params, search_term)
		params  = append(params, search_term)
		queries = append(queries, q_news)
	end if

	if s_ticket then
		params  = append(params, search_term)
		params  = append(params, search_term)
		queries = append(queries, q_ticket)
	end if

	if s_forum then
		params  = append(params, search_term)
		params  = append(params, search_term)
		queries = append(queries, q_forum)
	end if

	if s_wiki then
		params  = append(params, search_term)
		params  = append(params, search_term)
		queries = append(queries, q_wiki)
	end if

	if s_manual then
		sequence tmp_search_term = sprintf("%s >\"function %s\" >\"procedure %s\" >\"type %s\"", {
				search_term, search_term, search_term, search_term })

		params  = append(params, tmp_search_term)
		params  = append(params, tmp_search_term)
		queries = append(queries, q_manual)
	end if

	sequence sql = join(queries, " UNION ALL ") &
		" ORDER BY score DESC, created_at DESC LIMIT %d OFFSET %d"
	params = append(params, per_page)
	params = append(params, (page_no - 1) * per_page)

	object rows = edbi:query_rows(sql, params)

	for i = 1 to length(rows) do
		rows[i][S_DATE] = fuzzy_ago(rows[i][S_DATE])
		rows[i][S_ICON] = type_icon(rows[i][S_TYPE])
	end for

	map:put(data, "items",       rows)
	map:put(data, "s",           htmlspecialchars(search_term))
	map:put(data, "search_term", htmlspecialchars(search_term))
	map:put(data, "page",        page_no)
	map:put(data, "per_page",    per_page)
	map:put(data, "s_news",      s_news)
	map:put(data, "s_ticket",    s_ticket)
	map:put(data, "s_forum",     s_forum)
	map:put(data, "s_wiki",      s_wiki)
	map:put(data, "s_manual",    s_manual)
	map:put(data, "is_search",   1)

	return { TEXT, t_result:template(data) }
end function
wc:add_handler(routine_id("result"), -1, "search", "results", result_vars)
