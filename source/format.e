include std/sequence.e
include std/search.e
include std/text.e
include std/regex.e

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
	{"NEWS",		"http://openeuphoria.org/news/view.wc?id="}
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
 	integer pos
 	integer epos
 	integer nextpos = 1
 	integer repcnt = 0
 	integer namepos
 	integer nameend 
 	integer inname

	while 1 do
		pos = match_from("[quote", text, nextpos)
		if pos = 0 then
			exit
		end if

		epos = pos + 6
		
		-- Look back to see if we have <p>
		if pos > 3 then
			if equal(text[pos-3..pos], "<p>") then
				pos -= 3
			end if
		end if

		inname = 0
		nameend = 0
		-- scan for the close of this quote-open tag
		while epos <= length(text) do
			if text[epos] = ']' then
				exit
			end if
			
			if text[epos] = '\n' then
				-- should not happen in valid code.
				-- assume that the closing bracket was missing
				-- so assume it should be right here.
				epos -= 1
				nameend = epos
				exit
			end if
			
			if text[epos] = '[' then
				-- should not happen in valid code.
				-- assume that the closing bracket was missing
				-- so go back to start of tag and pretend missing
				-- bracket is after the first word in the tag.
				epos = pos + 6
				inname = 0
				while epos <= length(text) do
					if find(text[epos] , " \t") then
						if inname then
							epos -= 1
							nameend = epos
							exit	
						end if
					else
						if not inname then
							inname = 1
							namepos = epos
						end if
					end if
					epos += 1
				end while
				if epos > length(text) then
					epos = length(text)
				end if
				exit
			end if
			
			if not inname then
				if not find(text[epos], " \t") then
					inname = 1
					namepos = epos
				end if
			end if
			epos += 1
		end while
		
		if inname then
			if nameend = 0 then
				nameend = epos - 1
			end if
		end if
		
		if inname then
			text = text[1..pos-1] & "<div class=\"quote\"><strong>" & 
			       text[namepos .. nameend] & " </strong>said:<br />" & 
			       text[epos + 1 .. $]
			nextpos = pos + 27 + 21 + nameend - namepos + 1
		else
			text = text[1..pos-1] & "<div class=\"quote:\"><strong>quote</strong><br />" & 
			       text[epos + 1 .. $]
			nextpos = pos + 48
		end if
		repcnt += 1
	end while
	
	while 1 do
		pos = match("[/quote]", text)
		if pos then
			if repcnt > 0 then
				text = text[1 .. pos - 1] & "</div>" & text[ pos + 8 .. $]
				repcnt -= 1
			else
				-- too many end tags, so remove the excess.
				text = text[1 .. pos - 1] & text[ pos + 8 .. $]
			end if
		else
			if repcnt = 0 then	
				exit
			end if
			-- Missing one or more end of quote tags.
			while repcnt > 0 do
				text &= "</div>"
				repcnt -= 1
			end while
		end if
		
	end while
	
	return text
end function

constant
	re_quote_begin = regex:new(`(<p>)?\[quote ([A-Za-z0-9_]+)]`),
	re_quote_end = regex:new(`\[/quote\][ \t]*(</p>)?`)

function find_count(sequence needle, sequence haystack)
	integer count = 0, pos = 1
	
	while pos with entry do
		count += 1
		pos += length(needle)
	entry
		pos = match(needle, haystack, pos)
	end while

	return count
end function

function markup_quotes_two(sequence body)
	integer quote_begins = find_count("[quote", body)
	integer quote_ends = find_count("[/quote]", body)

	body = regex:find_replace(re_quote_begin, body, `<div class="quote">
<p><strong>\2 said:</strong>`)
	body = regex:find_replace(re_quote_end, body, `</p>
</div>`)

	for i = quote_begins to quote_ends do
		body = "<div>" & body
	end for
	
	for i = quote_ends to quote_begins do
		body &= "</div>"
	end for

	return body
end function

export function format_body(sequence body, integer format_quotes=1)
	body = creole_parse(body, routine_id("generate_html"), "0")
	body = search:find_replace("&amp;#", body, "&#")
	if format_quotes then
		--body = markup_quotes(body)
		body = markup_quotes_two(body)
	end if

	for i = 1 to length(smilies) by 2 do
		body = search:find_replace(smilies[i], body, smilies[i+1])
	end for

	return body
end function
