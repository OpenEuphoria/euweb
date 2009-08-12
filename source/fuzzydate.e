include std/get.e
include std/sequence.e
include std/text.e
include std/datetime.e as dt

constant SECS_PER_MINUTE=60, SECS_PER_HOUR=SECS_PER_MINUTE*60,
         SECS_PER_DAY=SECS_PER_HOUR*24, SECS_PER_WEEK=SECS_PER_DAY*7,
         SECS_PER_MONTH=SECS_PER_DAY*30, SECS_PER_YEAR=SECS_PER_DAY*365

public function fuzzyDateDiff(dt:datetime d1, dt:datetime d2)
    object sd, tmp
    sequence f

    sd = dt:diff(d1, d2)
    f = ""

    if sd > SECS_PER_YEAR then
        tmp = floor(sd / SECS_PER_YEAR)
        f &= sprint(tmp) & " year"
    elsif sd > SECS_PER_MONTH then
        tmp = floor(sd / SECS_PER_MONTH)
        f &= sprint(tmp) & " month"
    elsif sd > SECS_PER_WEEK then
        tmp = floor(sd / SECS_PER_WEEK)
        f &= sprint(tmp) & " week"
    elsif sd > SECS_PER_DAY then
        tmp = floor(sd / SECS_PER_DAY)
        f &= sprint(tmp) & " day"
    elsif sd > SECS_PER_HOUR then
        tmp = floor(sd / SECS_PER_HOUR)
        f &= sprint(tmp) & " hour"
    elsif sd > SECS_PER_MINUTE then
        tmp = floor(sd / SECS_PER_MINUTE)
        f &= sprint(tmp) & " minute"
    elsif sd > 0 then
        tmp = sd
        f &= sprint(sd) & " second"
    else
        tmp = 0
        f = "0 seconds"
    end if

    if tmp > 1 then
        f &= "s"
    end if

    return f
end function

public function fuzzy_ago(dt:datetime d1)
	if d1[YEAR] = 0 then
		return "never"
	end if

	return fuzzyDateDiff(d1, dt:now()) & " ago"
end function

