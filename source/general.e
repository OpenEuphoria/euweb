--****
-- == General handlers
--

include std/map.e as map

include webclay/webclay.e as wc

include templates/general/donate.etml as t_donate

function donate(map data, map request)
	return { TEXT, t_donate:template(data) }
end function
wc:add_handler(routine_id("donate"), -1, "general", "donate", {})
