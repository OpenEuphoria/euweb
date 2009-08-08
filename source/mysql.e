include std/dll.e
include std/machine.e
include std/datetime.e as dt
include std/search.e

export sequence last_statements = {}
export atom last_stmts_limit = 10

-- Helper Functions

export function sprintf_sql(sequence sql, object values)
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

            if ch = '%' then
                ns &= '%'
            elsif ch = 'b' then -- boolean
                if values[idx] then
                    ns &= "true"
                else
                    ns &= "false"
                end if
            elsif ch = 'S' then -- unescaped string
                ns &= sprintf("'%s'", {values[idx]})
                idx += 1
            elsif ch = 's' then -- escaped string
				-- TODO: Use MySQL's escape string function
                ns &= sprintf("'%s'", {find_replace("\\", find_replace("'", values[idx], "''", 0), "\\\\")})
                idx += 1
            elsif ch = 'd' then  -- integer
                ns &= sprintf("%d", {values[idx]})
                idx += 1
            elsif ch = 'D' then -- date
                -- TODO
                ns &= dt:format(values[idx], "'%Y-%m-%d'")
                idx += 1
            elsif ch = 'T' then -- datetime
                ns &= dt:format(values[idx], "'%Y-%m-%d %H:%M:%S'")
                idx += 1
            elsif ch = 't' then -- time
                ns &= dt:format(values[idx], "'%H:%M:%S'")
                idx += 1
            elsif ch = 'f' then -- float
                ns &= sprintf("%f", {values[idx]})
                idx += 1
            end if
        else
            ns &= ch
        end if
    end for

    return ns
end function


ifdef LINUX then
	constant lib_mysql = open_dll("libmysqlclient.so")

elsifdef FREEBSD then
	constant lib_mysql = open_dll("libmysqlclient.so")

elsifdef OSX then
	constant lib_mysql = open_dll("libmysqlclient.dylib")

elsifdef WIN32 then
	constant lib_mysql = open_dll("libmysql.dll")

else
	puts(1, "Unknown OS\n")
	abort(1)
end ifdef

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

export function mysql_error(atom dbh)
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

export function mysql_insert_id(atom dbh)
	return c_func(h_mysql_insert_id, {dbh})
end function

--**
-- Return the field count for the most recently used query

export function mysql_field_count(atom dbh)
	return c_func(h_mysql_field_count, {dbh})
end function

--**
-- Use a MySQL result

export function mysql_use_result(atom dbh)
	return c_func(h_mysql_use_result, {dbh})
end function

--**
-- Free a MySQL result

export procedure mysql_free_result(atom dbr)
	c_proc(h_mysql_free_result, {dbr})
end procedure

--**
-- Return the number of fields in a MySQL result

export function mysql_num_fields(atom dbr)
	return c_func(h_mysql_num_fields, {dbr})
end function

--**
-- Return the lengths of the fields fetched

export function mysql_fetch_lengths(atom dbr)
	return c_func(h_mysql_fetch_lengths, {dbr})
end function

--**
-- Fetch the next row in a MySQL result

export function mysql_fetch_row(atom dbr)
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

export function mysql_query(atom dbh, sequence sql, object data={})
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

export function mysql_query_one(atom dbh, sequence sql, object data={})
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
