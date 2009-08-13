--
-- Update user security system
-- 

ALTER TABLE users ADD COLUMN security_question VARCHAR(128);
ALTER TABLE users ADD COLUMN security_answer VARCHAR(128);
ALTER TABLE users MODIFY password VARCHAR(80);
