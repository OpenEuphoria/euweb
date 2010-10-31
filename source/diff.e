include std/sequence.e
include webclay/escape.e as esc

public function html_diff(sequence currpg, sequence oldpg)
	sequence difftxt = {}
	sequence htmlout = {}
	integer cnt = 0
	atom npos = 0
	atom opos = 0
	atom olen
	atom nlen
	
	currpg = split(currpg, '\n')
	oldpg = split(oldpg, '\n')
	
	olen = length(oldpg)
	nlen = length(currpg)
	
	opos = 1
	npos = 1
	
	while opos <= olen do
		cnt += 1
		if cnt = 10000 then
			exit
		end if
		
		if npos <= nlen and equal(oldpg[opos], currpg[npos]) then
			difftxt &= {{'=', oldpg[opos]}}
			opos += 1
			npos += 1       
			
		else
			
			for np = npos + 1 to nlen + 1 do --scan for match (means lines may have been inserted)
				if np <= nlen and equal(oldpg[opos], currpg[np]) then --match found after insertion
					for ad = npos to np-1 do --add inserted text
						difftxt &= {{'+', currpg[ad]}}
					end for
					npos = np
					exit
				end if
				
				if np > nlen then --match not found
					for op = opos + 1 to olen + 1 do --scan for match (means lines may have been deleted)
						if op <= olen and equal(oldpg[op], currpg[npos]) then --match found after deletion
							for rm = opos to op-1 do --add inserted text
								difftxt &= {{'-', oldpg[rm]}}
							end for
							opos = op
							exit
						end if
						
						if op > olen then --match not found (means lines may have been replaced)
							difftxt &= {{'-', oldpg[opos]}}
							difftxt &= {{'+', currpg[npos]}}
							opos += 1
							npos += 1
							exit
						end if
					end for
				end if
				
			end for
			
		end if
		
	end while
	
	if npos < nlen then
		for np = npos to nlen do
			difftxt &= {{'+', currpg[npos]}}
		end for
	end if
	
	htmlout = "<div class=\"pagesrc\">\n"
	for ln = 1 to length(difftxt) do
		if difftxt[ln][1] = '=' then
			htmlout &= htmlspecialchars(difftxt[ln][2]) & "<br>\n"
		elsif difftxt[ln][1] = '+' then
			htmlout &= "<ins class=\"diff\">" & htmlspecialchars(difftxt[ln][2]) & "</ins><br>\n"
		elsif difftxt[ln][1] = '-' then
			htmlout &= "<del class=\"diff\">" & htmlspecialchars(difftxt[ln][2]) & "</del><br>\n"
		end if
	end for
	htmlout &= "</div>\n"
	
	return htmlout
end function
