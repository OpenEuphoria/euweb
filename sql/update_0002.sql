--
-- Update the messages table to contain a topic id
-- 

ALTER TABLE messages ADD COLUMN topic_id integer not null default 0;
