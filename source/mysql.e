include std/datetime.e as dt
include std/dll.e
include std/error.e
include std/machine.e
include std/search.e

public sequence last_statements = {}
export atom last_stmts_limit = 10

-- Helper Functions

function sprintf_sql(sequence sql, object values)
    sequence ns
    integer in_fmt, idx, ch

    if atom(values) or length(values) = 0 then
        return sql
    end if

    ns = ""
    in_fmt = 0
    idx = 1

    for i = 1 to length(sql) do
        ch = sql[i]

        if ch = '%' and in_fmt = 0 then
            in_fmt = 1
        elsif in_fmt = 1 then
            in_fmt = 0
			
			switch ch do
	            case '%' then
	                ns &= '%'
	            case 'b' then -- boolean
	                if values[idx] then
	                    ns &= "true"
	                else
	                    ns &= "false"
	                end if
	            case 'S' then -- unescaped string
	                ns &= sprintf("'%s'", {values[idx]})
	                idx += 1
	            case 's' then -- escaped string
					-- TODO: Use MySQL's escape string function
	                ns &= sprintf("'%s'", { find_replace("\\", 
						find_replace("'", values[idx], "''", 0), "\\\\")})
	                idx += 1
	            case 'd' then  -- integer
	                ns &= sprintf("%d", {values[idx]})
	                idx += 1
	            case 'D' then -- date
	                -- TODO
	                ns &= dt:format(values[idx], "'%Y-%m-%d'")
	                idx += 1
	            case 'T' then -- datetime
	                ns &= dt:format(values[idx], "'%Y-%m-%d %H:%M:%S'")
	                idx += 1
	            case 't' then -- time
	                ns &= dt:format(values[idx], "'%H:%M:%S'")
	                idx += 1
	            case 'f' then -- float
	                ns &= sprintf("%f", {values[idx]})
	                idx += 1
				case else
					crash("Unknown format character: %s (parameter #%d) in SQL %s", 
						{ ch, idx, sql })
            end switch
        else
            ns &= ch
        end if
    end for

    return ns
end function

constant lib_mysql = open_dll({ "libmysqlclient.so", "libmysqlclient.dylib", 
	"libmysql.dll" })

if lib_mysql = -1 then
	crash("Could not find a suitable MySQL shared library")
end if

constant 
	h_mysql_init = define_c_func(lib_mysql, "mysql_init", {C_POINTER}, C_POINTER),
	h_mysql_real_connect = define_c_func(lib_mysql, "mysql_real_connect", {
		C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_UINT, C_POINTER,
		C_ULONG}, C_POINTER),
	h_mysql_close = define_c_proc(lib_mysql, "mysql_close", {C_POINTER}),
	h_mysql_error = define_c_func(lib_mysql, "mysql_error", {C_POINTER}, C_POINTER),
	h_mysql_real_query = define_c_func(lib_mysql, "mysql_real_query", {C_POINTER, C_POINTER,
		C_ULONG}, C_INT),
	h_mysql_field_count = define_c_func(lib_mysql, "mysql_field_count", {C_POINTER}, C_UINT),
	h_mysql_use_result = define_c_func(lib_mysql, "mysql_use_result", {C_POINTER}, C_POINTER),
	h_mysql_free_result = define_c_proc(lib_mysql, "mysql_free_result", {C_POINTER}),
	h_mysql_fetch_row = define_c_func(lib_mysql, "mysql_fetch_row", {C_POINTER}, C_POINTER),
	h_mysql_num_fields = define_c_func(lib_mysql, "mysql_num_fields", {C_POINTER}, C_UINT),
	h_mysql_fetch_lengths = define_c_func(lib_mysql, "mysql_fetch_lengths", {C_POINTER}, C_POINTER),
	h_mysql_insert_id = define_c_func(lib_mysql, "mysql_insert_id", {C_POINTER}, C_ULONG)

--**
-- Initalize a MySQL handle

export function mysql_init(atom dbh=0)
	return c_func(h_mysql_init, {dbh})
end function

--**
-- Connect to a MySQL database

