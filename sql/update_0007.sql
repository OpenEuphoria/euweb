--
-- Ticket System
--

CREATE TABLE ticket_severity (
	id integer primary key auto_increment not null, 
	name varchar(60) not null,
	position integer not null
);
CREATE INDEX name_idx ON ticket_severity(name);
INSERT INTO ticket_severity (name, position) VALUES ('Feature Request', 1);
INSERT INTO ticket_severity (name, position) VALUES ('Textual Change', 2);
INSERT INTO ticket_severity (name, position) VALUES ('Minor Inconvience', 3);
INSERT INTO ticket_severity (name, position) VALUES ('Workaround Exists', 4);
INSERT INTO ticket_severity (name, position) VALUES ('Blocks Progress', 5);

CREATE TABLE ticket_category (
	id integer not null primary key auto_increment,
	name varchar(60) not null
);
CREATE INDEX name_idx ON ticket_category(name);
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
	name varchar(60) not null,
	position integer not null
);
CREATE INDEX name_idx ON ticket_status(name);
INSERT INTO ticket_status (name, position) VALUES ('New', 1);
INSERT INTO ticket_status (name, position) VALUES ('Accepted', 2);
INSERT INTO ticket_status (name, position) VALUES ('Fixed', 3);
INSERT INTO ticket_status (name, position) VALUES ('Invalid', 4);
INSERT INTO ticket_status (name, position) VALUES ('Duplicate', 5);

CREATE TABLE ticket_state (
	id integer not null primary key auto_increment,
	name varchar(60) not null,
	closed integer not null,
	position integer not null
);
CREATE INDEX name_idx ON ticket_state(name);
INSERT INTO ticket_state (name, closed, position) VALUES ('Open', 0, 1);
INSERT INTO ticket_state (name, closed, position) VALUES ('Closed', 1, 2);
INSERT INTO ticket_state (name, closed, position) VALUES ('Deleted', 1, 3);

CREATE TABLE releases (
	id integer not null primary key auto_increment,
	name varchar(60) not null,
	archived integer not null,
	position integer not null
);
CREATE INDEX name_idx ON releases(name);
INSERT INTO releases (name, archived, position) VALUES ('svn trunk', 0, 1);
INSERT INTO releases (name, archived, position) VALUES ('3.1', 1, 2);
INSERT INTO releases (name, archived, position) VALUES ('3.1.1', 1, 3);
INSERT INTO releases (name, archived, position) VALUES ('4.0a1', 0, 4);
INSERT INTO releases (name, archived, position) VALUES ('4.0a2', 0, 5);
INSERT INTO releases (name, archived, position) VALUES ('4.0a3', 0, 6);
INSERT INTO releases (name, archived, position) VALUES ('4.0b1', 0, 7);
INSERT INTO releases (name, archived, position) VALUES ('4.0b2', 0, 8);

CREATE TABLE ticket (
	id integer not null primary key auto_increment,
	created_at datetime not null,
	submitted_by_id integer not null references users(id),
	assigned_to_id integer not null references users(id),
	severity_id integer not null references ticket_severity(id),
	category_id integer not null references ticket_category(id),
	status_id integer not null references ticket_status(id),
	state_id integer not null references ticket_state(id),
	reported_release_id integer not null references releases(id),
	subject varchar(120) not null,
	content text not null,
	resolved_at datetime,
	svn_rev varchar(60)
);
-- TODO: Create indexes

--
-- Generic comment table. This can be used for wiki pages, news articles, tickets,
-- or whatever else we come up with. Just assign a unique module_id and then put the
-- related id into item_id. Then, say ticket's module_id is 1 and you want comments
-- for ticket 1, then do a query: SELECT * FROM comment WHERE module_id=1 AND item_id=1
--

CREATE TABLE comment (
    id integer not null auto_increment primary key,
    module_id integer not null,
    item_id integer not null,
    user_id integer not null references users(id),
    created_at datetime not null,
    subject varchar(255) not null,
    body text not null
);
CREATE INDEX link_idx ON comment(module_id, item_id);
CREATE INDEX natural_display_idx ON comment(module_id, item_id, created_at);

--INSERT INTO users (id, user, password, email, disabled, disabled_reason, name)
--	VALUES (0, 'unknown', '', 'noemail@noemail.com', 1, 'Internal user', 'Unknown User');

