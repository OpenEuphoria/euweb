--
-- Add a user create date/time field
--

ALTER TABLE users ADD COLUMN created_at DATETIME AFTER id;

-- Date we went live with euweb
UPDATE users SET created_at = '2008-07-21 05:53:32';

