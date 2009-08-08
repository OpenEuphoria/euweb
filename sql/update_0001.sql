--
-- Update the existing schema from EUforum to that of euweb.
--

-- So we can easily terminate a user
ALTER TABLE users ADD COLUMN disabled tinyint default 0;
ALTER TABLE users ADD COLUMN disabled_reason VARCHAR(128);

CREATE TABLE user_roles (
	user_id integer not null references users(id),
	role_name varchar(45) not null
);

CREATE INDEX user_roles_user_idx ON user_roles (user_id);
INSERT INTO user_roles SELECT id, 'forum_moderator' FROM users WHERE moderator=1;
INSERT INTO user_roles SELECT id, 'admin' FROM users u WHERE u.user IN ('jeremy', 'DerekParnell', 'mattlewis'); 
INSERT INTO user_roles SELECT id, 'user' FROM users;
ALTER TABLE users DROP COLUMN moderator;

CREATE TABLE news (
	id integer not null primary key auto_increment,
	submitted_by_id integer not null references users(id),
	approved tinyint not null default 0,
	approved_by_id integer not null references users(id),
	publish_at datetime not null,
	subject varchar(128) not null,
	content text not null
);

CREATE INDEX news_display_order_idx ON news (publish_at, approved);
