--
-- Add and populate the field last_edit_at
-- 

ALTER TABLE messages ADD COLUMN last_edit_at datetime;
UPDATE messages SET last_edit_at=created_at;
