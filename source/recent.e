--****
-- == Recent module
--

-- StdLib includes
include std/datetime.e
include std/error.e
include std/map.e
include std/search.e
include std/sort.e
include std/sequence.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include ticket_db.e as ticket_db
include news_db.e as news_db
include wiki_db.e as wiki_db

include config.e
include fuzzydate.e

include templates/recent.etml as t_recent

public enum R_TYPE, R_ID, R_AGE, R_AUTHOR, R_TITLE, R_URL, R_ICON, R_ADDITIONAL

constant q_forum = """
	SELECT 'forum', id, created_at, author_name, subject, '', 0, '' FROM messages"""

constant q_tickets = """
		SELECT 'ticket', t.id, t.created_at, u.user, t.subject, '', 0, ''
			FROM ticket AS t, users AS u
			WHERE t.submitted_by_id=u.id
	UNION ALL
		SELECT 'ticket comment', t.id, c.created_at, u.user, t.subject, '', c.id, '' FROM
			comment AS c, ticket AS t, users AS u WHERE c.module_id=1 AND
			c.item_id=t.id AND u.id=c.user_id"""

constant q_news = """
		SELECT 'news', n.id, n.publish_at, u.user, n.subject, '', 0, ''
			FROM news AS n, users AS u
			WHERE n.submitted_by_id=u.id
	UNION ALL
		SELECT 'news comment', n.id, c.created_at, u.user, n.subject, '', c.id, '' FROM
			comment AS c, news AS n, users AS u WHERE c.module_id=2 AND
			c.item_id=n.id AND u.id=c.user_id"""

constant q_wiki = """
	SELECT 'wiki', w.name, w.created_at, u.user, w.name, '', 0, w.change_msg FROM
		wiki_page AS w, users AS u WHERE w.created_by_id=u.id"""

sequence recent_vars = {
	{ wc:INTEGER, "page",      1 },
	{ wc:INTEGER, "per_page", 20 },
	{ wc:INTEGER, "forum",     0 },
	{ wc:INTEGER, "ticket",    0 },
	{ wc:INTEGER, "news",      0 },
	{ wc:INTEGER, "wiki",      0 }
}

function recent(map data, map request)
	integer page     = map:get(request, "page")
	integer per_page = map:get(request, "per_page")
	integer forum    = map:get(request, "forum")
	integer ticket   = map:get(request, "ticket")
	integer news     = map:get(request, "news")
	integer wiki     = map:get(request, "wiki")

	if (forum + ticket + news + wiki = 0) then
		forum = 1
		ticket = 1
		news = 1
		wiki = 1
	end if

	integer total_count = 0
	sequence queries = {}

	if forum then
		queries = append(queries, q_forum)
		total_count += edbi:query_object("SELECT COUNT(id) FROM messages")
	end if

	if ticket then
		queries = append(queries, q_tickets)
		total_count += edbi:query_object("SELECT COUNT(id) FROM ticket")
		total_count += edbi:query_object("SELECT COUNT(id) FROM comment WHERE module_id=%d", {
			ticket_db:MODULE_ID })
	end if

	if news then
		queries = append(queries, q_news)
		total_count += edbi:query_object("SELECT COUNT(id) FROM news")
		total_count += edbi:query_object("SELECT COUNT(id) FROM comment WHERE module_id=%d", {
			news_db:MODULE_ID })
	end if

	if wiki then
		queries = append(queries, q_wiki)
		total_count += edbi:query_object("SELECT COUNT(name) FROM wiki_page")
	end if

	map:copy(request, data)

	sequence sql = join(queries, " UNION ALL ") &
		" ORDER BY created_at DESC LIMIT %d OFFSET %d"

	object items = edbi:query_rows(sql, { per_page, (page - 1) * per_page })

	for i = 1 to length(items) do
		items[i][R_AGE] = fuzzy_ago(items[i][R_AGE])
		switch items[i][R_TYPE] do
			case "ticket comment" then
				items[i][R_URL] = sprintf("/ticket/%d.wc#%d", { items[i][2], items[i][7] })
				items[i][R_ICON] = "bug_error.png"

			case "news comment" then
				items[i][R_URL] = sprintf("/news/%d.wc#%d", { items[i][2], items[i][7] })
				items[i][R_ICON] = "date_error.png"

			case "forum" then
				if sequence(current_user) and current_user[USER_FORUM_DEFAULT_VIEW] = 2 then
					items[i][R_URL] = sprintf("/forum/m/%d.wc", { items[i][2] })
				else
					items[i][R_URL] = sprintf("/forum/%d.wc#%d", { items[i][2], items[i][2] })
				end if
				items[i][R_ICON] = "email.png"

			case "ticket" then
				items[i][R_URL] = sprintf("/%s/%d.wc#%d", { items[i][1], items[i][2], items[i][2] })
				items[i][R_ICON] = "bug.png"

			case "news" then
				items[i][R_URL] = sprintf("/%s/%d.wc#%d", { items[i][1], items[i][2], items[i][2] })
				items[i][R_ICON] = "date.png"

			case "wiki" then
				items[i][R_URL] = sprintf("/wiki/view/%s.wc", { items[i][2] })
				items[i][R_ICON] = "world.png"

			case else
				items[i][R_URL] = sprintf("/%s/%d.wc#%d", { items[i][1], items[i][2], items[i][2] })
				items[i][R_ICON] = ""
		end switch
	end for

	map:put(data, "items", items)
	map:put(data, "total_items", total_count)

	return { TEXT, t_recent:template(data) }
end function
wc:add_handler(routine_id("recent"), -1, "recent", "index", recent_vars)
