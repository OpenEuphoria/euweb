--
-- Download Module
-- 

-- StdLib includes
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc

-- Local includes
include templates/downloads.etml as t_downloads

function index(map:map data, map:map vars)
	return { TEXT, t_downloads:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "downloads")
