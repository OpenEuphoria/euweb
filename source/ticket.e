--****
-- Ticket System

include std/error.e
include std/get.e
include std/map.e
include std/search.e

include webclay/webclay.e as wc
include webclay/logging.e as log

include edbi/edbi.e

include templates/security.etml as t_security
include templates/ticket/index.etml as t_index

include config.e
include db.e
--include ticket_db.e
include fuzzydate.e

sequence index_vars = {
	{ wc:INTEGER, "page",       1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map request)
	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "ticket", "index", index_vars)

