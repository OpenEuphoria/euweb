namespace jsmn

include std/dll.e
include std/get.e
include std/io.e
include std/machine.e
include std/map.e
include std/pretty.e
include std/text.e
include std/types.e
include std/utils.e

ifdef LINUX then
atom libjsmn = open_dll( "libjsmn.so" )

elsifdef WINDOWS then
atom libjsmn = open_dll( "jsmn.dll" )

elsedef
error:crash( "Platform not supported" )

end ifdef

constant _jsmn_init = define_c_proc( libjsmn, "+jsmn_init", {C_POINTER} )
constant _jsmn_parse = define_c_func( libjsmn, "+jsmn_parse", {C_POINTER,C_POINTER,C_SIZE_T,C_POINTER,C_UINT}, C_INT )

constant SIZEOF_JSMNTOK_T = 20
constant SIZEOF_JSMN_PARSER = 12

public constant
	JSMN_ERROR_LOW_MEMORY = (-1),
	JSMN_ERROR_INVALID    = (-2),
	JSMN_ERROR_PARTIAL    = (-3),
	JSMN_ERROR_NOT_ENOUGH = (-4),
$

public constant
	JSMN_UNDEFINED = 0,
	JSMN_OBJECT    = 1,
	JSMN_ARRAY     = 2,
	JSMN_STRING    = 3,
	JSMN_PRIMITIVE = 4,
$

public constant
	J_TYPE   = 1,
	J_START  = 2,
	J_END    = 3,
	J_SIZE   = 4,
	J_PARENT = 5,
$

public constant
	J_VALUE = 2,
	J_COUNT = 3,
$

public function jsmn_parse( string js )
--	return machine_func( M_JSON_PARSE, text:trim(js) )

	atom parser = allocate_data( SIZEOF_JSMN_PARSER )

	atom ptr_js = allocate_string( js, 1 )
	atom len_js = length( js )

	atom num_tokens = 256
	atom ptr_tokens = allocate_data( SIZEOF_JSMNTOK_T * num_tokens )

	c_proc( _jsmn_init, {parser} )
	atom result = c_func( _jsmn_parse, {parser,ptr_js,len_js,ptr_tokens,num_tokens} )

	while result = JSMN_ERROR_LOW_MEMORY do

		free( ptr_tokens )

		num_tokens += 128
		ptr_tokens = allocate_data( SIZEOF_JSMNTOK_T * num_tokens )

		c_proc( _jsmn_init, {parser} )
		result = c_func( _jsmn_parse, {parser,ptr_js,len_js,ptr_tokens,num_tokens} )

	end while

	if result < 0 then
		return result
	end if

	atom t = ptr_tokens
	sequence tokens = repeat( 0, result )

	for i = 1 to length( tokens ) do
		tokens[i] = peek4s({ t, 5 })
		t += SIZEOF_JSMNTOK_T
	end for

	free( ptr_tokens )
	free( parser )

	return tokens
end function

public function jsmn_value( string js, sequence tokens = {}, integer start = 1 )

	if length( tokens ) = 0 then

		-- parse string for tokens
		object temp = jsmn_parse( js )

		if atom( temp ) then
			-- return the error
			return temp
		end if

		tokens = temp

	end if

	if length( tokens ) < start then
		-- not enough tokens provided
		return JSMN_ERROR_NOT_ENOUGH
	end if

	sequence t = tokens[start]

    switch t[J_TYPE] do

        case JSMN_PRIMITIVE then
            -- a JSON primitive is a numeric value or
			-- literal value (i.e. true/false/null)

            -- get the string offsets
            integer j_start = t[J_START]
            integer j_end   = t[J_END]

            -- get the string value
            object p = text:trim( js[j_start..j_end] )

			-- is this a literal value?
            if not find( p, {"true","false","null"} ) then
				-- no, convert it to a number
                sequence val = stdget:value( p )
                p = val[2]
            end if

            return {JSMN_PRIMITIVE,p,1}

        case JSMN_OBJECT then
            -- a JSON object is a key/object map
            map m = map:new()

            integer i = start + 1
            for n = 1 to t[J_SIZE] do

                -- get the key and update the offset
                object key = jsmn_value( js, tokens, i )
				if atom( key ) then
					-- error
					return key
				end if
                i += key[J_COUNT]

                -- get the object and update the offset
                object obj = jsmn_value( js, tokens, i )
				if atom( obj ) then
					-- error
					return obj
				end if
                i += obj[J_COUNT]

                -- trim surrounding quotes
                key = text:trim( key, `"` )

                -- store the key/object pair in the map
                map:put( m, key[2], obj )

                if i > length( tokens ) then
                    -- no more tokens here
                    exit
                end if

            end for

            return {JSMN_OBJECT,m,i-start}

        case JSMN_ARRAY then
            -- a JSON array is a sequence of object
            sequence s = repeat( 0, t[J_SIZE] )

            integer i = start + 1
            for n = 1 to t[J_SIZE] do

                -- get the value and update the offset
                object val = jsmn_value( js, tokens, i )
				if atom( val ) then
					-- error
					return val
				end if
				i += val[J_COUNT]

                -- add the item to the array
                s[n] = val

                if i > length( tokens ) then
                    -- no more tokens here
					s = s[1..n]
                    exit
                end if

            end for

            return {JSMN_ARRAY,s,i-start}

        case JSMN_STRING then
            -- a JSON string is just a literal string

            -- get the string offsets
            integer j_start = t[J_START]
            integer j_end   = t[J_END]

            -- get the string value
            sequence s = js[j_start..j_end]

            -- trim surrounding quotes
            s = text:trim( s, `"` )

            return {JSMN_STRING,s,1}

	end switch

	return 0
