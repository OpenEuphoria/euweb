--
-- Update user for additional profile values
-- 

ALTER TABLE users ADD COLUMN name VARCHAR(80);
ALTER TABLE users ADD COLUMN location VARCHAR(128);
ALTER TABLE users ADD COLUMN forum_default_view TINYINT DEFAULT 1;
ALTER TABLE users ADD COLUMN show_email TINYINT DEFAULT 0;
