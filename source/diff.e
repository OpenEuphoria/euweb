-- ======== EUWEB COMMENT ========
--
-- This code was found in The Archive. It was originally used as a 
-- stand alone program. It has been modified for EuWEB to be used
-- as a library function.
--
-- The original source can be found on the archive as:
--
-- http://www.rapideuphoria.com/diff.zip
--
-- The chosen algorithm was diff21.ex
--
-- ======== END OF EUWEB COMMENT ========
--
-- Program to show the differences between two text files.
-- Author: R. M. Forno - Version 2.1 - 2002/07/15.
--
-- This program does not guarantee that an optimal output will be generated
-- (optimal in the sense of maximizing the number of matched lines),
-- but this optimal will be attained in about 99% of the practical cases.
-- The sub-optimal solutions will be usually very good, too.
-- Version 1 guarantees an optimal solution, at the price of
-- running nearly forever in many cases, when using the bbacktracking
-- algorithm option.
-- This version, rather than maximize the number of matched lines, tries
-- that the matching groups have maximum length, which is more practical
-- for the user.
-- This version is usually slower than Version 1 when no backtracking is
-- specified (in Version 1).
--
-- The matching of lines is done on the basis of strict equality.
-- But the user has the option of changing this by providing his/her
-- own comparison function.
-- The include file compare.e contains the function custom_compare,
-- that merely calls the standard compare function. The user may
-- provide a different custom_compare function, for example to
-- disregard heading blanks, or case of letters, etc. The only
-- place to make this modification is the compare.e include file.
--
-- Versions 3.0 and 4.0 use slightly different algorithms.

function custom_compare(object a, object b)
	return compare(a,b)
end function

sequence s, t, s1, t1, s2, t2, s3, t3, sl, tl

function GradeUp1(sequence s, integer n)
	--This function is a merge sort of the Von Neumann kind, that is, 
	-- first generates variable length sequences and then merges them.
	--While it is more complex than the merge sort provided in EUPHORIA
	-- demo ALLSORTS, it has some advantages:
	--1) According to the argument n being zero or not zero, it respectively
	-- gives the indexes of the sorted elements of s or the elements themselves.
	-- The sorted indexes are useful when one sorts by a key but wants
	-- to sort the remaining data, that for example resides in a "parallel"
	-- sequence. You can see an example of that use in the IndexOf routine
	-- that follows.
	--2) This sort is faster than most sorts in demo ALLSORTS for RANDOM data.
	-- Its performance is approximately equal to the stardard sort provided
	-- with EUPHORIA (Shell sort). However, its main advantage is being MUCH
	-- FASTER than most sorts for data that is nearly ordered, either in NORMAL
	-- or REVERSE order, or in large chunks of data ordered both ways.
	--3) It is stable, that is, it preserves the original order between
	-- equal elements. Some of the other sorts are not stable (quick_sort,
	-- for example). This is not important if the output consists in the
	-- elements themselves, but it matters if the output consists in the
	-- indexes.
	--This is a modification of GradeUp from genfunc.e for use with a
	-- custom_compare function.
    sequence z, r, w, t
    object low, high, temp, one, two
    integer len, m, k, g, h, f, a, b, mid, indz, indr, indt, indw, len1
    len = length(s)
    if len <= 1 then
		if n then
			return s
		else
			return repeat(1, len)
		end if
    end if
    indz = 1
    z = repeat(0, len)
    mid = len - 1
    indr = 0
    r = repeat(0, mid) --Indexes of developed data sequences
    t = repeat(0, len + mid) --Work area for developing sequences
    m = 1
    while m <= len do --Develop ordered data sequences from the input
		indr += 1
		low = s[m]
		high = low
		t[len] = m
		a = len
		b = len
		while m < len do
			m += 1
			temp = s[m]
			if custom_compare(temp, high) >= 0 then --Data in normal order
				b += 1
				t[b] = m
				high = temp
			elsif custom_compare(temp, low) < 0 then --Data in reverse order
				a -= 1
				t[a] = m
				low = temp
			else --End of sequenced data
				m -= 1
				exit
			end if
		end while
		z[indz..m] = t[a..b] --Add sequence to result
		m += 1
		indz = m
		r[indr] = m
    end while
    if indr <= 1 then --If only one data sequence developed
		if n then
			for i = 1 to len do
				z[i] = s[z[i]]
			end for
		end if
		return z
    end if
    len1 = len + 1
    r = r[1..indr]
    t = r
    w = z
    while 1 do --Start merge process
		indw = 0
		indt = 0
		k = 1 --First bound
		for i = 2 to indr by 2 do --Merge pairs of data sequences
			g = r[i - 1]
			h = r[i]
			f = g
			a = z[k]
			one = s[a]
			b = z[g]
			two = s[b]
			while 1 do --Merge two data sequences
				indw += 1
				if custom_compare(one, two) <= 0 then
					w[indw] = a
					k += 1
					if k >= f then
						exit
					end if
					a = z[k]
					one = s[a]
				else
					w[indw] = b
					g += 1
					if g >= h then
						exit
					end if
					b = z[g]
					two = s[b]
				end if
			end while
			--Both conditions cannot hold true at the same time
			if k < f then
				indw += 1
				f -= 1
				b = indw + f - k
				w[indw..b] = z[k..f] --Remainder of first data sequence
				indw = h - 1
			elsif g < h then
				indw = h - 1
				w[g..indw] = z[g..indw] --Remainder of second data sequence
			end if
			indt += 1
			t[indt] = h
			k = h --First bound = previous last bound
		end for
		if and_bits(1, indr) then --Orphaned last data sequence
			w[k..len] = z[k..len]
			indt += 1
			t[indt] = len1
		end if
		if indt <= 1 then --If only one data sequence remains
			if n then
				for i = 1 to len do
					w[i] = s[w[i]]
				end for
			end if
			return w
		end if
		r = t[1..indt]
		indr = indt
		z = w
    end while
