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
	HEADER,
	CONTENT

regex re_header = regex:new( `^<a name="(.*)"></a><a name="(.*)"></a><h([2..4])>(.*)</h[2..4]>` )
for i = 1 to length(files) do
	sequence fname = files[i]
	sequence bfname = filename(fname)
	sequence
		a_name   = "",
		content  = "",
		name     = "",
		maj_name = "",
		header   = ""

	printf(1, "processing %s\n", { fname })
	sequence html = read_file(fname)

	sequence lines = seq:split(html, "\n")

	for j = 1 to length(lines) do
		sequence line = lines[j]
		object matches = regex:matches( re_header, line )
		if sequence( matches ) then
			
			a_name = matches[A_NAME]
			name   = matches[NAME]
			header = matches[HEADER]
			content = matches[CONTENT]
			if equal( "2", header ) then
				maj_name = name
			elsif length( maj_name ) then
				name = maj_name & ": " & name
			end if
			add(bfname, a_name, name, content)
		end if
	end for
end for

ifdef not NOEDBI then
	edbi:execute("COMMIT")
	db:close()
end ifdef

