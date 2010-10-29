--****
-- == Forum module
--

-- StdLib includes
include std/error.e
include std/get.e
include std/map.e
include std/search.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

include edbi/edbi.e

-- Templates
include templates/security.etml as t_security
include templates/forum/index.etml as t_index
include templates/forum/view.etml as t_view
include templates/forum/post.etml as t_post
include templates/forum/post_ok.etml as t_post_ok
include templates/forum/remove_post.etml as t_remove
include templates/forum/remove_post_ok.etml as t_remove_ok
include templates/forum/edit.etml as t_edit
include templates/forum/edit_ok.etml as t_edit_ok
include templates/forum/view_message.etml as t_view_message
include templates/forum/index_message.etml as t_index_message
include templates/forum/invalid_message.etml as t_invalid

-- Local includes
include config.e
include db.e
include format.e
include forum_db.e
include fuzzydate.e

sequence index_vars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index_message(map data, map request)
	object messages = forum_db:get_list(map:get(request, "page"), map:get(request, "per_page"))

	for i = 1 to length(messages) do
		messages[i][MSG_CREATED_AT] = fuzzy_ago(messages[i][MSG_CREATED_AT])
	end for

	map:put(data, "page", map:get(request, "page"))
	map:put(data, "per_page", map:get(request, "per_page"))
	map:put(data, "message_count", forum_db:message_count())
	map:put(data, "messages", messages)

	return { TEXT, t_index_message:template(data) }
end function

function index_thread(map data, map request)
	map:put(data, "page", map:get(request, "page"))
	map:put(data, "per_page", map:get(request, "per_page"))
	map:put(data, "message_count", forum_db:message_count())
	map:put(data, "thread_count", forum_db:thread_count())

	object threads = forum_db:get_thread_list(map:get(request, "page"), map:get(request, "per_page"))
	for i = 1 to length(threads) do
		threads[i][THREAD_CREATED_AT] = fuzzy_ago(threads[i][THREAD_CREATED_AT])
		if length(threads[i][THREAD_LAST_POST_AT]) then
			threads[i][THREAD_LAST_POST_AT] = fuzzy_ago(threads[i][THREAD_LAST_POST_AT])
		end if
	end for

	map:put(data, "threads", threads)

	return { TEXT, t_index:template(data) }
end function

function index(map data, map request)
	if sequence(current_user) and current_user[USER_FORUM_DEFAULT_VIEW] = 2 then
		return index_message(data, request)
	else
		return index_thread(data, request)
	end if
end function
wc:add_handler(routine_id("index"), -1, "forum", "index", index_vars)

sequence basic_vars = {
	{ wc:INTEGER, "id", -1 }
}

function view(map data, map request)
	integer topic_id = map:get(request, "id")

	object messages = forum_db:get_topic_messages(topic_id)
	if atom(messages) then
		crash("Couldn't get message: %s", { edbi:error_message() })
	end if
	if length(messages) = 0 then
		return { TEXT, t_invalid:template(data) }
	end if

	forum_db:inc_view_counter(topic_id)

	for i = 1 to length(messages) do
		messages[i] = append(messages[i], format_body(messages[i][MSG_BODY]))
		messages[i][MSG_CREATED_AT] = fuzzy_ago(messages[i][MSG_CREATED_AT])
		if length(messages[i][MSG_LAST_EDIT_AT]) then
			messages[i][MSG_LAST_EDIT_AT] = fuzzy_ago(messages[i][MSG_LAST_EDIT_AT])
		end if
	end for

	map:put(data, "messages", messages)

	return { TEXT, t_view:template(data) }
end function
wc:add_handler(routine_id("view"), -1, "forum", "view", basic_vars)

sequence post_vars = {
	{ wc:INTEGER, "parent_id",  -1 },
	{ wc:INTEGER, "quote",  	 0 },
	{ wc:INTEGER, "fork",   	 0 }
}

