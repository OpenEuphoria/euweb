include std/get.e
include std/io.e
include std/filesys.e
include std/search.e

constant REV_HEADER = 1, REV_TEXT = 2

function escape_sql(sequence s)
	return match_replace("'", match_replace("\\", s, "\\\\", 0), "''", 0)
end function

function toInteger(sequence s)
	s = value(s)
	return s[2]
end function

sequence revs = {}
sequence list_of_pages, oldpagename = ""
list_of_pages = dir("euwikidb/pages/*.txt")
for i = 1 to length(list_of_pages) do
	sequence pagename = list_of_pages[i][D_NAME][1..$-4]
	sequence alltext = read_lines("euwikidb/pages/"&pagename&".txt")
	integer rev_i = 1
	for j = 1 to length(alltext) do
		if find(0, alltext[j]) then
			-- end of wiki page
			exit
		elsif match("#Revision$", alltext[j]) = 1 then
			revs = append(revs, {{}, {}})
			rev_i = length(revs)

			alltext[j] = alltext[j][length("#Revision$")+1..$]
			integer revno = toInteger(alltext[j][1..find('$', alltext[j])-1])
			alltext[j] = alltext[j][find('$', alltext[j])+1..$]
			-- handle tip
			-- if we're handling the first revision that we see for this page (i.e. it's a new page) then we know this is the newest revision
			if not equal(oldpagename, pagename) then
				revno = 0
			end if

			sequence datestr = alltext[j][1..find('$', alltext[j])-1]
			alltext[j] = alltext[j][find('$', alltext[j])+1..$]

			sequence author, reason
			if find('$', alltext[j]) then
				author = alltext[j][1..find('$', alltext[j])-1]
				alltext[j] = alltext[j][find('$', alltext[j])+1..$]
				reason = alltext[j]
			else
				-- no reason in wiki .txt file
				author = alltext[j]
				reason = ""
			end if

			if equal(pagename, "Sandbox") then
				pagename = "Sandbox-Two"
			elsif equal(pagename, "HomePage") then
				pagename = "home"
			end if
			switch author with fallthru do
				case "cchris00" then
				case "cchris005" then
					author = "cchris"
					break

				case "ryan" then
					author = "ryanj"
					break

				case "iamlost" then
					author = "jimcbrown"
					break
			end switch

			revs[rev_i][REV_HEADER] = { revno, pagename, datestr, author, escape_sql(reason) }
		else
			revs[rev_i][REV_TEXT] &= alltext[j] & "\n"
		end if
		oldpagename = pagename
	end for
end for

printf(1, "DELETE FROM wiki_page;\n", {})
for i = 1 to length(revs) do
	printf(1, """
			INSERT INTO wiki_page VALUES (%d, '%s', '%s', (SELECT id FROM users WHERE user='%s'), '%s', '%s');
		""", revs[i][REV_HEADER] & { escape_sql(revs[i][REV_TEXT]) })
end for
