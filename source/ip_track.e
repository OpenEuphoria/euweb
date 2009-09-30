--
-- Track IPs and deny if requests are greater than 10 a second.
-- 

include edbi/edbi.e

-- request_count = 10, in_seconds = 5
-- 
-- This means that if 10 requests are made with in a 5 second interval, the IP is 
-- placed on a ban list.

constant request_count = 20, in_seconds = 5

-- Record our request via IP

sequence request = sprintf("[%s] %s?%s", { getenv("REQUEST_METHOD"), getenv("SCRIPT_NAME"),
    getenv("QUERY_STRING") })

object remote_addr = getenv("REMOTE_ADDR")
if atom(remote_addr) then
    remote_addr = "UNKNOWN"
end if

edbi:execute("INSERT INTO ip_requests (request_date, ip, url) VALUES (NOW(), %s, %s)", { 
    remote_addr, request })

object count = edbi:query_object(`SELECT COUNT(ip) FROM ip_requests 
    WHERE request_date > TIMESTAMPADD(SECOND, %d, NOW()) AND ip=%s`, { (-in_seconds), remote_addr })
if count > request_count then
    printf(1, "Content-Type: text/plain\n\nBye: %s %d", { remote_addr, count })
    abort(1)
end if