function post(map data, map request)
	if not has_role("user") then
		return { TEXT, t_security:template(data) }
	end if

    if map:get(data, "has_errors") then
        -- Copy all input data right over to the template data
        map:copy(request, data)

        -- We use a different source than name for the body, so we must
        -- set it manually.
        map:put(data, "quote_body", map:get(request, "body"))

        return { TEXT, t_post:template(data) }
    end if

	integer id = map:get(request, "parent_id")
	integer fork = map:get(request, "fork")
	integer quote = map:get(request, "quote")

	map:put(data, "quote", quote)
	map:put(data, "fork", fork)
	map:put(data, "id", -1)
	map:put(data, "parent_id", -1)
	map:put(data, "topic_id", -1)
	map:put(data, "fork_id", -1)

	if sequence(map:get(data, "body_formatted")) then

		map:copy(request, data)
		map:put(data, "quote_body", match_replace("\r\n", map:get(request, "body"), "\n"))

	elsif id > 0 then
		object msg = forum_db:get(id)
		if atom(msg) then
			crash("Couldn't retrieve message %d, %s", { id, edbi:error_message() })
		end if

		sequence subject = msg[MSG_SUBJECT]

		if not match("Re:", subject) then
			subject = "Re: " & subject
		end if

		if fork = 0 then
			map:put(data, "parent_id", id)
			map:put(data, "subject", subject)
			map:put(data, "topic_id", msg[MSG_TOPIC_ID])
		else
			map:put(data, "fork_id", id)
		end if

		map:put(data, "body", msg[MSG_BODY])
		if quote or fork then
			sequence body
			map:put(data, "quote", 1)
			body = match_replace("\r\n", sprintf("[quote %s]\n%s\n[/quote]\n", {
				msg[MSG_AUTHOR_NAME], msg[MSG_BODY] }), "\n")

			if fork then
				body = sprintf("**Forked from [[%s/forum/%d.wc#%d|%s]]**\n\n", {
					ROOT_URL, msg[MSG_ID], msg[MSG_ID], msg[MSG_SUBJECT]
				}) & body
			end if

			map:put(data, "quote_body", body)
		end if
	end if

	return { TEXT, t_post:template(data) }
end function
wc:add_handler(routine_id("post"), -1, "forum", "post", post_vars)

sequence save_vars = {
	{ wc:INTEGER, "id", 	   -1 },
	{ wc:INTEGER, "topic_id",  -1 },
	{ wc:INTEGER, "parent_id", -1 },
	{ wc:INTEGER, "fork_id",   -1 },
	{ wc:INTEGER, "fork",   	0 },
	{ wc:SEQUENCE, "subject"	  },
	{ wc:SEQUENCE, "body"   	  }
}

--**
-- Validate the information sent by the forum post form
--
-- Web Validation:
--  * Subject must not be empty
--  * Body must not be empty
--  * Body must be valid creole
--  * Body cannot have dangling <eucode>'s
--

function validate_save(integer data, map:map vars)
	sequence errors = wc:new_errors("forum", "post")

	if not valid:not_empty(map:get(vars, "subject")) then
		errors = wc:add_error(errors, "subject", "Subject is empty!")
	end if

	if not valid:not_empty(map:get(vars, "body")) then
		errors = wc:add_error(errors, "body", "Body is empty!")
	end if

	return errors
end function

--**
-- Handle the submission of a new forum post
--

function save(map:map data, map:map vars)
	if not has_role("user") then
		return { TEXT, t_security:template(data) }
	end if

	if equal(map:get(vars, "save"), "Preview") then
		map:put(data, "body_formatted", format_body(map:get(vars, "body")))
		return post(data, vars)
	end if

	object post = forum_db:create(map:get(vars, "parent_id"),
		map:get(vars, "topic_id"), map:get(vars, "subject"),
		map:get(vars, "body"))

	if atom(post) then
		crash("Couldn't create new post")
	end if

	map:put(data, "ok", 1)
	map:put(data, "subject", post[MSG_SUBJECT])
	map:put(data, "topic_id", post[MSG_TOPIC_ID])
	map:put(data, "id", post[MSG_ID])

	if map:get(vars, "fork", 0) then
		integer forked_id = map:get(vars, "fork_id")
		forum_db:update_forked_body(post[MSG_ID], forked_id, post[MSG_SUBJECT])
	end if

	return { TEXT, t_post_ok:template(data) }
end function
wc:add_handler(routine_id("save"), routine_id("validate_save"), "forum", "save", save_vars)

function edit(map data, map request)
	object message = forum_db:get(map:get(request, "id"))

	-- A forum admin can edit any message, no need for further checks
	if not has_role("forum_moderator") then
		-- You must be at least a user
		if not has_role("user") then
			return { TEXT, t_security:template(data) }
		end if

		-- You must be the owner of the message
		if not equal(message[MSG_POST_BY_ID], current_user[USER_ID]) then
			return { TEXT, t_security:template(data) }
		end if
	end if

	message[MSG_BODY] = match_replace("\r\n", message[MSG_BODY], "\n")

	if sequence(map:get(data, "body_formatted")) then

		map:copy(request, data)
		map:put(data, "body", match_replace("\r\n", map:get(request, "body"), "\n"))

	else

		map:put(data, "subject", message[MSG_SUBJECT])
		map:put(data, "body", message[MSG_BODY])

	end if

	map:put(data, "id", message[MSG_ID])
	map:put(data, "topic_id", message[MSG_TOPIC_ID])

	return { TEXT, t_edit:template(data) }
end function
wc:add_handler(routine_id("edit"), -1, "forum", "edit", basic_vars)

sequence update_vars = {
	{ wc:INTEGER, "id", 	   -1 },
	{ wc:SEQUENCE, "subject"	  },
	{ wc:SEQUENCE, "body"   	  }
}

