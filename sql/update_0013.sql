--
-- Add support for Ticket Target Milestone
--

ALTER TABLE ticket ADD COLUMN milestone varchar(30) NOT NULL default '';

CREATE TABLE ticket_milestone (
  name varchar(30) not null unique primary key
) ENGINE=MyISAM;

INSERT INTO ticket_milestone (name) VALUES ('4.0.0');
INSERT INTO ticket_milestone (name) VALUES ('4.1.0');
INSERT INTO ticket_milestone (name) VALUES ('5.0.0');

