--****
-- == Category Module
--

include std/map.e as map
include std/sequence.e as seq
include std/text.e as txt

include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e as edbi

include category_db.e as category_db
include page_grouper.e

include templates/category/cloud.etml as t_cloud
include templates/category/member_list.etml as t_member_list

--**
-- Display a category cloud.
-- 
-- Parameters:
--    * ##data##    - webclay template data
--    * ##request## - HTTP request data
--
-- Request Parameters:
--    * ##sort## - 1 = alpha, 2 = popularity, 3 = popularity centered
--
-- Returns:
--   { TEXT, HTML_DATA }   
--

sequence cloud_vars = {
	{ wc:INTEGER, "sort",  3 }
}

function cloud(map data, map request)
	sequence order_by, sort_name
	integer sort_flag = map:get(request, "sort")

	map:put(data, "sort", sort_flag)

	switch sort_flag do
		case 1 then
			order_by = "name"
			sort_name = "Categories by Alphabetical Order"

		case 2 then
			order_by = "children DESC"
			sort_name = "Categories by Popularity Order"

		case else
			order_by = "children DESC"
			sort_name = "Categories by Popularity Centered Order"
	end switch

	map:put(data, "title", sort_name)

	object categories = edbi:query_rows("SELECT name, children, 0 as font_size FROM category ORDER BY %v", {
		order_by })
	atom size_min = 0.6, size_max = 4.0
	integer max_children = 0

	for i = 1 to length(categories) do
		if categories[i][2] > max_children then
			max_children = categories[i][2]
		end if
	end for

	atom interval = (size_max - size_min) / max_children

	for i = 1 to length(categories) do
		categories[i][3] = size_min + (interval * categories[i][2])
		if categories[i][3] = 0 then
			categories[i][3] = size_min
		end if
	end for

	if sort_flag = 3 then
		integer side = 0
		sequence left = {}
		sequence right = {}

		for i = 1 to length(categories) do
			if side then
				right = append(right, categories[i])
			else
				left = append(left, categories[i])
			end if
			side = not side
		end for

		categories = reverse(right) & left
	end if

	map:put(data, "categories", categories)

	return { TEXT, t_cloud:template(data) }
end function
wc:add_handler(routine_id("cloud"), -1, "category", "cloud", cloud_vars)

sequence member_list_vars = {
	{ wc:SEQUENCE, "category" }
}

function member_list(map data, map request)
	sequence cat_name = map:get(request, "category")

	map:put(data, "category", cat_name)

	object members = -1
	if not has_role("user") then
		members = category_db:member_list_anon(cat_name)
	else
		members = category_db:member_list(cat_name)
	end if
	if sequence(members) then
		sequence page_groups = assemble_page_list(members)

		map:put(data, "num_of_members", length(members))
		map:put(data, "groups", page_groups)
	else
		map:put(data, "num_of_members", 0)
		map:put(data, "groups", {})
	end if

	return { TEXT, t_member_list:template(data) }
end function
wc:add_handler(routine_id("member_list"), -1, "category", "members", member_list_vars)

--**
-- Rename a category
-- 
-- Parameters:
--    * ##data##    - webclay template data
--    * ##request## - HTTP request data
--
-- Returns:
--   { TEXT, HTML_TEXT }
--
-- See Also:
--   [[:remove]]
--

function rename(map data, map request)
	return { TEXT, "Not Implemented" }
end function

--**
-- Categorize a given item
--
-- Request Parameters:
--   * ##module_id## - id of module the item belongs to
--   * ##item_id##   - unique identifier for the item
--   * ##cat_name##  - name of category to add
--

sequence categorize_vars = {
	{ wc:INTEGER,  "module_id", 0 },
	{ wc:SEQUENCE, "item_id"      },
	{ wc:SEQUENCE, "cat_name"     },
	{ wc:SEQUENCE, "url"          },
	{ wc:INTEGER,  "operation", 1 }
}

function validate_categorize(map data, map request)
	sequence errors = wc:new_errors("wiki", "categorize")

	if not has_role("user") then
		errors = wc:add_error(errors, "form", "You are not authorized to edit wiki pages")
	end if

	return errors
end function


function categorize(map data, map request)
	integer  module_id = map:get(request, "module_id")
	sequence item_id   = map:get(request, "item_id")
	sequence cat_name  = map:get(request, "cat_name")
	sequence url       = map:get(request, "url")
	integer  operation = map:get(request, "operation")

	sequence cats = split_any(cat_name, ",: ", 0, 1)
	for i = 1 to length(cats) do
		if operation = 1 then
			category_db:categorize(trim(cats[i]), module_id, item_id)
		else
			category_db:uncategorize(trim(cats[i]), module_id, item_id)
		end if
	end for

	return { REDIRECT_303, url & "#category_" & item_id }
end function
wc:add_handler(routine_id("categorize"), routine_id("validate_categorize"), "category", "categorize", categorize_vars)

function autocomplete(map data, map request)
	sequence result = ""

	object vals = edbi:query_rows("SELECT name FROM category WHERE name LIKE %s ORDER BY name", {
		"%" & map:get(request, "value") & "%" })

	result &= "<ul>\n"
	for i = 1 to length(vals) do
		result &= sprintf("<li>%s</li>\n", { vals[i][1] })
	end for
	result &= "</ul>"

	return { TEXT, result }
end function
wc:add_handler(routine_id("autocomplete"), -1, "category", "autocomplete", {})

