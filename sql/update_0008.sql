ALTER TABLE ticket ADD COLUMN reported_release VARCHAR(30) NOT NULL DEFAULT '';
 UPDATE ticket, releases SET ticket.reported_release=releases.name 
	WHERE ticket.reported_release_id=releases.id;
ALTER TABLE ticket DROP COLUMN reported_release_id;
