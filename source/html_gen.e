include std/text.e
include std/search.e

constant kHTML = {
				{"&", "&amp;"},
				{"<", "&lt;"},
				{">", "&gt;"}
	}

with trace
------------------------------------------------------------------------------
global function html_generator(integer pAction, sequence pParms, object pContext = "")
------------------------------------------------------------------------------
	sequence lHTMLText
	sequence lSuffix
	sequence lNumText
	integer lPos

	lHTMLText = ""

	switch pAction do

		case InternalLink then
			if find('.', pParms[1]) = 0 then
				lSuffix = ".html"
			else
				lSuffix = ""
			end if
			lHTMLText = "<a href=\"" & pParms[1] & lSuffix & "\">" & pParms[2] & "</a>"

		case QualifiedLink then
			if find('.', pParms[1]) = 0 then
				lSuffix = ".html"
			else
				lSuffix = ""
			end if
			lHTMLText = "<a href=\"" & pParms[1] & lSuffix & '#' & pParms[2] & "\">" & pParms[3] & "</a>"

		case InterWikiLink then
			lHTMLText = "<font color=\"#FF0000\" background=\"#000000\">Interwiki link failed for "
			for i = 1 to length(pParms) do
				lHTMLText &= pParms[i]
				if i < length(pParms) then
					lHTMLText &= ", "
				end if
			end for
			lHTMLText &= "</font>"

		case NormalLink then
			lHTMLText = "<a class=\"external\" href=\"" & pParms[1] & "\">" &
							pParms[2] & "</a>"

		case InternalImage then

			lHTMLText = "<img src=\"" & pParms[1] & 
						"\" alt=\"" & pParms[2] & 
						"\" caption=\"" & pParms[2] & 
						"\" />"

		case InterWikiImage then
			lHTMLText = "<font color=\"#FF0000\" background=\"#000000\">Interwiki image failed for "
			for i = 1 to length(pParms) do
				lHTMLText &= pParms[i]
				if i < length(pParms) then
					lHTMLText &= ", "
				end if
			end for
			lHTMLText &= "</font>"

		case NormalImage then
			lHTMLText = "<img src=\"" & pParms[1] & 
						"\" alt=\"" & pParms[2] & 
						"\" caption=\"" & pParms[2] & 
						"\" />"

		case Paragraph then
			lHTMLText = "\n<p>" & pParms & "</p>\n"

		case Division then
			lHTMLText = "\n<div class=\"" & pParms[1] & "\">" & pParms[2] & "</div>\n"

		case Bookmark then
			lHTMLText = "<a name=\"" & pParms & "\" ></a>"

		case OrderedList then
			lHTMLText = "<ol>" & pParms & "</ol>"

		case UnorderedList then
			lHTMLText = "<ul>" & pParms & "</ul>"

		case ListItem then
			lHTMLText = "<li>" & pParms & "\n</li>"

		case Heading then
			lNumText = sprintf("%d", pParms[1])
			lHTMLText = "\n<h" & lNumText & ">" & trim(pParms[2]) & "</h" & lNumText & ">"

		case ItalicText then
			lHTMLText = "<em>" & pParms[1] & "</em>"

		case BoldText then
			lHTMLText = "<strong>" & pParms[1] & "</strong>"

		case MonoText then
			lHTMLText = "<tt>" & pParms[1] & "</tt>"

		case UnderlineText then
			lHTMLText = "<u>" & pParms[1] & "</u>"

		case Superscript then
			lHTMLText = "<sup>" & pParms[1] & "</sup>"

		case Subscript then
			lHTMLText = "<sub>" & pParms[1] & "</sub>"

		case StrikeText then
			lHTMLText = "<del>" & pParms[1] & "</del>"

		case InsertText then
			lHTMLText = "<ins>" & pParms[1] & "</ins>"

		case ColorText then
			lHTMLText = "<span style=\"color:" & pParms[1] & ";\">" & pParms[2] & "</span>"

		case CodeExample then
			lHTMLText = "\n<pre class=\"examplecode\">" & pParms[1] &  "</pre>\n"

		case TableDef then
			lHTMLText = "<table>" & pParms[1] & "</table>\n"

		case HeaderRow then
			lHTMLText = "<tr>" & pParms[1] & "</tr>\n"

		case HeaderCell then
			lHTMLText = "<th>" & pParms[1] & "</th>\n"

		case NormalRow then
			lHTMLText = "<tr>" & pParms[1] & "</tr>\n"

		case NormalCell then
			lHTMLText = "<td>" & pParms[1] & "</td>\n"

		case NonBreakSpace then
			lHTMLText = "&nbsp;"

		case ForcedNewLine then
			lHTMLText = "<br />\n"

		case HorizontalLine then
			lHTMLText = "\n<hr />\n"

		case NoWikiBlock then
			lHTMLText = "\n<pre>" & pParms[1] & "</pre>\n"

		case NoWikiInline then
			lHTMLText = pParms[1]

		case HostID then
			lHTMLText = ""

		case OptReparseHeadings then
			lHTMLText = ""

		case DefinitionList then
			lHTMLText = "<dl>\n"
			for i = 1 to length(pParms) do
				lHTMLText &= "<dt>" & pParms[i][1] & 
							"\n</dt>\n<dd>" & pParms[i][2] & 
							"</dd>\n"
			end for
			lHTMLText &= "</dl>\n"

		case BeginIndent then
			lHTMLText = "<div style=\"margin-left:2em\">"
			
		case EndIndent then
			lHTMLText = "</div>"
			
		case PassThru then
			lHTMLText = pParms
			for i = 1 to length(kHTML) do
				lHTMLText = match_replace(kHTML[i][1], lHTMLText, kHTML[i][2])
			end for
			if not equal(pParms, lHTMLText) then
				lHTMLText = "<div class=\"passthru\">" & lHTMLText & "</div>"
			end if
			
		case Sanitize then
			lHTMLText = pParms
			for i = 1 to length(kHTML) do
				lHTMLText = match_replace(kHTML[i][1], lHTMLText, kHTML[i][2])
			end for
		
		case CamelCase then
			lHTMLText = {lower(pParms[1])}
			for i = 2 to length(pParms) do
				if upper(pParms[i]) = pParms[i] then
					lHTMLText &= ' '
					lHTMLText &= lower(pParms[i])
				else
					lHTMLText &= pParms[i]
				end if
			end for
			
		case Plugin then
		-- Extract the key/values, but don't parse for quoted text nor whitespace delims.
			pParms = keyvalues(pParms[1], -1, -2, "", "")
			lHTMLText = "--**Unknown plugin '" & pParms[1][2] & "'"

		case Document then
			-- Default action is to ust pass back the document text untouched.
			lHTMLText = pParms[1]
									
		case ContextChange then
			-- Record the context change in the output document
			if length(pParms) > 0 then
				lHTMLText = "\n<!-- " & pParms & " -->\n"
			end if
									
		case Comment then
			-- Record a comment in the output document
			if length(pParms) > 0 then
				lHTMLText = "\n<!-- " & pParms & " -->\n"
			end if
									
		case Quoted then
			-- Highlight a quoted section.
			if length(pParms[2]) > 0 then
				lHTMLText = "\n<div class=\"quote\">quote: <strong>" &
							pParms[1] &
							"</strong><br />\n" &
							pParms[2] &
							"\n</div>\n"
			end if
									
		case else
			lHTMLText = sprintf("[BAD ACTION CODE %d]", pAction)
			for i = 1 to length(pParms) do
				lHTMLText &= pParms[i]
				lHTMLText &= " "
			end for

	end switch

	lPos = 0
	while lPos != 0 with entry do
		lHTMLText = lHTMLText[1 .. lPos + 6] & "euwiki" & lHTMLText[lPos + 8 .. $]
	  entry
		lPos = match_from("class=\"?", lHTMLText, lPos+1)
	end while

	return lHTMLText
end function
