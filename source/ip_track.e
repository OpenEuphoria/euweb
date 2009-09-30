--
-- Track IPs and deny if requests are greater than 10 a second.
-- 

include edbi/edbi.e
include std/sequence.e
include std/io.e

-- request_count = 10, in_seconds = 5
-- 
-- This means that if 10 requests are made with in a 5 second interval, the IP is 
-- placed on a ban list. Currently this is for the same page.

constant request_count = 10, in_seconds = 5

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
    WHERE request_date > TIMESTAMPADD(SECOND, %d, NOW()) AND ip=%s AND url=%s`, { 
        (-in_seconds), remote_addr, request })
if count > request_count then
    sequence htaccess = read_lines(".htaccess")
    integer i = 1
    
    while i < length(htaccess) do
        if equal("#IP_BAN_LIST", htaccess[i]) then
            sequence ban_cond = sprintf("RewriteCond %%{REMOTE_ADDR} ^%s [OR]", { 
                replace_all(remote_addr, ".", "\\.") })
            htaccess = insert(htaccess, ban_cond, i + 1)
            exit
        end if
        i += 1
    end while

    write_lines(".htaccess", htaccess)

    printf(1, "Content-Type: text/plain\n\nBye: %s %d", { remote_addr, count })
    abort(1)
end if
