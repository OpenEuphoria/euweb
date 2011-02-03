USE `euweb`;

alter table users add column disable_fuzzy int(1) default 0;
