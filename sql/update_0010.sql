--
-- IP tracking/banning
-- 

CREATE TABLE ip_requests (
	ip varchar(15) not null,
	request_date datetime not null,
	url text
);
CREATE INDEX find_banned ON ip_requests(ip, request_date);
