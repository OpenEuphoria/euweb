--****
-- == Preview Module
-- 
-- This allows AJAX calls to preview CREOLE formatted fields
-- 

-- StdLib includes
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc

include format.e

function preview(map:map data, map:map request)
	sequence content = map:get(request, "content")

	return { TEXT, format_body(content, 0) }
end function
wc:add_handler(routine_id("preview"), -1, "ajax", "creole_preview")
