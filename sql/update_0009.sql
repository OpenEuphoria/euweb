--
-- Adding search
-- 

ALTER TABLE ticket ENGINE=MyISAM;
ALTER TABLE ticket ADD FULLTEXT(subject,content);
ALTER TABLE ticket CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE INDEX created ON ticket(created_at);

ALTER TABLE messages CHANGE body body text not null;
ALTER TABLE messages ENGINE=MyISAM;
ALTER TABLE messages ADD FULLTEXT(subject,content);
ALTER TABLE messages CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE INDEX created ON messages(created_at);

ALTER TABLE news ENGINE=MyISAM;
ALTER TABLE news ADD FULLTEXT(subject,content);
ALTER TABLE news CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE INDEX created ON news(publish_at);
