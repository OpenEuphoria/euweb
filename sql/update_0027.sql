CREATE TABLE pastey (
  id integer auto_increment primary key,
  user_id integer not null,
  created_at datetime not null,
  title varchar(80) not null,
  body text
) DEFAULT CHARSET=cp1251;