end function

type json_value( object x )

	if not sequence( x ) then
		return 0
	end if

	if not length( x ) = 3 then
		return 0
	end if

	if not find( x[1], {JSMN_OBJECT,JSMN_ARRAY,
			JSMN_STRING,JSMN_PRIMITIVE} ) then
		return 0
	end if

	return 1
end type

function json_object( object x )
	return map( x )
end function

function json_array( object x )
	return sequence( x )
end function

function json_string( object x )
	return string( x )
end function

function json_primitive( object x )
	return atom( x ) or find( x, {"true","false","null"} )
end function

public function jsmn_new( integer j_type, object j_value = 0 )

	switch j_type do

		case JSMN_OBJECT then

			if equal( j_value, 0 ) then
				-- default value
				j_value = map:new()

			elsif sequence_array( j_value ) then

				-- create a new map of key/value pairs
				/* j_value = map:new_from_kvpairs( j_value ) */

				-- N.B. need to process kvpairs manually to verify contents

				map m = map:new()

				for i = 1 to length( j_value ) do

					if length( j_value[i] ) != 2 then
						-- not a key/value pair
						return 0

					elsif not string( j_value[i][1] ) then
						-- key is not a string
						return 0

					end if

					-- convert raw values into json values
					if not json_value( j_value[i][2] ) then

						integer item_type = JSMN_PRIMITIVE
						if json_string( j_value[i][2] ) and not json_primitive( j_value[i][2] ) then
							item_type = JSMN_STRING
						end if

						j_value[i][2] = jsmn_new( item_type, j_value[i][2] )

					end if

					map:put( m, j_value[i][1], j_value[i][2] )

				end for

				j_value = m

			end if

			if not json_object( j_value ) then
				-- invalid type
				return 0
			end if

		case JSMN_ARRAY then

			if atom( j_value ) then
				-- default value
				j_value = {}
			end if

			for i = 1 to length( j_value ) do

				-- convert raw values into json values
				if not json_value( j_value[i] ) then

					integer item_type = JSMN_PRIMITIVE
					if json_string( j_value[i] ) and not json_primitive( j_value[i] ) then
						item_type = JSMN_STRING
					end if

					j_value[i] = jsmn_new( item_type, j_value[i] )

				end if

			end for

			if not json_array( j_value ) then
				-- invalid type
				return 0
			end if

		case JSMN_STRING then

			if equal( j_value, 0 ) then
				-- default value
				j_value = ""

			elsif not json_string( j_value ) then
				-- invalid type
				return 0

			end if

		case JSMN_PRIMITIVE then

			if not json_primitive( j_value ) then
				-- invalid ype
				return 0
			end if

	end switch

	return {j_type,j_value,0}
end function

