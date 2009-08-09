-- StdLib includes
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc

-- Local includes
include templates/security.etml as t_security

function security_invalid(map:map data, map:map vars)
	return { TEXT, t_security:template(data) }
end function

wc:add_handler(routine_id("security_invalid"), -1, "security", "invalid")
