--
-- Add a blocked status
--

UPDATE ticket_status SET position = position + 1 WHERE position > 3;
INSERT INTO ticket_status (name, position, is_open) 
    VALUES ('Blocked', 4, 1);
