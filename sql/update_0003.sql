--
-- Add and populate the field last_edit_at
-- 

ALTER TABLE messages ADD COLUMN last_edit_at datetime;
UPDATE messages SET last_edit_at=created_at;

--
-- Index well for the topic list, our slowest part of the whole system
-- 

CREATE INDEX topic_list ON messages(last_post_at, parent_id);
