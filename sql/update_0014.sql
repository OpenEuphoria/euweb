--
-- Moving tracker from a "single" product bias to a "multiple" product bias
--

ALTER TABLE ticket_category ADD COLUMN product_id INTEGER;
ALTER TABLE ticket_milestone ADD COLUMN product_id INTEGER;

UPDATE ticket_category SET product_id=1;
UPDATE ticket_milestone SET product_id=1;

ALTER TABLE ticket_category MODIFY product_id INTEGER NOT NULL; 
ALTER TABLE ticket_category ADD FOREIGN KEY(product_id) REFERENCES ticket_product(id);
ALTER TABLE ticket_milestone MODIFY product_id INTEGER NOT NULL;
ALTER TABLE ticket_milestone ADD FOREIGN KEY(product_id) REFERENCES ticket_product(id);

-- Move all "Website" category items to "OpenEuphoria.org" product
UPDATE ticket SET product_id=2 WHERE category_id=14;

-- Update Website category to be owned by OpenEuphoria.org and named General
UPDATE ticket_category SET product_id=2, name='General' WHERE id=14;

-- Add a General category for the Creole product
INSERT INTO ticket_category (name, product_id) VALUES ('General', 3);

