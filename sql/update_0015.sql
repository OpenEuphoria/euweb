--
-- Migration from State/Status to Status
--

ALTER TABLE ticket_status ADD COLUMN is_open INTEGER NOT NULL DEFAULT 1;

UPDATE ticket_status SET is_open=0 WHERE id IN (3,4,5,7);
UPDATE ticket_status SET name='Is Bug?' WHERE id=6;
UPDATE ticket_status SET position=position+1 WHERE position >= 4;
INSERT INTO ticket_status (name,position,is_open)
    VALUES ('Fixed, Please Confirm', 4, 1);

ALTER TABLE ticket DROP COLUMN state_id;
DROP TABLE ticket_state;
