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

include config.e
include db.e

constant re_tag = re:new(`<[^>]+>`)

constant now = dt:now()

procedure add(sequence fname, sequence a_name, sequence name, sequence content)
	content = re:find_replace(re_tag, content, "")
	edbi:execute("""INSERT INTO manual (created_at, filename, a_name, name, content) 
		VALUES (%T, %s, %s, %s, %s)""", {
			now, fname, a_name, name, content })
end procedure

sequence cmds = command_line()
if length(cmds) < 3 then
	puts(1, "usage: manimport2.ex file1 file2 ...\n")
	abort(1)
end if

db:open()

edbi:execute("BEGIN")
edbi:execute("DELETE FROM manual")

sequence files = cmds[3..$]

for i = 1 to length(files) do
	sequence fname = files[i]
	sequence bfname = filename(fname)
	sequence a_name = "", content = "", name = ""
	
	printf(1, "processing %s\n", { fname })
	sequence html = read_file(fname)
	
	sequence lines = seq:split(html, "\n")

	for j = 1 to length(lines) do
		sequence line = lines[j]
	
		if begins("<a name=\"", line) then
			-- We only want h2, h3 and h4 a names
			sequence nline = lines[j+1]
			if begins("<h2", nline) or
				begins("<h3", nline) or
				begins("<h4", nline)
			then
				if length(a_name) and length(content) then
					add(bfname, a_name, name, content)
				end if
			
				content = ""
			
				integer end_pos = find_from('"', line, 10)
				if end_pos = 0 then
					continue
				end if
			
				a_name = line[10..end_pos-1]
			
				end_pos = find_from('<', nline, 5)
				if end_pos = 0 then
					continue
				end if
			
				name = nline[5..end_pos - 1]
			end if
		elsif length(a_name) then
			content &= line & "\n"
		end if
	end for
end for

edbi:execute("COMMIT")
db:close()
