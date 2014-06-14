-- wraper around iconv utilities in GNU C Lib
-- no-op for non-Linux, works with 4.0 and 4.1

namespace iconv

include std/dll.e
include std/machine.e

ifdef EU4_0 then
	constant SIZEOF_PTR = 4
	procedure poke_pointer( atom ptr, object val )
		poke4( ptr, val )
	end procedure
elsedef
	constant SIZEOF_PTR = sizeof( C_POINTER )
end ifdef

constant
	ICONV       = define_c_func( 0, "iconv", { C_POINTER, C_POINTER, C_POINTER, C_POINTER, C_POINTER }, C_POINTER ),
	ICONV_OPEN  = define_c_func( 0, "iconv_open", { C_POINTER, C_POINTER }, C_POINTER ),
	ICONV_CLOSE = define_c_func( 0, "iconv_close", { C_POINTER }, C_INT ),
	$

enum
	ICON_CD,
	ICON_TOCODE,
	ICON_FROMCODE

public type iconv_t( object o )
	if atom( o ) then
		return 0
	end if
	if length( o ) != 3 then
		return 0
	end if
	if not atom( o[ICON_CD] )           then return 0 end if
	if not sequence( o[ICON_TOCODE] )   then return 0 end if
	if not sequence( o[ICON_FROMCODE] ) then return 0 end if
	return 1
end type

procedure close( iconv_t iconv )
	ifdef LINUX then
		c_func( ICONV_CLOSE, { iconv[ICON_CD] })
	end ifdef
end procedure
integer close_iconv = routine_id("iconv:close")

--**
-- Creates a new iconv_t. Use iconv --list to get
-- a platform dependent list of encodings available.
--
-- Optionally use //TRANSLIT and //IGNORE to the encoding.
-- For instance, to sanitize UTF8, use UTF8//IGNORE in
-- the tocode parameter and invalid 
public function new( sequence tocode, sequence fromcode )
	iconv_t iconv = { 0, tocode, fromcode }
	ifdef LINUX then
		atom from_ptr, to_ptr
		from_ptr = allocate_string( fromcode, 1 )
		to_ptr   = allocate_string( tocode, 1 )
		iconv[ICON_CD] = c_func( ICONV_OPEN, { to_ptr, from_ptr })
	end ifdef
	return delete_routine( iconv, close_iconv )
end function

public function convert( iconv_t iconv, sequence text )
	ifdef not LINUX then
		return text
	elsedef
		atom inbuff  = allocate( length( text ) + SIZEOF_PTR + 1, 1 )
		atom outbuff = allocate( length( text ) + SIZEOF_PTR + 1, 1 )
		atom inleft  = allocate( SIZEOF_PTR, 1 )
		atom outleft = allocate( SIZEOF_PTR, 1 )
		poke_pointer( inbuff, inbuff + SIZEOF_PTR )
		poke( inbuff + SIZEOF_PTR, text )
		poke( outbuff, repeat( 0, SIZEOF_PTR + length( text ) + 1 ) )
		poke_pointer( outbuff, outbuff + SIZEOF_PTR )
		poke_pointer( inleft, length( text ) )
		poke_pointer( outleft, length( text ) )
		c_func( ICONV, { iconv[ICON_CD], inbuff, inleft, outbuff, outleft } )
		return peek_string( outbuff + SIZEOF_PTR )
	end ifdef
end function


ifdef TEST_CONVERT then
	iconv_t sanitize = iconv:new( "UTF8//IGNORE", "UTF8" )
	sequence bad = "good " & {#1A, #AD} & " bad"
	
	? convert( sanitize, bad )
	? bad
	delete( sanitize )
end ifdef
