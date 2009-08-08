include std/sequence.e
include std/search.e
include std/text.e

include creole.e
include html_gen.e

sequence smilies = {
	":-)",     "<img src=\"/images/ksk-smile.png\" />",
	":-P",     "<img src=\"/images/ksk-tongue.png\" />",
	":-D",     "<img src=\"/images/ksk-grin.png\" />",
	":-O",     "<img src=\"/images/ksk-shocked.png\" />",
	":lol:",   "<img src=\"/images/ksk-lol.png\" />",
	":-/",     "<img src=\"/images/ksk-getlost.png\" />",
	"^_^",     "<img src=\"/images/ksk-pleased.png\" />",
	":-|",     "<img src=\"/images/ksk-none.png\" />",
	":-(",     "<img src=\"/images/ksk-sad.png\" />",
	";-)",     "<img src=\"/images/ksk-blink.png\" />",
	">:[]",    "<img src=\"/images/ksk-angry.png\" />",
	"B-D",     "<img src=\"/images/ksk-cool.png\" />",
	":'(",     "<img src=\"/images/ksk-cry.png\" />",
	">:)",     "<img src=\"/images/ksk-evil.png\" />",
	":-*",     "<img src=\"/images/ksk-kiss.png\" />",
	":oops:",  "<img src=\"/images/ksk-oops.png\" />",
	":sick:",  "<img src=\"/images/ksk-unwell.png\" />",
	":heart:", "<img src=\"/images/ksk-heart.png\" />",
	":zzz:",   "<img src=\"/images/ksk-zzz.png\" />"
}

sequence KnownWikis = { 
	{"WIKICREOLE",	"http://wikicreole.org/wiki/"},
	{"OHANA",		"http://wikiohana.net/cgi-bin/wiki.pl/"},
	{"WIKIPEDIA",	"http://wikipedia.org/wiki/"}
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
			lHTMLText = pParms[1]

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

		case StrikeText then
			lHTMLText = "--" & pParms[1]

		case InsertText then
			lHTMLText = "++" & pParms[1]
			
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

function markup_quotes(sequence text)
	integer pos = 1
	while pos >= 1 with entry do
		text = replace(text, "<div class=\"quote\"><strong>", pos, pos + 6)
		pos = find_from(']', text, pos)
		text = replace(text, " said:</strong><br />", pos)
	entry
		pos = match_from("[quote", text, pos)
	end while

	text = find_replace("[/quote]", text, "</div>")

	return text
end function

export function format_body(sequence body)
	body = creole_parse(body, routine_id("generate_html"), "0")
	body = markup_quotes(body)
	body = find_replace("&amp;#", body, "&#")

	for i = 1 to length(smilies) by 2 do
		body = find_replace(smilies[i], body, smilies[i+1])
	end for

	return body
end function
