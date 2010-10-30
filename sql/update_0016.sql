--
-- Wiki system
--

CREATE TABLE wiki_page (
  rev integer not null default 0,
  name varchar(128) not null,
  created_at datetime not null,
  created_by_id integer not null references users(id),
  change_msg text not null,
  wiki_text text not null,
  primary key (name,rev)
);
