--
-- New category system
--

CREATE TABLE category (
    id          integer primary key auto_increment,
    name        varchar(48) not null unique,
    children    integer not null default 0,
    rank        integer not null default 1,
    keywords    text,
    description text
);

CREATE TABLE category_link (
    category_id integer not null,
    module_id   integer not null,
    item_id     varchar(128) not null,
    primary key (category_id, module_id, item_id)
);
