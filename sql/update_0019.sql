--
-- Add "Task" as a valid ticket type and "On Hold" as a new status
--

INSERT INTO ticket_type (name) VALUES ('Task');

UPDATE ticket_status SET position = position + 1 WHERE position > 3;
INSERT INTO ticket_status (name, position, is_open) 
    VALUES ('On Hold', 4, 1);

