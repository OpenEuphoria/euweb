include std/text.e
include std/search.e

constant kHTML = {
				{"&", "&amp;"},
				{"<", "&lt;"},
				{">", "&gt;"}
	}

with trace
------------------------------------------------------------------------------
global function html_generator(integer pAction, sequence pParms)
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
			break

		case QualifiedLink then
			if find('.', pParms[1]) = 0 then
				lSuffix = ".html"
			else
				lSuffix = ""
			end if
			lHTMLText = "<a href=\"" & pParms[1] & lSuffix & '#' & pParms[2] & "\">" & pParms[3] & "</a>"
			break

		case InterWikiLink then
			lHTMLText = "<font color=\"#FF0000\" background=\"#000000\">Interwiki link failed for "
			for i = 1 to length(pParms) do
				lHTMLText &= pParms[i]
				if i < length(pParms) then
					lHTMLText &= ", "
				end if
			end for
			lHTMLText &= "</font>"
			break

		case NormalLink then
			lHTMLText = "<a class=\"external\" href=\"" & pParms[1] & "\">" &
							pParms[2] & "</a>"
			break

		case InternalImage then

			lHTMLText = "<img src=\"" & pParms[1] & 
						"\" alt=\"" & pParms[2] & 
						"\" caption=\"" & pParms[2] & 
						"\" />"
			break

		case InterWikiImage then
			lHTMLText = "<font color=\"#FF0000\" background=\"#000000\">Interwiki image failed for "
			for i = 1 to length(pParms) do
				lHTMLText &= pParms[i]
				if i < length(pParms) then
					lHTMLText &= ", "
				end if
			end for
			lHTMLText &= "</font>"
			break

		case NormalImage then
			lHTMLText = "<img src=\"" & pParms[1] & 
						"\" alt=\"" & pParms[2] & 
						"\" caption=\"" & pParms[2] & 
						"\" />"
			break

		case Paragraph then
			lHTMLText = "\n<p>" & pParms & "</p>\n"
			break

		case Division then
			lHTMLText = "\n<div class=\"" & pParms[1] & "\">" & pParms[2] & "</div>\n"
			break

		case Bookmark then
			lHTMLText = "<a name=\"" & pParms & "\" ></a>"
			break

		case OrderedList then
			lHTMLText = "<ol>" & pParms & "</ol>"
			break

		case UnorderedList then
			lHTMLText = "<ul>" & pParms & "</ul>"
			break

		case ListItem then
			lHTMLText = "<li>" & pParms & "\n</li>"
			break

		case Heading then
			lNumText = sprintf("%d", pParms[1])
			lHTMLText = "\n<H" & lNumText & ">" & trim(pParms[2]) & "</H" & lNumText & ">"
			break

		case ItalicText then
			lHTMLText = "<em>" & pParms[1] & "</em>"
			break

		case BoldText then
			lHTMLText = "<strong>" & pParms[1] & "</strong>"
			break

		case MonoText then
			lHTMLText = "<tt>" & pParms[1] & "</tt>"
			break

		case UnderlineText then
			lHTMLText = "<u>" & pParms[1] & "</u>"
			break

		case Superscript then
			lHTMLText = "<sup>" & pParms[1] & "</sup>"
			break

		case Subscript then
			lHTMLText = "<sub>" & pParms[1] & "</sub>"
			break

		case StrikeText then
			lHTMLText = "<del>" & pParms[1] & "</del>"
			break

		case InsertText then
			lHTMLText = "<ins>" & pParms[1] & "</ins>"
			break

		case ColorText then
			lHTMLText = "<font color=\"" & pParms[1] & "\">" & pParms[2] & "</font>"
			break

		case CodeExample then
			lHTMLText = "\n<pre class=\"examplecode\">" & pParms[1] &  "</pre>\n"
			break

		case TableDef then
			lHTMLText = "<table>" & pParms[1] & "</table>\n"

			break

		case HeaderRow then
			lHTMLText = "<tr>" & pParms[1] & "</tr>\n"

			break

		case HeaderCell then
			lHTMLText = "<th>" & pParms[1] & "</th>\n"

			break

		case NormalRow then
			lHTMLText = "<tr>" & pParms[1] & "</tr>\n"

			break

		case NormalCell then
			lHTMLText = "<td>" & pParms[1] & "</td>\n"

			break

		case NonBreakSpace then
			lHTMLText = "&nbsp;"

			break

		case ForcedNewLine then
			lHTMLText = "<br />\n"

			break

		case HorizontalLine then
			lHTMLText = "\n<hr />\n"

			break

		case NoWikiBlock then
			lHTMLText = "\n<pre>" & pParms[1] & "</pre>\n"

			break

		case NoWikiInline then
			lHTMLText = pParms[1]
			break

		case HostID then
			lHTMLText = ""
			break

		case OptReparseHeadings then
			lHTMLText = ""
			break

		case DefinitionList then
			lHTMLText = "<dl>\n"
			for i = 1 to length(pParms) do
				lHTMLText &= "<dt>" & pParms[i][1] & 
							"\n</dt>\n<dd>" & pParms[i][2] & 
							"</dd>\n"
			end for
			lHTMLText &= "</dl>\n"
			
			break
		case BeginIndent then
			lHTMLText = "<div style=\"margin-left:2em\">"
			break
			
		case EndIndent then
			lHTMLText = "</div>"
			break
			
		case PassThru then
			lHTMLText = pParms
			for i = 1 to length(kHTML) do
				lHTMLText = find_replace(kHTML[i][1], lHTMLText, kHTML[i][2])
			end for
			if not equal(pParms, lHTMLText) then
				lHTMLText = "<div class=\"passthru\">" & lHTMLText & "</div>"
			end if
			break
			
			
		case Sanitize then
			lHTMLText = pParms
			for i = 1 to length(kHTML) do
				lHTMLText = find_replace(kHTML[i][1], lHTMLText, kHTML[i][2])
			end for
			break

		
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
			break
			
		case Plugin then
		-- Extract the key/values, but don't parse for quoted text nor whitespace delims.
			pParms = keyvalues(pParms[1], -1, -2, "", "")
			lHTMLText = "**Unknown plugin '" & pParms[1][2] & "'"
			break

		case Document then
			-- Default action is to ust pass back the document text untouched.
			lHTMLText = pParms[1]
			break
									
		case ContextChange then
			-- Record the context change in the output document
			if length(pParms) > 0 then
				lHTMLText = "\n<!-- " & pParms & " -->\n"
			end if
			break
									
		case Comment then
			-- Record a comment in the output document
			if length(pParms) > 0 then
				lHTMLText = "\n<!-- " & pParms & " -->\n"
			end if
			break
									
		case else
			lHTMLText = sprintf("[BAD ACTION CODE %d]", pAction)
			for i = 1 to length(pParms) do
				lHTMLText &= pParms[i]
				lHTMLText &= " "
			end for
			break
	end switch

	lPos = 0
	while lPos != 0 with entry do
		lHTMLText = lHTMLText[1 .. lPos + 6] & "euwiki" & lHTMLText[lPos + 8 .. $]
	  entry
		lPos = match_from("class=\"?", lHTMLText, lPos+1)
	end while

	return lHTMLText
end function