public function jsmn_sprint( sequence obj, integer white_space = 1, integer tab_width = 4, integer column = 0 )

	sequence pad1, pad2, eol

	if white_space then
		pad1 = repeat( ' ', (column+0) * tab_width )
		pad2 = repeat( ' ', (column+1) * tab_width )
		eol = "\n"
	else
		pad1 = ""
		pad2 = ""
		eol = ""
	end if

	sequence buffer = ""

	switch obj[J_TYPE] do

		case JSMN_PRIMITIVE then
			-- obj[J_VALUE] is a numeric value or
            -- literal value (i.e. true/false/null)

			-- convert atoms to strings
			if atom( obj[J_VALUE] ) then
				obj[J_VALUE] = text:sprint( obj[J_VALUE] )
			end if

			-- print the value
			buffer &= sprintf( "%s", {obj[J_VALUE]} )

		case JSMN_OBJECT then
			-- obj[J_VALUE] is a key/object map

			-- get the object keys
			sequence keys = map:keys( obj[J_VALUE] )

			-- print the start character
			buffer &= "{" & eol

			-- loop through the keys
			for i = 1 to length( keys ) do

				-- print the padding and key name
				buffer &= pad2 & sprintf( `"%s": `, {keys[i]} )

				-- print the key object
				buffer &= jsmn_sprint( map:get(obj[J_VALUE], keys[i]), white_space, tab_width, column+1 )

				-- print a comma and/or new line
				buffer &= iff(i < length(keys), ",", "") & eol

			end for

			-- print padding the end character
			buffer &= pad1 & "}"

		case JSMN_ARRAY then
			-- obj[J_VALUE] is a sequence of objects

			-- get the array items
			sequence items = obj[J_VALUE]

			-- print the start character
			buffer &= "[" & eol

			-- loop through the items
			for i = 1 to length( items ) do

				-- print the padding
				buffer &= pad2

				-- print the item value
				buffer &= jsmn_sprint( items[i], white_space, tab_width, column+1 )

				-- print a comma and/or new line
				buffer &= iff(i < length(items), ",", "") & eol

			end for

			-- print the padding and end character
			buffer &= pad1 & "]"

		case JSMN_STRING then
			-- obj[J_VALUE] is a literal string

			-- print the string
			buffer &= sprintf( `"%s"`, {obj[J_VALUE]} )

	end switch

	return buffer
end function

public procedure jsmn_write( object fn, sequence obj, integer white_space = 1, integer tab_width = 4, integer column = 0 )

	if sequence( fn ) then
		-- open the file for writing
		fn = open( fn, "w", 1 )
	end if

	sequence pad1, pad2, eol

	if white_space then
		pad1 = repeat( ' ', (column+0) * tab_width )
		pad2 = repeat( ' ', (column+1) * tab_width )
		eol = "\n"
	else
		pad1 = ""
		pad2 = ""
		eol = ""
	end if

	switch obj[J_TYPE] do

		case JSMN_PRIMITIVE then
			-- obj[J_VALUE] is a numeric value or
            -- literal value (i.e. true/false/null)

			-- convert atoms to strings
			if atom( obj[J_VALUE] ) then
				obj[J_VALUE] = text:sprint( obj[J_VALUE] )
			end if

			-- print the value
			printf( fn, "%s", {obj[J_VALUE]} )

		case JSMN_OBJECT then
			-- obj[J_VALUE] is a key/object map

			-- get the object keys
			sequence keys = map:keys( obj[J_VALUE] )

			-- print the start character
			printf( fn, "{" & eol )

			-- loop through the keys
			for i = 1 to length( keys ) do

				-- print the padding and key name
				printf( fn, pad2 & `"%s": `, {keys[i]} )

				-- print the key object
				jsmn_write( fn, map:get(obj[J_VALUE], keys[i]), white_space, tab_width, column+1 )

				-- print a comma and/or new line
				printf( fn, iff(i < length(keys), ",", "") & eol )

			end for

			-- print the end character
			printf( fn, pad1 & "}" )

		case JSMN_ARRAY then
			-- obj[J_VALUE] is a sequence of objects

			-- get the array items
			sequence items = obj[J_VALUE]

			-- print the start character
			printf( fn, "[" & eol )

			-- loop through the items
			for i = 1 to length( items ) do

				-- print the padding
				printf( fn, pad2 )

				-- print the item value
				jsmn_write( fn, items[i], white_space, tab_width, column+1 )

				-- print a comma and/or new line
				printf( fn, iff(i < length(items), ",", "") & eol )

			end for

			-- print the padding and end character
			printf( fn, pad1 & "]" )

		case JSMN_STRING then
			-- obj[J_VALUE] is a literal string

			-- print the string
			printf( fn, `"%s"`, {obj[J_VALUE]} )

	end switch

end procedure

