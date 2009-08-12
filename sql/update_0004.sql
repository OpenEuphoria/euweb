--
-- Add the ip address column that the user was last logged in as
-- 

ALTER TABLE users ADD COLUMN ip_addr VARCHAR(32);
