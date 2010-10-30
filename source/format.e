include std/sequence.e
include std/search.e
include std/text.e

include config.e
include creole.e
include html_gen.e

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
	{"SVN", 		"http://rapideuphoria.svn.sourceforge.net/viewvc/rapideuphoria?view=rev&amp;revision="}
}

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
		case InternalLink then
			lHTMLText = sprintf("<a href=\"/wiki/view/%s.wc\">%s</a>", {
				pParms[1], pParms[1] })

		case  InterWikiLink then
			lHTMLText = ""
			lPos = find(':', pParms[1])
			lWiki = upper(pParms[1][1 .. lPos - 1])
			lPage = pParms[1][lPos + 1 .. $]
			for i = 1 to length(KnownWikis) do
				if equal(lWiki, KnownWikis[i][1]) then
					lHTMLText = sprintf("<a class=\"euwiki\" href=\"%s%s\">%s</a>",
						{KnownWikis[i][2], lPage, pParms[2]})

				end if
			end for

			if length(lHTMLText) = 0 then
				lHTMLText = "<span class=\"euwiki_error\">Interwiki link failed for "
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
			lHTMLText = ""

		case HostID then
			lHTMLText = "euforum"

		case OptReparseHeadings then
			lHTMLText = ""

		case PassThru then
			lHTMLText = ""

		case else
			lHTMLText = html_generator(pAction, pParms)

	end switch

	return lHTMLText

end function

export function format_body(sequence body, integer format_quotes=1)
	body = creole_parse(body, routine_id("generate_html"), "0")
	body = search:match_replace("&amp;#", body, "&#")

	for i = 1 to length(smilies) by 2 do
		body = search:match_replace(smilies[i], body, smilies[i+1])
	end for

	return body
end function
