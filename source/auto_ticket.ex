--
-- Update tickets for items found in the SVN repo
-- 

include std/error.e
include std/io.e
include std/filesys.e
include std/text.e
include std/regex.e
include std/net/http.e

include std/get.e
include edbi/edbi.e
include db.e

db:open()

if not file_exists("auto_ticket.svn") then
	crash("auto_ticket.svn does not exist, please create it with the starting svn revision number")
end if

sequence last_svn = trim(read_file("auto_ticket.svn"))
sequence cmd = sprintf("svn log -r%s:HEAD http://rapideuphoria.svn.sourceforge.net/svnroot/rapideuphoria > auto_ticket.log", { last_svn })
system(cmd)

constant 
	re_rev = regex:new(`r([0-9]+) \| ([A-Za-z0-9_]+) \|`), -- rev number | username |
	re_ticket = regex:new(`ticket:([0-9]+)`) -- ticket:123

sequence tmp, current_rev = "", current_user = ""
object rev, id
sequence svn_log = read_lines("auto_ticket.log")
for i = 1 to length(svn_log) do
	if regex:has_match(re_rev, svn_log[i]) then
		tmp = regex:matches(re_rev, svn_log[i])
		current_rev = tmp[2]
		current_user = tmp[3]
	elsif regex:has_match(re_ticket, svn_log[i]) then
		tmp = regex:all_matches(re_ticket, svn_log[i])
		for j = 1 to length(tmp) do
			--get_url(sprintf("http://openeuphoria.org/ticket/auto.wc?id=%s&rev=%s", {
				--tmp[j][2], current_rev }))

	id = value(tmp[j][2])
	if id[1] != GET_SUCCESS then
		id = -1
	else
		id = id[2]
	end if

	rev = current_rev

	if id = -1 then 
		--return { TEXT, "bad-id" }
		continue
	end if

	if length(rev) then
		object ticket_rev = edbi:query_object("SELECT svn_rev FROM ticket WHERE id=%d", { id })
		if atom(ticket_rev) then
			--return { TEXT, "ticket-not-found" }
			continue
		end if
		
		if not match(rev, ticket_rev) then
			if length(ticket_rev) then
				ticket_rev &= ", " & rev
			else
				ticket_rev = rev
			end if
			
			edbi:execute("UPDATE ticket SET svn_rev=%s WHERE id=%d", { ticket_rev, id })
		end if
	end if
				--tmp[j][2], current_rev }))
		end for
	end if
end for

db:close()
write_file("auto_ticket.svn", current_rev)
