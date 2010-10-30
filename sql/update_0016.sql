--
-- Wiki system
--

DROP TABLE IF EXISTS wiki_page;
CREATE TABLE wiki_page (
  rev integer not null default 0,
  name varchar(128) not null,
  created_at datetime not null,
  created_by_id integer not null references users(id),
  change_msg text not null,
  wiki_text text not null,
  PRIMARY KEY (name,rev),
  KEY lookup (name,rev),
  KEY recent (rev,created_at),
  FULLTEXT KEY subject (name,wiki_text)
) DEFAULT CHARSET=cp1251;
