--****
-- == News module
-- 

include std/map.e
include std/search.e
include std/datetime.e as dt

include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include templates/security.etml as t_security
include templates/news/index.etml as t_index
include templates/news/edit.etml as t_edit
include templates/news/edit_ok.etml as t_edit_ok
include templates/news/view.etml as t_view

include comment_db.e
include news_db.e
include format.e
include fuzzydate.e
include wiki_db.e

sequence index_invars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map invars)
	map:put(data, "page", map:get(invars, "page"))
	map:put(data, "per_page", map:get(invars, "per_page"))
	map:put(data, "article_count", news_db:article_count())

	object news_wiki = wiki_db:get("NewsHome")
	map:put(data, "news_html", format_body(news_wiki[WIKI_TEXT]))

	object arts = news_db:get_article_list(map:get(invars, "page"), map:get(invars, "per_page"))
	for i = 1 to length(arts) do
		arts[i][news_db:CONTENT] = format_body(arts[i][news_db:CONTENT])
		--arts[i][news_db:PUBLISH_AT] = fuzzy_ago(arts[i][news_db:PUBLISH_AT])
		arts[i][news_db:PUBLISH_AT] = dt:format(arts[i][news_db:PUBLISH_AT], "%b %d, %Y")
		arts[i] &= edbi:query_object("SELECT COUNT(id) FROM comment WHERE module_id=%d AND item_id=%d", 
			{ news_db:MODULE_ID, arts[i][news_db:ID] })
	end for

	map:put(data, "articles", arts)

	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "news", "index", index_invars)
wc:add_handler(routine_id("index"), -1, "index", "index", index_invars)
wc:set_default_handler(routine_id("greet_form"))

sequence edit_in = {
	{ wc:INTEGER, "id", -1 }
}

function edit(map data, map request)
	map:put(data, "id", map:get(request, "id"))

	if map:get(data, "has_errors") then
		map:copy(request, data)
	elsif map:get(request, "id") > 0 then
		object n = news_db:get(map:get(request, "id"))

		map:put(data, "subject", n[news_db:SUBJECT])
		map:put(data, "content", n[news_db:CONTENT])
	end if
	
	if map:has(data, "content") then
		map:put(data, "content", match_replace("\r\n", map:get(data, "content"), "\n"))
	end if

	return { TEXT, t_edit:template(data) }
end function
wc:add_handler(routine_id("edit"), -1, "news", "edit", edit_in)
wc:add_handler(routine_id("edit"), -1, "news", "post", edit_in)

sequence save_in = {
	{ wc:INTEGER, "id", -1 },
	{ wc:SEQUENCE, "subject", "" },
	{ wc:SEQUENCE, "content", "" }
}

function validate_save(integer data, map vars)
	sequence errors = wc:new_errors("news", "edit")

	if length(map:get(vars, "subject")) = 0 then
		errors = wc:add_error(errors, "subject", "Subject cannot be empty.")
	end if

	if length(map:get(vars, "content")) = 0 then
		errors = wc:add_error(errors, "content", "Content cannot be empty.")
	end if

	return errors
end function

function save(map data, map request)
	if not has_role("news_admin") then
		return { TEXT, t_security:template(data) }
	end if

	integer id = map:get(request, "id")

	if id = -1 then
		id = news_db:insert(map:get(request, "subject"), 
			map:get(request, "content"))
	else
		news_db:save(id,
			map:get(request, "subject"), 
			map:get(request, "content"))
	end if

	map:copy(request, data)
	
	return { REDIRECT_303, sprintf("/news/%d.wc", { id }) }
end function
wc:add_handler(routine_id("save"), routine_id("validate_save"), "news", "save", save_in)

sequence view_vars = { 
	{ wc:INTEGER, "id", -1 },
	{ wc:SEQUENCE, "body", "" },
	{ wc:INTEGER, "remove_comment", -1 }
}

function view(map data, map request)
	object item = news_db:get(map:get(request, "id"))
	
	if has_role("user") and length(map:get(request, "body")) then
		comment_db:add_comment(
			news_db:MODULE_ID, 
			item[news_db:ID], 
			item[news_db:SUBJECT], 
			map:get(request, "body"))
	
		integer id = edbi:last_insert_id()
		return { REDIRECT_303, sprintf("/news/%d.wc#%d", { item[news_db:ID], id }) }
	end if
	
	if has_role("forum_moderator") and map:get(request, "remove_comment") > 0 then
		comment_db:remove_comment(map:get(request, "remove_comment"))
	
		return { REDIRECT_303, sprintf("/news/%d.wc", { item[news_db:ID] }) }
	end if
	
	map:put(data, "item", item)
	map:put(data, "id", item[news_db:ID])
	map:put(data, "subject", item[news_db:SUBJECT])
	map:put(data, "content", format_body(item[news_db:CONTENT], 0))
	map:put(data, "publish_at", fuzzy_ago(item[news_db:PUBLISH_AT]))
	map:put(data, "author_name", item[news_db:AUTHOR_NAME])
	map:put(data, "comment_count", 
		edbi:query_object("SELECT COUNT(id) FROM comment WHERE module_id=%d AND item_id=%d", 
			{ news_db:MODULE_ID, item[news_db:ID] }))
	map:put(data, "comments", comment_db:get_all(news_db:MODULE_ID, map:get(request, "id")))
	
	return { TEXT, t_view:template(data) }
end function
wc:add_handler(routine_id("view"), -1, "news", "view", view_vars)
