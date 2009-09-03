--****
-- == News module
-- 

include std/map.e
include std/search.e

include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include templates/security.etml as t_security
include templates/news/index.etml as t_index
include templates/news/edit.etml as t_edit
include templates/news/edit_ok.etml as t_edit_ok

include news_db.e
include format.e
include fuzzydate.e

sequence index_invars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map invars)
	map:put(data, "page", map:get(invars, "page"))
	map:put(data, "per_page", map:get(invars, "per_page"))
	map:put(data, "article_count", news_db:article_count())

	object arts = news_db:get_article_list(map:get(invars, "page"), map:get(invars, "per_page"))
	for i = 1 to length(arts) do
		arts[i][news_db:CONTENT] = format_body(arts[i][news_db:CONTENT])
		arts[i][news_db:PUBLISH_AT] = fuzzy_ago(arts[i][news_db:PUBLISH_AT])
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
		map:put(data, "content", find_replace("\r\n", map:get(data, "content"), "\n"))
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

	if map:get(request, "id") = -1 then
		news_db:insert(map:get(request, "subject"), map:get(request, "content"))
	else
		news_db:save(map:get(request, "id"), map:get(request, "subject"), map:get(request, "content"))
	end if

	map:copy(request, data)

	return { TEXT, t_edit_ok:template(data) }	
end function
wc:add_handler(routine_id("save"), routine_id("validate_save"), "news", "save", save_in)