end function

function GradeUp(sequence s, integer n)
	--This function is a merge sort of the Von Neumann kind, that is, 
	-- first generates variable length sequences and then merges them.
	--While it is more complex than the merge sort provided in EUPHORIA
	-- demo ALLSORTS, it has some advantages:
	--1) According to the argument n being zero or not zero, it respectively
	-- gives the indexes of the sorted elements of s or the elements themselves.
	-- The sorted indexes are useful when one sorts by a key but wants
	-- to sort the remaining data, that for example resides in a "parallel"
	-- sequence. You can see an example of that use in the IndexOf routine
	-- that follows.
	--2) This sort is faster than most sorts in demo ALLSORTS for RANDOM data.
	-- Its performance is approximately equal to the stardard sort provided
	-- with EUPHORIA (Shell sort). However, its main advantage is being MUCH
	-- FASTER than most sorts for data that is nearly ordered, either in NORMAL
	-- or REVERSE order, or in large chunks of data ordered both ways.
	--3) It is stable, that is, it preserves the original order between
	-- equal elements. Some of the other sorts are not stable (quick_sort,
	-- for example). This is not important if the output consists in the
	-- elements themselves, but it matters if the output consists in the
	-- indexes.
	--This is the original GradeUp function from genfunc.e.
    sequence z, r, w, t
    object low, high, temp, one, two
    integer len, m, k, g, h, f, a, b, mid, indz, indr, indt, indw, len1
    len = length(s)
    if len <= 1 then
		if n then
			return s
		else
			return repeat(1, len)
		end if
    end if
    indz = 1
    z = repeat(0, len)
    mid = len - 1
    indr = 0
    r = repeat(0, mid) --Indexes of developed data sequences
    t = repeat(0, len + mid) --Work area for developing sequences
    m = 1
    while m <= len do --Develop ordered data sequences from the input
		indr += 1
		low = s[m]
		high = low
		t[len] = m
		a = len
		b = len
		while m < len do
			m += 1
			temp = s[m]
			if compare(temp, high) >= 0 then --Data in normal order
				b += 1
				t[b] = m
				high = temp
			elsif compare(temp, low) < 0 then --Data in reverse order
				a -= 1
				t[a] = m
				low = temp
			else --End of sequenced data
				m -= 1
				exit
			end if
		end while
		z[indz..m] = t[a..b] --Add sequence to result
		m += 1
		indz = m
		r[indr] = m
    end while
    if indr <= 1 then --If only one data sequence developed
		if n then
			for i = 1 to len do
				z[i] = s[z[i]]
			end for
		end if
		return z
    end if
    len1 = len + 1
    r = r[1..indr]
    t = r
    w = z
    while 1 do --Start merge process
		indw = 0
		indt = 0
		k = 1 --First bound
		for i = 2 to indr by 2 do --Merge pairs of data sequences
			g = r[i - 1]
			h = r[i]
			f = g
			a = z[k]
			one = s[a]
			b = z[g]
			two = s[b]
			while 1 do --Merge two data sequences
				indw += 1
				if compare(one, two) <= 0 then
					w[indw] = a
					k += 1
					if k >= f then
						exit
					end if
					a = z[k]
					one = s[a]
				else
					w[indw] = b
					g += 1
					if g >= h then
						exit
					end if
					b = z[g]
					two = s[b]
				end if
			end while
			--Both conditions cannot hold true at the same time
			if k < f then
				indw += 1
				f -= 1
				b = indw + f - k
				w[indw..b] = z[k..f] --Remainder of first data sequence
				indw = h - 1
			elsif g < h then
				indw = h - 1
				w[g..indw] = z[g..indw] --Remainder of second data sequence
			end if
			indt += 1
			t[indt] = h
			k = h --First bound = previous last bound
		end for
		if and_bits(1, indr) then --Orphaned last data sequence
			w[k..len] = z[k..len]
			indt += 1
			t[indt] = len1
		end if
		if indt <= 1 then --If only one data sequence remains
			if n then
				for i = 1 to len do
					w[i] = s[w[i]]
				end for
			end if
			return w
		end if
		r = t[1..indt]
		indr = indt
		z = w
    end while