export function mysql_real_connect(atom dbh, object host=0, object user=0, 
		object passwd=0, object db=0, integer port=3306, object unix_socket=0,
		integer client_flag=0)
	atom p_mysql

	if sequence(host) then
		host = allocate_string(host)
	end if

	if sequence(user) then
		user = allocate_string(user)
	end if

	if sequence(passwd) then
		passwd = allocate_string(passwd)
	end if

	if sequence(db) then
		db = allocate_string(db)
	end if

	if sequence(unix_socket) then
		unix_socket = allocate_string(unix_socket)
	end if
	
	p_mysql = c_func(h_mysql_real_connect, {dbh, host, user, passwd, db, port, 
		unix_socket, client_flag})
	
	if host then
		free(host)
	end if

	if user then
		free(user)
	end if

	if passwd then
		free(passwd)
	end if

	if db then
		free(db)
	end if

	if unix_socket then
		free(unix_socket)
	end if

	return p_mysql
end function

--**
-- Close a MySQL connection

export procedure mysql_close(atom dbh)
	c_proc(h_mysql_close, {dbh})
end procedure

--**
-- Retrieve an error message

public function mysql_error(atom dbh)
	sequence message=""
	atom p_error = c_func(h_mysql_error, {dbh})

	if p_error != NULL then
		-- Memory is free'd by MySQL when connection is closed
		message = peek_string(p_error)
	end if

	return message
end function

--**
-- Get the last inserted id

public function mysql_insert_id(atom dbh)
	return c_func(h_mysql_insert_id, {dbh})
end function

--**
-- Return the field count for the most recently used query

public function mysql_field_count(atom dbh)
	return c_func(h_mysql_field_count, {dbh})
end function

--**
-- Use a MySQL result

public function mysql_use_result(atom dbh)
	return c_func(h_mysql_use_result, {dbh})
end function

--**
-- Free a MySQL result

public procedure mysql_free_result(atom dbr)
	c_proc(h_mysql_free_result, {dbr})
end procedure

--**
-- Return the number of fields in a MySQL result

public function mysql_num_fields(atom dbr)
	return c_func(h_mysql_num_fields, {dbr})
end function

--**
-- Return the lengths of the fields fetched

export function mysql_fetch_lengths(atom dbr)
	return c_func(h_mysql_fetch_lengths, {dbr})
end function

--**
-- Fetch the next row in a MySQL result
-- 
-- Return:
--   A ##sequence## of field values.

public function mysql_fetch_row(atom dbr)
	atom p_lengths, p_row = c_func(h_mysql_fetch_row, {dbr})
	integer field_count
	object data = {}, tmp

	if p_row = 0 then
		return 0
	end if

	p_lengths = mysql_fetch_lengths(dbr)
	field_count = mysql_num_fields(dbr)

	for i = 0 to (field_count - 1) * 4 by 4 do
		data &= {peek({peek4u(p_row + i), peek4u(p_lengths + i)})}
	end for

	return data
end function

--**
-- Query the database

public function mysql_query(atom dbh, sequence sql, object data={})
	integer result
	atom p_sql

	sql = sprintf_sql(sql, data)
	
	if length(last_statements) > last_stmts_limit then
		last_statements = last_statements[2..$]
	end if
	last_statements &= {sql}

	p_sql = allocate_string(sql)
	result = c_func(h_mysql_real_query, {dbh, p_sql, length(sql)})
	free(p_sql)

	return result
end function

public function mysql_query_one(atom dbh, sequence sql, object data={})
	atom res

	if mysql_query(dbh, sql, data) then
		return 0
	end if

	res = mysql_use_result(dbh)
	data = mysql_fetch_row(res)

	if atom(data) then
		return 0
	end if

	mysql_free_result(res)

	return data
end function

public function mysql_query_object(atom dbh, sequence sql, object data={})
	object result = mysql_query_one(dbh, sql, data)
	if sequence(result) then
		return result[1]
	end if
	return 0
end function

public function mysql_query_rows(atom dbh, sequence sql, object data={})
	if mysql_query(dbh, sql, data) then
		return 0
	end if
	
	object row, result = {}
	object stmt = mysql_use_result(dbh)
	while sequence(row) with entry do
		result = append(result, row)
	entry
		row = mysql_fetch_row(stmt)
	end while
    mysql_free_result(stmt)

	return result
end function
