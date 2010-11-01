include std/sequence.e
include std/search.e
include std/text.e

include config.e
include creole.e
include html_gen.e

include webclay/logging.e as log

include wiki_db.e as wiki_db

integer generate_html_rid = -1

sequence smilies = {
	":-)",     "<img src=\"" & ROOT_URL & "/images/ksk-smile.png\" alt=\"smile\" />",
	":-P",     "<img src=\"" & ROOT_URL & "/images/ksk-tongue.png\" alt=\"tongue\" />",
	":-D",     "<img src=\"" & ROOT_URL & "/images/ksk-grin.png\" alt=\"grin\" />",
	":-O",     "<img src=\"" & ROOT_URL & "/images/ksk-shocked.png\" alt=\"shocked\" />",
	":lol:",   "<img src=\"" & ROOT_URL & "/images/ksk-lol.png\" alt=\"lol\" />",
	":-/",     "<img src=\"" & ROOT_URL & "/images/ksk-getlost.png\" alt=\"getlost\" />",
	"^_^",     "<img src=\"" & ROOT_URL & "/images/ksk-pleased.png\" alt=\"pleased\" />",
	":-|",     "<img src=\"" & ROOT_URL & "/images/ksk-none.png\" alt=\"none\" />",
	":-(",     "<img src=\"" & ROOT_URL & "/images/ksk-sad.png\" alt=\"sad\" />",
	";-)",     "<img src=\"" & ROOT_URL & "/images/ksk-blink.png\" alt=\"blink\" />",
	">:[]",    "<img src=\"" & ROOT_URL & "/images/ksk-angry.png\" alt=\"angry\" />",
	"B-D",     "<img src=\"" & ROOT_URL & "/images/ksk-cool.png\" alt=\"cool\" />",
	":'(",     "<img src=\"" & ROOT_URL & "/images/ksk-cry.png\" alt=\"cry\" />",
	">:)",     "<img src=\"" & ROOT_URL & "/images/ksk-evil.png\" alt=\"evil\" />",
	":-*",     "<img src=\"" & ROOT_URL & "/images/ksk-kiss.png\" alt=\"kiss\" />",
	":oops:",  "<img src=\"" & ROOT_URL & "/images/ksk-oops.png\" alt=\"oops\" />",
	":sick:",  "<img src=\"" & ROOT_URL & "/images/ksk-unwell.png\" alt=\"unwell\" />",
	":heart:", "<img src=\"" & ROOT_URL & "/images/ksk-heart.png\" alt=\"heart\" />",
	":zzz:",   "<img src=\"" & ROOT_URL & "/images/ksk-zzz.png\" alt=\"zzz\" />"
}

sequence KnownWikis = {
	{"WIKICREOLE",	"http://wikicreole.org/wiki/"},
	{"OHANA",		"http://wikiohana.net/cgi-bin/wiki.pl/"},
	{"WIKIPEDIA",	"http://wikipedia.org/wiki/"},
	{"TICKET",  	"http://openeuphoria.org/ticket/view.wc?id="},
	{"MESSAGE", 	"http://openeuphoria.org/forum/view.wc?id="},
	{"NEWS",		"http://openeuphoria.org/news/view.wc?id="},
	{"WIKI",        "http://openeuphoria.org/wiki/view.wc?page="},
	{"SVN", 		"http://rapideuphoria.svn.sourceforge.net/viewvc/rapideuphoria?view=rev&amp;revision="}
}

export function format_body(sequence body, integer format_quotes=1)
	body = creole_parse(body, generate_html_rid, "0")
	body = search:match_replace("&amp;#", body, "&#")

	for i = 1 to length(smilies) by 2 do
		body = search:match_replace(smilies[i], body, smilies[i+1])
	end for

	return body
end function

function creole_plugin_wikipage(sequence params)
	sequence result = ""
	sequence style = "none"
	sequence page = "--INVALID-PAGE--"
	integer toc_heading = 1

	for i = 2 to length(params) do
		switch params[i][1] do
			case "style" then
				style = params[i][2]

			case "page" then
				page = params[i][2]

			case "heading" then
				if find(params[i][2], { "on", "off", "hide", "0" }) then
					toc_heading = 0
				end if
		end switch
	end for

	if toc_heading then
		result &= sprintf("<a href=\"/wiki/view/%s.wc\">%s</a>:\n", {
			page, page })
	end if

	result &= sprintf("<div class=\"wiki %s\">", { style })
	object wikipage = wiki_db:get(page)
	if atom(wikipage) then
		return "<strong>INVALID PAGE</strong>"
	end if

	result &= format_body(wikipage[wiki_db:WIKI_TEXT])

	result &= "</div>"

	return result
end function

function generate_html(integer pAction, sequence pParms, object pContext)
	sequence lHTMLText
	integer lPos
	integer lIdx
	integer lInstance
	integer lData
	integer lDepth
	sequence lSuffix
	sequence lWiki
	sequence lPage
	sequence lParms
	sequence lHeadings
	object lValue
	sequence lSpacer
	sequence lHere
	sequence lElements
	integer lLookingNext
	integer lSkipping
	integer lThisElement
	sequence lThisFile
	sequence lThisContext
	sequence lThisText
	sequence lNextPageFile
	sequence lNextChapFile
	sequence lPrevPageFile
	sequence lPrevChapFile
	sequence lParentFile
	sequence lCurrChapFile
	sequence lTOCFile
	sequence lHomeFile
	integer lThisLevel = 0

	lHTMLText = ""
	lSpacer = ""

	switch pAction do
		case CamelCase then
			lHTMLText = pParms

		case InternalLink then
			lHTMLText = sprintf("<a href=\"/wiki/view/%s.wc\">%s</a>", {
				pParms[1], pParms[2] })

		case  InterWikiLink then
			lHTMLText = ""
			lPos = find(':', pParms[1])
			lWiki = upper(pParms[1][1 .. lPos - 1])
			lPage = pParms[1][lPos + 1 .. $]
			for i = 1 to length(KnownWikis) do
				if equal(lWiki, KnownWikis[i][1]) then
					lHTMLText = sprintf("<a href=\"%s%s\">%s</a>",
						{KnownWikis[i][2], lPage, pParms[2]})
				end if
			end for

			if length(lHTMLText) = 0 then
				lHTMLText = "<span class=\"error\">Interwiki link failed for "
				for i = 1 to length(pParms) do
					lHTMLText &= pParms[i]
					if i < length(pParms) then
						lHTMLText &= ", "
					end if
				end for
				lHTMLText &= "</span>"
			end if

		case Document then
			lHTMLText = pParms[1]

		case Plugin then
			lInstance = pParms[4]
			lParms = keyvalues(pParms[1], -1, -2)
			lHTMLText = ""

			switch upper(lParms[1][2]) do
				case "WIKIPAGE" then
					--lHTMLText = creole_plugin_wikipage(lParms)
			end switch

		case Quoted then
			-- Highlight a quoted section.
			if length(pParms[2]) > 0 then
				lHTMLText = "\n<div class=\"quote\"><div class=\"attribution\"><span class=\"name\">" &
					pParms[1] &
					" said...</span></div>\n" &
					"<div class=\"body\">" & pParms[2] & "</div>" &
					"\n</div>\n"
			end if
		
		case HostID then
			lHTMLText = "euweb"

		case OptReparseHeadings then
			lHTMLText = ""

		case PassThru then
			lHTMLText = ""

		case else
			lHTMLText = html_generator(pAction, pParms)

	end switch

	return lHTMLText
end function

generate_html_rid = routine_id("generate_html")
