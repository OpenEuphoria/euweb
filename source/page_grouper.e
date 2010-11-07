--
-- Group a list of pages into a sequence of sequences grouped by
-- the first letter in the page name as well as in 3 columns
--

include std/math.e
include std/text.e

public function assemble_page_list(object page_list)
	sequence new_page_list = {}

	if sequence(page_list) then
		integer num_of_pages = length(page_list)

		-- Resulting data:
		-- { group1, group2, ... }
		--
		-- Groups:
		--
		-- { { heading, pages }, { heading, pages }, ... }

		if num_of_pages < 30 then
			new_page_list = { { { 0, page_list } } }
		else
			integer per_col = ceil(num_of_pages / 3)
			integer last_group = 0, last_col_group = 0
			integer pgidx = 0

			for i = 1 to 3 do
				sequence page_group = {}
				sequence pages = {}

				for j = 1 to per_col do
					pgidx += 1

					if pgidx > num_of_pages then
						exit
					end if

					sequence p = page_list[pgidx]
					if length(p[1]) = 0 then
						p[1] = "#"
					end if
					if last_group != upper(p[1][1]) or
						(j = 1 and last_group = last_col_group)
					then
						last_group = upper(p[1][1])
						page_group = append(page_group, { last_group, {}, 
								j=1 and last_group = last_col_group })
					end if

					page_group[$][2] = append(page_group[$][2], p)
				end for

				new_page_list = append(new_page_list, page_group)
				last_col_group = last_group
			end for
		end if
	end if

	return new_page_list
end function
