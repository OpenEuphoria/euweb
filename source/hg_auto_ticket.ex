#!/usr/bin/eui

--
-- Analyze a HG commit message and look for ticket references.
-- If found, update the given ticket.
--
-- References are case insensitive
-- Multiple references can exist in one commit message
-- Ticket references can be either ticket:123 (old style) or ticket 123 (new style)
--
-- Example references:
--   * ticket 123        -- simple reference
--   * fixes ticket 123  -- marks bug as fixed
--   * fixes? ticket 123 -- marks bug as fixed, please confirm
--
-- Parameters via ENV
--
-- HG_NODE='ea3bb483859d65c4b858d900812e144e46d03fdc'
-- HG_SOURCE='serve'
-- HG_URL='remote:https::jeremy'
--

include std/convert.e
include std/filesys.e
include std/io.e
include std/pretty.e
include std/regex.e as re
include std/sequence.e as seq
include std/text.e

include db.e
include user_db.e as user_db
include ticket_db.e as ticket_db
include comment_db.e as comment_db

constant re_ref = re:new(`(fixes)?(\?)?\s+ticket[ :]([0-9]+)`, re:CASELESS)

enum REFERENCES = 0, MAYBE_FIXES = 8, FIXES = 3 -- status ids, 0 = no update
enum R_FULL, R_FIXES, R_MAYBE, R_NUM

--**
-- Parse the commit message and return a sequence only of information
-- we are interested in
--
-- {
--   { REFERENCES | MAYBE_FIXES | FIXES, ticket_number },
--   ...
-- }
--

function get_refs(sequence msg)
	sequence result = {}
	object matches = re:find_all(re_ref, msg)

	for i = 1 to length(matches) do
		sequence m = matches[i]
		integer num = to_number(msg[m[R_NUM][1]..m[R_NUM][2]])
		integer typ = 0

		if m[R_FIXES][1] = 0 then
			typ = REFERENCES
		elsif m[R_MAYBE][1] = 0 then
			typ = FIXES
		else
			typ = MAYBE_FIXES
		end if

		result = append(result, { typ, num })
	end for

	return result
end function

sequence cmdline = command_line()
object hg_node   = getenv("HG_NODE")
object hg_source = getenv("HG_SOURCE")
object hg_url    = getenv("HG_URL")

sequence tmp_filename = sprintf("/tmp/%s.log", { hg_node })
system(sprintf("hg log -r %s > %s", { hg_node, tmp_filename }))

object lines = read_lines(tmp_filename)
delete_file(tmp_filename)
if not sequence(lines) then
	puts(1, "aborting\n")
	abort(0)
end if

sequence url_data = seq:split(hg_url, ":")
sequence username = url_data[4]

sequence commentMsg = join(lines, "\n")

integer summaryPos = match("summary:", commentMsg)
if summaryPos then
	commentMsg = "\n" & trim(commentMsg[summaryPos+8..$]) & "\n"
else
	commentMsg = "\n" & commentMsg & "\n"
end if

sequence content = join(lines, " ")
sequence refs = get_refs(content)

if length(refs) then
	db:open()

	for i = 1 to length(refs) do
		sequence ref = refs[i]

		edbi:execute("BEGIN")

		if ref[1] then
			edbi:execute("UPDATE ticket SET status_id=%d WHERE id=%d", {
				ref[1], ref[2] })
		end if

		current_user = user_db:get_by_code(username)
		comment_db:add_comment(
			ticket_db:MODULE_ID, 
			ref[2], 
			sprintf("Related SCM commit %s", { hg_node[1..12] }),
			sprintf("See: [[hg:%s/rev/%s]]\n\n%s", { cmdline[3], hg_node[1..12], commentMsg }))

		edbi:execute("COMMIT")
	end for

	db:close()
end if

