USE `euweb`;

alter table messages add column is_deleted int(1) default 0;
