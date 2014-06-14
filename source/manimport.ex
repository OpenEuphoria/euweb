--
-- Import HTML text for the purpose of full text searching only
--
include std/filesys.e
include std/text.e
include std/search.e
include std/sequence.e as seq
include std/io.e
include std/regex.e as re
include std/datetime.e as dt
include std/map.e

-- define NOEDBI to to output to stdout instead of writing to DB
ifdef NOEDBI then
	include std/console.e
elsedef
	include config.e
	include db.e
end ifdef
constant re_tag = re:new(`<[^>]+>`)
constant now = dt:now()
procedure add(sequence fname, sequence a_name, sequence name, sequence content)
	content = re:find_replace(re_tag, content, "")
	ifdef NOEDBI then
		display( {fname, a_name, name, content})
	elsedef
		edbi:execute("""INSERT INTO manual (created_at, filename, a_name, name, content)
			VALUES (%T, %s, %s, %s, %s)""", {
				now, fname, a_name, name, content })
	end ifdef
end procedure
sequence cmds = command_line()
if length(cmds) < 3 then
	puts(1, "usage: manimport.ex file1 file2 ...\n")
	abort(1)
end if
ifdef not NOEDBI then
	db:open()
	edbi:execute("BEGIN")
	edbi:execute("DELETE FROM manual")
end ifdef
sequence files = cmds[3..$]
enum
	FULL_MATCH,
	A_NAME,
	NAME,
	HEADER_LEVEL,
	SECTION,
	HEADING
regex re_header = regex:new( `^<a name="(.*)"></a><a name="(.*)"></a><h([2-4])>([\d\.]+) (.*)</h[2-4]>` )
regex re_words  = regex:new( `[^<"'/]\b([A-Za-z][A-Z_a-z0-9]+)\b` )

procedure add_matches( map words, sequence content )
	object matches = regex:all_matches( re_words, content )
	if sequence( matches ) then
		for i = 1 to length( matches ) do
			map:put( words, matches[i][2], 0 )
		end for
	end if
end procedure

for i = 1 to length(files) do
	sequence fname = files[i]
	sequence bfname = filename(fname)
	sequence
		a_name   = "",
		content  = "",
		name     = "",
		maj_name = "",
		header   = "",
		heading  = ""
	map words = map:new()
	printf(1, "processing %s\n", { fname })
	sequence html = read_file(fname)
	sequence lines = seq:split(html, "\n")
	for j = 1 to length(lines) do
		sequence line = lines[j]
		object matches = regex:matches( re_header, line )
		if sequence( matches ) then
			if length( a_name ) then
				add( bfname, a_name, heading, stdseq:join( map:keys( words, 1), ' ' ) )
			end if
			a_name  = matches[A_NAME]
			name    = matches[NAME]
			header  = matches[HEADER_LEVEL]
			heading = matches[HEADING]
			words = map:new()
			add_matches( words, heading )
			if equal( "2", header ) then
				maj_name = heading
			elsif length( maj_name ) then
				heading = maj_name & ": " & heading & " (" & matches[SECTION] & ')'
			end if
		else
			add_matches( words, line )
		end if
	end for
end for

ifdef not NOEDBI then
	edbi:execute("COMMIT")
	db:close()
end ifdef
