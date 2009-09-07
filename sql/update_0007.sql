--
-- Ticket System
--

CREATE TABLE ticket_severity (
	id integer primary key auto_increment not null, 
	name varchar(60) not null
);
CREATE INDEX name_idx ON ticket_severity(name);
INSERT INTO ticket_severity (name) VALUES ('Textual');
INSERT INTO ticket_severity (name) VALUES ('Inconvience');
INSERT INTO ticket_severity (name) VALUES ('Major');
INSERT INTO ticket_severity (name) VALUES ('Blocker');

CREATE TABLE ticket_category (
	id integer not null primary key auto_increment,
	name varchar(60) not null
);
CREATE INDEX name_idx ON ticket_category(name);
INSERT INTO ticket_category (name) VALUES ('Unknown');
INSERT INTO ticket_category (name) VALUES ('Binder');
INSERT INTO ticket_category (name) VALUES ('Build System');
INSERT INTO ticket_category (name) VALUES ('Bundled Utility');
INSERT INTO ticket_category (name) VALUES ('Demo Program');
INSERT INTO ticket_category (name) VALUES ('Disassembler');
INSERT INTO ticket_category (name) VALUES ('Documentation');
INSERT INTO ticket_category (name) VALUES ('Error Reporting');
INSERT INTO ticket_category (name) VALUES ('Tracing/Debugging');
INSERT INTO ticket_category (name) VALUES ('Interpreter');
INSERT INTO ticket_category (name) VALUES ('Library Routine');
INSERT INTO ticket_category (name) VALUES ('Packaged Distribution');
INSERT INTO ticket_category (name) VALUES ('Translator');
INSERT INTO ticket_category (name) VALUES ('Unit Tests');

CREATE TABLE ticket_status (
	id integer not null primary key auto_increment,
	name varchar(60) not null
);
CREATE INDEX name_idx ON ticket_status(name);
INSERT INTO ticket_status (name) VALUES ('New');
INSERT INTO ticket_status (name) VALUES ('Accepted');
INSERT INTO ticket_status (name) VALUES ('Fixed');
INSERT INTO ticket_status (name) VALUES ('Invalid');
INSERT INTO ticket_status (name) VALUES ('Duplicate');

CREATE TABLE ticket_state (
	id integer not null primary key auto_increment,
	name varchar(60) not null
);
CREATE INDEX name_idx ON ticket_state(name);
INSERT INTO ticket_state (name) VALUES ('Open');
INSERT INTO ticket_state (name) VALUES ('Closed');
INSERT INTO ticket_state (name) VALUES ('Deleted');

CREATE TABLE ticket_release (
	id integer not null primary key auto_increment,
	name varchar(60) not null
);
CREATE INDEX name_idx ON ticket_release(name);
INSERT INTO ticket_release (name) VALUES ('svn trunk');
INSERT INTO ticket_release (name) VALUES ('4.0a1');
INSERT INTO ticket_release (name) VALUES ('4.0a2');
INSERT INTO ticket_release (name) VALUES ('4.0a3');
INSERT INTO ticket_release (name) VALUES ('4.0b1');
INSERT INTO ticket_release (name) VALUES ('4.0b2');

CREATE TABLE ticket (
	id integer not null primary key auto_increment,
	created_at datetime not null,
	submitted_by_id integer not null references users(id),
	assigned_to_id integer not null references users(id),
	severity_id integer not null references ticket_severity(id),
	category_id integer not null references ticket_category(id),
	status_id integer not null references ticket_status(id),
	state_id integer not null references ticket_state(id),
	reported_release_id integer not null references ticket_release(id),
	body text not null,
	subject varchar(120) not null,
	resolved_at datetime,
	svn_rev varchar(60)
);
-- TODO: Create indexes

CREATE TABLE ticket_comment (
    id integer not null primary key auto_increment,
    ticket_id integer not null references ticket(id),
    user_id integer not null references users(id),
    created_at datetime not null,
    body text not null
);
CREATE INDEX ticket_idx ON ticket_comment(ticket_id);
CREATE INDEX created_at_idx ON ticket_comment(created_at);
CREATE INDEX user_idx ON ticket_comment(user_id);
