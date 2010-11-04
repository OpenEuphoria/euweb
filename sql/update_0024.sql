--
-- Wiki read-only page mod
--

ALTER TABLE wiki_page ADD COLUMN read_only integer not null default 0;
