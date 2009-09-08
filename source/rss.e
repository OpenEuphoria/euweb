--****
-- == RSS module
--

-- StdLib includes
include std/datetime.e
include std/error.e
include std/map.e
include std/search.e
include std/sort.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include config.e
include format.e
include ticket_db.e

include templates/rss.etml as t_rss

public enum DATE, AUTHOR, URL, TITLE, CONTENT

function rss_date(datetime d)
	return datetime:format(d, "%a, %d %b %Y %H:%M:%S GMT")
end function

function latest_tickets()
	object rows = edbi:query_rows("""SELECT t.id, t.created_at, u.user, t.subject, t.content 
		FROM ticket AS t, users AS u WHERE t.submitted_by_id=u.id 
		ORDER BY t.created_at DESC LIMIT 10""")
	
	for i = 1 to length(rows) do
		rows[i] = {
			rows[i][2],
			rows[i][3],
			sprintf("/ticket/%d.wc", { rows[i][1] }),
			"Ticket: " & rows[i][4],
			format_body(rows[i][5], 0)
		}
	end for
	
	return rows
end function

function latest_ticket_comments()
	object rows = edbi:query_rows("""SELECT c.id, c.created_at, u.user, t.subject, c.body,
		t.id FROM comment AS c, ticket AS t, users AS u WHERE c.user_id=u.id AND c.module_id=%d
		AND c.item_id=t.id ORDER BY c.created_at DESC LIMIT 10""", { ticket_db:MODULE_ID })
	
	for i = 1 to length(rows) do
		rows[i] = {
			rows[i][2],
			rows[i][3],
			sprintf("/ticket/%d.wc#%d", { rows[i][6], rows[i][1] }),
			"Ticket comment: " & rows[i][4],
			format_body(rows[i][5], 0)
		}
	end for

	return rows
end function

function latest_news()
	object rows = edbi:query_rows("""SELECT n.id, n.publish_at, u.user, n.subject, n.content
		FROM news AS n, users AS u WHERE n.submitted_by_id=u.id AND n.publish_at < NOW()
		ORDER BY n.publish_at DESC LIMIT 10""")
	
	for i = 1 to length(rows) do
		rows[i] = {
			rows[i][2],
			rows[i][3],
			sprintf("/news/%d.wc", { rows[i][1] }),
			"News: " & rows[i][4],
			format_body(rows[i][5], 0)
		}
	end for

	return rows
end function
	
function latest_forum_posts()
	object rows = edbi:query_rows("""SELECT m.topic_id, m.id, m.created_at, m.author_name, 
		m.subject, m.body FROM messages AS m ORDER BY created_at DESC LIMIT 10""")
	
	for i = 1 to length(rows) do
		rows[i] = {
			rows[i][3],
			rows[i][4],
			sprintf("/forum/%d.wc#%d", { rows[i][2], rows[i][1] }),
			"Forum: " & rows[i][5],
			format_body(rows[i][6])
		}
	end for

	return rows
end function

function rss(map data, map request)
	map:put(data, "ROOT_URL", ROOT_URL)

	object rows = latest_tickets()
 	rows &= latest_ticket_comments()
	rows &= latest_news()
	rows &= latest_forum_posts()

	-- enum DATE, AUTHOR, VIEW_URL, SUBJECT, CONTENT

	-- Sort based on date, then take the first 10 items
	rows = sort_columns(rows, { -DATE })
	if length(rows) > 20 then 
		rows = rows[1..20]
	end if
	
	for i = 1 to length(rows) do
		rows[i][DATE] = rss_date(rows[i][DATE])
	end for

	map:put(data, "items", rows)
 
	return { TEXT, t_rss:template(data) }
end function
wc:add_handler(routine_id("rss"), -1, "rss")