--**
-- Validate the information sent by the forum edit form
--
-- Web Validation:
--  * Subject must not be empty
--  * Body must not be empty
--  * Body must be valid creole
--  * Body cannot have dangling <eucode>'s
--	* id cannot be <= 0
--

function validate_update(integer data, map:map vars)
	sequence errors = wc:new_errors("forum", "edit")

	if not valid:not_empty(map:get(vars, "subject")) then
		errors = wc:add_error(errors, "subject", "Subject is empty!")
	end if

	if not valid:not_empty(map:get(vars, "body")) then
		errors = wc:add_error(errors, "body", "Body is empty!")
	end if

	if map:get(vars, "id") <= 0 then
		errors = wc:add_error(errors, "form", "Invalid message id!")
	end if

	return errors
end function

function update(map data, map request)
	object message = forum_db:get(map:get(request, "id"))

	-- A forum admin can edit any message, no need for further checks
	if not has_role("forum_moderator") then
		-- You must be at least a user
		if not has_role("user") then
			return { TEXT, t_security:template(data) }
		end if

		-- You must be the owner of the message
		if not equal(message[MSG_POST_BY_ID], current_user[USER_ID]) then
			return { TEXT, t_security:template(data) }
		end if
	end if

	if equal(map:get(request, "save"), "Preview") then
		map:put(data, "body_formatted", format_body(map:get(request, "body")))
		return edit(data, request)
	end if

	message[MSG_SUBJECT] = map:get(request, "subject")

	message[MSG_BODY] = map:get(request, "body")

	forum_db:update(message)

	map:put(data, "subject", message[MSG_SUBJECT])
	map:put(data, "topic_id", message[MSG_TOPIC_ID])
	map:put(data, "id", message[MSG_ID])

	return { TEXT, t_edit_ok:template(data) }
end function
wc:add_handler(routine_id("update"), routine_id("validate_update"), "forum", "update", update_vars)

sequence remove_vars = {
	{ wc:INTEGER, "id", -1 }
}

function remove_post(map data, map request)
	if not has_role("forum_moderator") then
		return { TEXT, t_security:template(data) }
	end if

	object message = forum_db:get(map:get(request, "id"))
	if atom(message) then
		crash("Could not retrieve message from database: %s", { edbi:error_message() })
	end if

	map:put(data, "id", message[MSG_ID])
	map:put(data, "topic_id", message[MSG_TOPIC_ID])
	map:put(data, "subject", message[MSG_SUBJECT])

	return { TEXT, t_remove:template(data) }
end function
wc:add_handler(routine_id("remove_post"), -1, "forum", "remove", remove_vars)

function remove_post_confirmed(map data, map request)
	if not has_role("forum_moderator") then
		return { TEXT, t_security:template(data) }
	end if

	forum_db:remove_post(map:get(request, "id"))

	return { TEXT, t_remove_ok:template(data) }
end function
wc:add_handler(routine_id("remove_post_confirmed"), -1, "forum", "remove_confirmed", remove_vars)

sequence message_vars = {
	{ wc:INTEGER, "id" }
}

function message(map data, map request)
	object m = forum_db:get(map:get(request, "id"))
	if sequence( m ) then
		map:put(data, "id", m[forum_db:MSG_ID])
		map:put(data, "topic_id", m[forum_db:MSG_TOPIC_ID])
		map:put(data, "parent_id", m[forum_db:MSG_PARENT_ID])
		map:put(data, "created_at", fuzzy_ago(m[forum_db:MSG_CREATED_AT]))
		map:put(data, "subject", m[forum_db:MSG_SUBJECT])
		map:put(data, "body", m[forum_db:MSG_BODY])
		map:put(data, "ip", m[forum_db:MSG_IP])
		map:put(data, "author_name", m[forum_db:MSG_AUTHOR_NAME])
		map:put(data, "author_email", m[forum_db:MSG_AUTHOR_EMAIL])
		map:put(data, "post_by_id", m[forum_db:MSG_POST_BY_ID])
		map:put(data, "views", m[forum_db:MSG_VIEWS])
		map:put(data, "replies", m[forum_db:MSG_REPLIES])
		map:put(data, "body_formatted", format_body(m[forum_db:MSG_BODY]))

		object prev_id = edbi:query_object("SELECT id FROM messages WHERE id < %d ORDER BY id DESC LIMIT 1",
			{ m[forum_db:MSG_ID] })
		object next_id = edbi:query_object("SELECT id FROM messages WHERE id > %d ORDER BY id LIMIT 1",
			{ m[forum_db:MSG_ID] })

		map:put(data, "prev_id", prev_id)
		map:put(data, "next_id", next_id)

		forum_db:inc_message_view_counter(m[forum_db:MSG_ID])

		return { TEXT, t_view_message:template(data) }
	else
		return { TEXT, t_invalid:template(data) }
	end if
end function
wc:add_handler(routine_id("message"), -1, "forum", "message", message_vars)
