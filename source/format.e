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
	{"NEWS",		"http://openeuphoria.org/news/view.wc?id="},
	{"SVN", 		"http://rapideuphoria.svn.sourceforge.net/viewvc/rapideuphoria?view=rev&revision="}
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


function match_prev(sequence needle, sequence haystack, integer whence)
	if whence <= 0 then
		return 0
	end if
	
	if whence > length(haystack) then
		whence = length(haystack)
	end if
	
	while whence >= length(needle) do
		if equal(haystack[whence .. whence + length(needle) - 1], needle) then
			return whence
		end if
		
		whence -= 1
	end while
	
	return 0
end function

function markup_quotes(sequence text)
 	integer ppos
 	integer cspos
 	integer ospos
 	integer oepos
 	integer nextpos = 1
 	integer namepos
 	integer nameend 
 	integer inname
	integer diff

	while 1 do
		cspos = match_from("[/quote]", text, nextpos)
		if cspos then
			ppos = match_from("</p>", text, cspos+8)
			if ppos <= cspos + 9 then
				diff = (ppos + 3 - (cspos + 8)) + 1
				text[cspos .. ppos + 3] = text[cspos + 8 .. ppos + 3] & text[cspos .. cspos + 7]
				cspos += diff
			end if

			ospos = match_prev("[quote", text, cspos - 1)
			
			if ospos then
				oepos = ospos + 6
				
				-- Look back to see if we have <p>
				ppos = ospos-3
				while ppos >= 1 do
					if equal(text[ppos..ppos+2], "<p>") then
						exit
					elsif text[ppos] = '\n' then
						ppos = 0
						exit
					end if
					ppos -= 1
				end while
				
				inname = 0
				nameend = 0
				-- scan for the close of this quote-open tag
				while oepos <= length(text) do
					if text[oepos] = ']' then
						exit
					end if
					
					if text[oepos] = '\n' then
						-- should not happen in valid code.
						-- assume that the closing bracket was missing
						-- so assume it should be right here.
						oepos -= 1
						nameend = oepos
						exit
					end if
					
					if text[oepos] = '[' then
						-- should not happen in valid code.
						-- assume that the closing bracket was missing
						-- so go back to start of tag and pretend missing
						-- bracket is after the first word in the tag.
						oepos = ospos + 6
						inname = 0
						while oepos <= length(text) do
							if find(text[oepos] , " \t") then
								if inname then
									oepos -= 1
									nameend = oepos
									exit	
								end if
							else
								if not inname then
									inname = 1
									namepos = oepos
								end if
							end if
							oepos += 1
						end while
						if oepos > length(text) then
							oepos = length(text)
						end if
						exit
					end if
					
					if not inname then
						if not find(text[oepos], " \t") then
							inname = 1
							namepos = oepos
						end if
					end if
					oepos += 1
				end while
				
				if inname then
					if nameend = 0 then
						nameend = oepos - 1
					end if
				end if
		
				if ppos >= 1 then
					diff = (ospos - ppos)
					text[ppos .. oepos] = text[ospos .. oepos] & text[ppos .. ospos - 1]
					oepos = oepos - diff
					namepos = namepos - diff
					nameend = nameend - diff
					ospos = ppos
					ppos = 0
				end if		
				
				-- Replace end quote
				text = text[1 .. cspos - 1] & "</div>" & text[ cspos + 8  .. $]
				
				-- Replace start quote
				if inname then
					text = text[1..ospos-1] & "<div class=\"quote\"><strong>" & 
					       text[namepos .. nameend] & " </strong>said:<br />" & 
					       text[oepos + 1 .. $]
					nextpos = ospos + 27 + 21 + nameend - namepos + 1
				else
					text = text[1..ospos-1] & "<div class=\"quote:\"><strong>quote</strong><br />" & 
					       text[oepos + 1 .. $]
					nextpos = ospos + 48
				end if
			else
				-- No matching open quote to this close quote
				-- so just ignore the close quote.
				text = text[1 .. cspos - 1] & text[ cspos + 8  .. $]
			end if
		else
			-- No close quote found.
			-- so ignore any open quotes in text.
			exit
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
		--body = markup_quotes_two(body)
	end if

	for i = 1 to length(smilies) by 2 do
		body = search:find_replace(smilies[i], body, smilies[i+1])
	end for

	return body
end function
