--****
-- == Database setup/connection
-- 

namespace db

include std/datetime.e as dt
include std/error.e
include std/get.e

public include edbi/edbi.e

include config.e

public db_handle db = 0

edbi:set_driver_path(DB_DRIVERS_PATH)

public procedure open()
	db = edbi:open(DB_URL)
end procedure

public procedure close()
    if not db = 0 then
		edbi:close(db)
    end if
end procedure

--
-- Return a count of records of the supplied database
-- 

public function record_count(sequence table)
	return edbi:query_object("SELECT COUNT(*) FROM " & table)
end function

