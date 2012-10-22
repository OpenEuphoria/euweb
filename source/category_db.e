--****
-- == Category System
-- 
-- Categories exist in the database table 'category.' They contain a unique
-- identifier, name and child count. Optionally they contain a description in creole
-- format and a rank. The higher ranking categories appear at the front of the list.
-- 
-- Categories are not explicitly created or removed. When an item is assigned to a
-- category, the category is automatically created if necessary. When an item
-- is removed from a category, the category is automatically removed if it contains
-- no other children.
-- 
-- Categories do have user defined settings and they are for better category
-- display. If a category is user edited it will not be automatically removed. It
-- will, however, appear in as an unused category. 
--

namespace category_db

include edbi/edbi.e as edbi

public enum ID, NAME, CHILDREN, RANK, KEYWORDS, DESCRIPTION

--**
-- Get the ID of a category. If the category is an ID already, it simply
-- returns the ID passed. If the category is a sequence, then we query the
-- database for the ID. Do it for anonymous users - don't add new ones.
-- Return -1 in that case.
--
-- Parameters:
--   * ##category## - category name or id
--
-- Returns:
--   ##integer## ID representing the category or -1 if it is a new one
--

public function get_id_anon(object category)
	if integer(category) then
		return category
	end if

	object cat_rec = edbi:query_row("SELECT id FROM category WHERE name=%s", {
			category })
	if sequence(cat_rec) then
		return cat_rec[1]
	end if

	return -1
end function
--**
-- Get the ID of a category. If the category is an ID already, it simply
-- returns the ID passed. If the category is a sequence, then we query the
-- database for the ID. If it does not exist, it is created.
--
-- Parameters:
--   * ##category## - category name or id
--
-- Returns:
--   ##integer## ID representing the category
--

public function get_id(object category)
	if integer(category) then
		return category
	end if

	object cat_rec = edbi:query_row("SELECT id FROM category WHERE name=%s", {
			category })
	if sequence(cat_rec) then
		return cat_rec[1]
	end if

	integer status = edbi:execute("INSERT INTO category (name) VALUES (%s)", { 
			category }
	) 

	if status = 0 then
		return edbi:last_insert_id()
	end if
	
	return -1
end function

