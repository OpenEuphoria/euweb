--
-- Migration of Milestone 4.0.0 to Milestone 4.0.0RC1
--

INSERT INTO ticket_milestone (name,product_id) VALUES ('4.0.0RC1', 1);

UPDATE ticket SET milestone='4.0.0RC1' WHERE milestone='4.0.0' AND product_id=1;
