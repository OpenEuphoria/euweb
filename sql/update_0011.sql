--
-- Ticket conversion to support product and ticket type
-- 

CREATE TABLE ticket_product (
	id integer primary key not null auto_increment,
	name varchar(128) not null unique
);
INSERT INTO ticket_product (name) VALUES 
	('Euphoria'), 
	('OpenEuphoria.org'), 
	('Creole');

CREATE TABLE ticket_type (
	id integer primary key not null auto_increment,
	name varchar(128) not null unique
);
INSERT INTO ticket_type (name) VALUES 
	('Bug Report'), 
	('Feature Request');

ALTER TABLE ticket ADD COLUMN product_id integer not null default 1 references ticket_product(id);
ALTER TABLE ticket ADD COLUMN type_id integer not null default 1 references ticket_type(id);

UPDATE ticket SET type_id=2 WHERE severity_id=1;
UPDATE ticket SET severity_id=3 WHERE type_id=2;

UPDATE ticket_severity SET name='Textual' WHERE id=1;
UPDATE ticket_severity SET name='Minor' WHERE id=2;
UPDATE ticket_severity SET name='Normal' WHERE id=3;
UPDATE ticket_severity SET name='Major' WHERE id=4;
UPDATE ticket_severity SET name='Blocking' WHERE id=5;

UPDATE ticket SET product_id=2 WHERE category_id=14;