--**
-- Get a list of category members anonymously (i.e. don't add new ones)
-- 
-- Parameters:
--   * ##category## - category to get member list for
--

public function member_list_anon(object category)
	integer category_id = get_id_anon(category)

	-- right now only forum messages and wiki pages can belong to a category
	-- resulting list must be: name, icon, url
	object members = edbi:query_rows("""
			SELECT 
				w.name AS name, 'world.png', CONCAT('/wiki/view/', w.name, '.wc')
			FROM wiki_page AS w
			INNER JOIN category_link AS cl ON (w.name = cl.item_id AND cl.category_id=%d)
			WHERE w.rev = 0 AND cl.module_id=3
		UNION ALL
			SELECT
				m.subject AS name, 'email.png', CONCAT('/forum/', m.id, '.wc')
			FROM messages AS m
			INNER JOIN category_link AS cl ON (m.id = cl.item_id)
			WHERE cl.category_id = %d AND cl.module_id=4
		""", { category_id, category_id })

	return members
end function

--**
--**
-- Get a list of category members
-- 
-- Parameters:
--   * ##category## - category to get member list for
--

public function member_list(object category)
	integer category_id = get_id(category)

	-- right now only forum messages and wiki pages can belong to a category
	-- resulting list must be: name, icon, url
	object members = edbi:query_rows("""
			SELECT 
				w.name AS name, 'world.png', CONCAT('/wiki/view/', w.name, '.wc')
			FROM wiki_page AS w
			INNER JOIN category_link AS cl ON (w.name = cl.item_id AND cl.category_id=%d)
			WHERE w.rev = 0 AND cl.module_id=3
		UNION ALL
			SELECT
				m.subject AS name, 'email.png', CONCAT('/forum/', m.id, '.wc')
			FROM messages AS m
			INNER JOIN category_link AS cl ON (m.id = cl.item_id)
			WHERE cl.category_id = %d AND cl.module_id=4
		""", { category_id, category_id })

	return members
end function

--**
-- Get a list of categories that a given item blongs to
--
-- Parameters:
--   * ##module_id## - module of item
--   * ##item_id##   - item id
--
-- Returns:
--   Sequence of category names that the item blongs to
--

public function item_list(integer module_id, object item_id)
	if not sequence(item_id) then
		item_id = sprintf("%d", { item_id })
	end if

	return edbi:query_rows("""
		SELECT c.id, c.name FROM category_link AS cl
		INNER JOIN category AS c ON (c.id = cl.category_id)
		WHERE cl.module_id = %d AND cl.item_id = %s
		ORDER BY c.rank DESC, c.name""", { module_id, item_id })
end function

--**
-- Assign a category to a given item
--
-- Parameters:
--   * ##category##    - category, can be id (integer) or name (sequence)
--   * ##module_id##   - module id of the item being assigned
--   * ##item_id##     - actual item being assigned to the category
--
-- See Also:
--   [[:uncategorize]]
--

public function categorize(object category, integer module_id, sequence item_id)
	integer cat_id = get_id(category)
	if cat_id = -1 then
		return 0
	end if

	integer status = edbi:execute("""INSERT INTO 
		category_link (category_id, module_id, item_id)
		VALUES (%d, %d, %s)""", 
		{
			cat_id, module_id, item_id 
		}
	)

	edbi:execute("UPDATE category SET children = children + 1 WHERE id=%d", {
			cat_id })
	
	return (status = 0)
end function

--**
-- Remove a category from a given item
--
-- Parameters:
--   * ##category##  - category, can be id (integer) or name (sequence)
--   * ##module_id##   - module id of the item being assigned
--   * ##item_id##     - actual item being assigned to the category
--
-- See Also:
--   [[:categorize]]
--

public function uncategorize(object category, integer module_id, sequence item_id)
	integer cat_id = get_id(category)
	if cat_id = -1 then
		return 0
	end if

	integer status = edbi:execute("""
		DELETE FROM category_link 
		WHERE category_id=%d AND module_id=%d AND item_id=%s
		""", { cat_id, module_id, item_id } 
	)

	edbi:execute("UPDATE category SET children = children - 1 WHERE id=%d", {
			cat_id })
	
	-- Delete this category only if it has no children and no user
	-- supplied data
	edbi:execute("""
		DELETE FROM category 
		WHERE id=%d AND children = 0 AND rank=1 AND description IS NULL""", 
		{ 
			cat_id 
		} 
	)
	
	return status
end function

--**
-- Update a category's user data
--
-- Parameters:
--   * ##category##    - integer id or sequence name
--   * ##rank##        - integer rank (1=top, 10=bottom)
--   * ##keywords##    - keywords (comma delimited) used for category suggestions
--   * ##description## - displayed on category detail page
--
-- Returns:
--   1 on success, 0 on failure
--

public function update(object category, integer rank, sequence keywords,
			sequence description)
	integer cat_id = get_id(category)
	if cat_id = -1 then
		return 0
	end if

	integer status = edbi:execute("""
		UPDATE category SET rank=%d, keywords=%s, description=%s
		WHERE id=%d""",
		{
			rank, keywords, description, cat_id
		}
	)
	
	return (status = 0)
end function

--**
-- Rename a category.
--
-- Parameters:
--   * ##category## - current category ID or name
--   * ##new_name## - new category name
--

public function rename(object category, sequence new_name)
	integer cat_id = get_id(category)
	if cat_id = -1 then
		return 0
	end if

	return edbi:execute("UPDATE category SET name=%s WHERE id=%d", { 
			new_name, cat_id })
end function
