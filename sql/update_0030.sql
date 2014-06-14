USE `euweb`;

alter table comment add column is_deleted int(1) default 0;
alter table ticket add column is_deleted int(1) default 0;
alter table pastey add column is_deleted int(1) default 0;
