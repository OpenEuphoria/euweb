--****
-- == Database setup/connection
-- 

namespace db

include std/datetime.e as dt
include std/error.e
include std/get.e

include config.e
public include mysql.e

public atom db = 0

public procedure open()
    db = mysql_init()
    if not mysql_real_connect(db, DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT) 
    then
        crash("Couldn't connect to the database. See config.e for parameters.")
    end if
end procedure

public procedure close()
    if not db = 0 then
        mysql_close(db)
    end if
end procedure

--
-- Convert a date to a  SQL date and time
--

public function dateTimeToSQL(dt:datetime d)
    return dt:format(d, "%Y-%m-%d %H:%M:%S")
end function

public function sqlDateTimeToDateTime(sequence sD)
    if length(sD) = 0 then
        return dt:new()
    end if

    return dt:new(
        defaulted_value(sD[1..4], 0),
        defaulted_value(sD[6..7], 0),
        defaulted_value(sD[9..10], 0),
        defaulted_value(sD[12..13], 0),
        defaulted_value(sD[15..16], 0),
        defaulted_value(sD[18..19], 0))
end function
