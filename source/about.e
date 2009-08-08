-- StdLib includes
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc

-- Local includes
include templates/about_website.etml as t_about_website

function about_website(map:map data, map:map vars)
	return { TEXT, t_about_website:template(data) }
end function
wc:add_handler(routine_id("about_website"), -1, "about")