end function

function GenInd1(sequence s, sequence t)
	--Generate a sequence of two sequences mimicking the original sequences s & t
	-- with respect to comparisons for equality, but consisting only of
	-- integers, in order to diminish processing time.
	--This variant uses custom_compare.
    sequence x, ind, r, p, z
    integer len, lens, lent, k, d
    lens = length(s)
    lent = length(t)
    len = lens + lent
    if len = 0 then
		return {}
    end if
    x = s & t --Form composite sequence
    ind = GradeUp1(x, 0) --Generate index vector
    p = repeat(0, len)
    k = 1
    d = ind[1]
    r = x[d]
    p[d] = k
    for i = 2 to len do --Look for repeated sub-sequences
		d = ind[i]
		z = x[d]
		if custom_compare(z, r) != 0 then
			k += 1
			r = z
		end if
		p[d] = k
    end for
    return {p[1..lens], p[lens + 1..len]}
end function

function GenInd(sequence s, sequence t)
	--Generate a sequence of two sequences mimicking the original sequences s & t
	-- with respect to comparisons for equality, but consisting only of
	-- integers, in order to diminish processing time.
	--This variant uses standard compare.
    sequence x, ind, r, p, z
    integer len, lens, lent, k, d
    lens = length(s)
    lent = length(t)
    len = lens + lent
    if len = 0 then
		return {}
    end if
    x = s & t --Form composite sequence
    ind = GradeUp(x, 0) --Generate index vector
    p = repeat(0, len)
    k = 1
    d = ind[1]
    r = x[d]
    p[d] = k
    for i = 2 to len do --Look for repeated sub-sequences
		d = ind[i]
		z = x[d]
		if not equal(z, r) then
			k += 1
			r = z
		end if
		p[d] = k
    end for
    return {p[1..lens], p[lens + 1..len]}
