--****
-- == Recent module
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
include fuzzydate.e

include templates/recent.etml as t_recent

public enum TYPE, ID, AGE, AUTHOR, SUBJECT, URL, ICON

sequence recent_vars = {
	{ wc:INTEGER, "page", 1 },
	{ wc:INTEGER, "per_page", 20 }
}

function recent(map data, map request)
	map:copy(request, data)

	sequence sql = """
			SELECT 'forum', id, created_at, author_name, subject, '', 0 FROM messages
		UNION ALL
			SELECT 'ticket', t.id, t.created_at, u.user, t.subject, '', 0
				FROM ticket AS t, users AS u
				WHERE t.submitted_by_id=u.id
		UNION ALL
			SELECT 'ticket comment', t.id, c.created_at, u.user, t.subject, '', c.id FROM
				comment AS c, ticket AS t, users AS u WHERE c.module_id=1 AND
				c.item_id=t.id AND u.id=c.user_id
		UNION ALL
			SELECT 'news', n.id, n.publish_at, u.user, n.subject, '', 0
				FROM news AS n, users AS u
				WHERE n.submitted_by_id=u.id
		UNION ALL
			SELECT 'news comment', n.id, c.created_at, u.user, n.subject, '', c.id FROM
				comment AS c, news AS n, users AS u WHERE c.module_id=2 AND
				c.item_id=n.id AND u.id=c.user_id
		ORDER BY created_at DESC LIMIT %d OFFSET %d
		"""

	integer page = map:get(request, "page")
	integer per_page = map:get(request, "per_page")

	integer total_count = edbi:query_object("SELECT COUNT(id) FROM ticket")
	total_count += edbi:query_object("SELECT COUNT(id) FROM comment")
	total_count += edbi:query_object("SELECT COUNT(id) FROM messages")
	total_count += edbi:query_object("SELECT COUNT(id) FROM news")

	object items = edbi:query_rows(sql, { per_page, (page - 1) * per_page })

	for i = 1 to length(items) do
		items[i][AGE] = fuzzy_ago(items[i][AGE])
		switch items[i][TYPE] do
			case "ticket comment" then
				items[i][URL] = sprintf("/ticket/%d.wc#%d", { items[i][2], items[i][7] })
				items[i][ICON] = "bug_error.png"

			case "news comment" then
				items[i][URL] = sprintf("/news/%d.wc#%d", { items[i][2], items[i][7] })
				items[i][ICON] = "date_error.png"

			case "forum" then
				if sequence(current_user) and current_user[USER_FORUM_DEFAULT_VIEW] = 2 then
					items[i][URL] = sprintf("/forum/m/%d.wc", { items[i][2] })
				else
					items[i][URL] = sprintf("/forum/%d.wc#%d", { items[i][2], items[i][2] })
				end if
				items[i][ICON] = "email.png"

			case "ticket" then
				items[i][URL] = sprintf("/%s/%d.wc#%d", { items[i][1], items[i][2], items[i][2] })
				items[i][ICON] = "bug.png"

			case "news" then
				items[i][URL] = sprintf("/%s/%d.wc#%d", { items[i][1], items[i][2], items[i][2] })
				items[i][ICON] = "date.png"

			case else
				items[i][URL] = sprintf("/%s/%d.wc#%d", { items[i][1], items[i][2], items[i][2] })
				items[i][ICON] = ""
		end switch
	end for

	map:put(data, "items", items)
	map:put(data, "total_items", total_count)

	return { TEXT, t_recent:template(data) }
end function
wc:add_handler(routine_id("recent"), -1, "recent", "index", recent_vars)
