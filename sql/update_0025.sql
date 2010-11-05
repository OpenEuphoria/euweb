--
-- Manaul
--

CREATE TABLE manual (
    filename      varchar(64) not null,
    a_name        varchar(256) not null,
    name          varchar(256) not null,
    created_at    datetime not null,
    content       text not null,
    KEY           recent (created_at),
    FULLTEXT KEY  subject (content)
) DEFAULT CHARSET=cp1251;