end function

function MaxMatchGroup(sequence s1, sequence t1)
	--Search for the maximum length grouping of elements.
    sequence old, new, best
    integer lens, lent, lenb, k, ns, nt
    object a, b
    lens = length(s1)
    lent = length(t1)
    lenb = 0
    best = {lenb, 0, 0} --Initialize best grouping
    new = {} --To avoid searching when no improvement is possible
    for i = 1 to lens do
		a = s1[i]
		old = new
		new = {}
		if atom(a) then --Disregard previous groupings
			for j = 1 to lent do
				b = t1[j]
				if equal(a, b) then
					if j < lent then
						if i < lens then
							if equal(s1[i + 1], t1[j + 1]) then
								new &= j --Prepare already-done test
							end if
						end if
					end if
					if not find(j - 1, old) then --Not previously done
						k = 1
						while 1 do --Determine group
							ns = i + k
							if ns > lens then
								exit
							end if
							nt = j + k
							if nt > lent then
								exit
							end if
							if not equal(s1[ns], t1[nt]) then
								exit
							end if
							k += 1
						end while
						if k > lenb then --Update best grouping
							lenb = k
							best = {lenb, i, j}
						end if
					end if
				end if
			end for
		end if
    end for
    return best
end function

function NonMatchGroup(sequence s)
	--Group non-matching elements
    sequence r, p
    object a
    integer k, len
    len = length(s)
    k = 1
    r = {}
    while k <= len do
		a = s[k]
		if atom(a) then
			p = {a}
			k += 1
			while k <= len do
				a = s[k]
				if atom(a) then
					p &= a
				else
					exit
				end if
				k += 1
			end while
			r = append(r, p)
		else
			r = append(r, a)
			k += 1
		end if
    end while
    return r
end function

function MatchGroup(sequence s1, sequence t1)
	--Group elements in descending order of group lengths.
    integer len, a, b
    sequence best
    while 1 do --Search for groups
		best = MaxMatchGroup(s1, t1)
		len = best[1]
		if len = 0 then
			exit
		end if
		a = best[2]
		b = best[3]
		s1 = s1[1..a - 1] & {s1[a..a + len - 1]} & s1[a + len..length(s1)]
		t1 = t1[1..b - 1] & {t1[b..b + len - 1]} & t1[b + len..length(t1)]
    end while
    --Group non-matching elements
    s1 = NonMatchGroup(s1)
    t1 = NonMatchGroup(t1)
    return {s1, t1}
end function

function GetLengths(sequence s)
	--Returns the lengths of the subsequences in s.
    sequence r
    integer len
    len = length(s)
    r = repeat(0, len)
    for i = 1 to len do
		r[i] = length(s[i])
    end for
    return r
end function

function BestMatch(sequence s3, sequence t3, sequence sl,
		sequence is, sequence it)
	--Matches the reduced sequences and returns the best list of index pairs.
    integer count, best_count, lens, lent, d, i1, j1
    sequence pairs, best_pairs, x, y
    lens = length(s3)
    lent = length(t3)
    best_pairs = {}
    best_count = 0
    for i = 1 to lens do
		d = s3[i]
		i1 = i + 1
		for j = 1 to lent do
			if t3[j] = d then --Match found
				x = BestMatch(s3[1..i - 1], t3[1..j - 1], sl, is, it)
				--No need to slice sl, is, it
				j1 = j + 1
				y = BestMatch(s3[i1..lens], t3[j1..lent], sl[i1..lens],
					is[i1..lens], it[j1..lent])
				pairs = x[2..length(x)] & {{is[i], it[j]}} & y[2..length(y)]
				count = sl[i] + x[1] + y[1]
				if count > best_count then --Update best results
					best_count = count
					best_pairs = pairs
				end if
			end if
		end for
    end for
    return best_count & best_pairs
end function

public enum 
--**
-- Unchanged line
UNCHANGED, 
--**
-- Inserted line
INSERTED, 
--**
-- Removed line
REMOVED

--
-- Instead of outputting to the screen, make a sequence
-- of the changes. Difference will return this.
--
-- { { CHANGE_TYPE, LINE_TEXT }, ... }
--

function Changes(sequence best_pairs)
	--Ouput resulting in, out, and equal lines.
    sequence x, result = {}
    integer a, b, u, v, z, zs, zt
    a = 1
    b = 1
    zs = 1
    zt = 1
    for i = 1 to length(best_pairs) do
		x = best_pairs[i]
		u = x[1]
		v = x[2]
		z = 0
		for j = a to u - 1 do
			z += sl[j]
		end for
		for j = zs to zs + z - 1 do
			result = append(result, { INSERTED, s[j] })
		end for
		zs += z
		z = 0
		for j = b to v - 1 do
			z += tl[j]
		end for
		for j = zt to zt + z - 1 do
			result = append(result, { REMOVED, t[j] })
		end for
		zt += z
		z = sl[u]
		for j = zs to zs + z - 1 do
			result = append(result, { UNCHANGED, s[j] })
		end for
		zs += z
		zt += z
		a = u + 1
		b = v + 1
    end for
    for j = zs to length(s) do
		result = append(result, { INSERTED, s[j] })
    end for
    for j = zt to length(t) do
		result = append(result, { REMOVED, t[j] })
    end for
	return result
end function

function InvertPairs(sequence p)
    for i = 1 to length(p) do
		p[i] = {p[i][2], p[i][1]}
    end for 
    return p
end function

function GenIndex(integer len)
    sequence s
    s = repeat(0, len)
    for i = 1 to len do
		s[i] = i
    end for
    return s
end function

--**
-- Compute the differences between `ss` and `tt`. 
--
-- Parameters:
--   * ss - a sequence of lines { line1, line2, ... }
--   * tt - a sequence of lines { line1, line2, ... }
--
-- Returns:
--   A sequence of changes.
--
--   <eucode>
--   {
--     { CHANGE_TYPE, LINE_TEXT },
--     { CHANGE_TYPE, LINE_TEXT },
--     ...
--   }
--   </eucode>
--
-- See Also:
--   [[:INSERTED]], [[:REMOVED]], [[:UNCHANGED]]
--

public function Difference(sequence ss, sequence tt)
	--Main procedure.
    sequence best_pairs, s3p, t3p, slp, tlp, p, is, it
    integer best_count, count
    object option = 0
	s = ss
	t = tt
    p = GenInd1(s, t) --To decrease processing time
    s1 = p[1]
    t1 = p[2]
    p = MatchGroup(s1, t1) --Groups matching elements
    s2 = p[1]
    t2 = p[2]
    p = GenInd(s2, t2) --Also, to decrease processing time
    s3 = p[1]
    t3 = p[2]
    is = GenIndex(length(s3))
    it = GenIndex(length(t3))
    sl = GetLengths(s2) --Lengths, to be added up for evaluating performance
    tl = GetLengths(t2)
    p = BestMatch(s3, t3, sl, is, it)
    best_count = p[1]
    best_pairs = p[2..length(p)]
    p = MatchGroup(t1, s1) --Try the inverse
    s2 = p[2]
    t2 = p[1]
    p = GenInd(t2, s2)
    s3p = p[2]
    t3p = p[1]
    is = GenIndex(length(s3p))
    it = GenIndex(length(t3p))
    slp = GetLengths(s2)
    tlp = GetLengths(t2)
    p = BestMatch(t3p, s3p, tlp, it, is)
    count = p[1]
    if count > best_count then
		best_pairs = InvertPairs(p[2..length(p)])
		sl = slp
		tl = tlp
		s3 = s3p
		t3 = t3p
    end if
	return Changes(best_pairs)
end function

------END OF FILE------
