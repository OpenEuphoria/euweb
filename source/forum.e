--****
-- == Forum module
--

-- StdLib includes
include std/error.e
include std/get.e
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid
include webclay/logging.e as log

-- Templates
include templates/forum/index.etml as t_index
include templates/forum/view.etml as t_view
include templates/forum/post.etml as t_post
include templates/forum/post_ok.etml as t_post_ok

-- Local includes
include db.e
include format.e
include forum_db.e

sequence index_invars = {
	{ wc:INTEGER, "page",   	1 },
	{ wc:INTEGER, "per_page",  20 }
}

function index(map data, map invars)
	map:put(data, "page", map:get(invars, "page"))
	map:put(data, "per_page", map:get(invars, "per_page"))
	map:put(data, "message_count", forum_db:message_count())
	map:put(data, "thread_count", forum_db:thread_count())

	map:put(data, "threads", 
		forum_db:get_thread_list(map:get(invars, "page"), map:get(invars, "per_page")))

	log:log("Page: %d Per Page: %d", { map:get(invars, "page"), map:get(invars, "per_page") })
	
	return { TEXT, t_index:template(data) }
end function
wc:add_handler(routine_id("index"), -1, "forum", "index", index_invars)

sequence view_invars = {
	{ wc:INTEGER, "id", -1 }
}

function view(map data, map invars)
	integer topic_id = map:get(invars, "id")
	forum_db:inc_view_counter(topic_id)

	object messages = forum_db:get_topic_messages(topic_id)
	if atom(messages) then
		crash("Couldn't get message: %s", { mysql_error(db) })
	end if
	if length(messages) = 0 then
		crash("Message topic id is invalid")
	end if
	
	for i = 1 to length(messages) do
		messages[i] = append(messages[i], format_body(messages[i][MSG_BODY]))
	end for
	
	map:put(data, "messages", messages)
	
	return { TEXT, t_view:template(data) }
end function
wc:add_handler(routine_id("view"), -1, "forum", "view", view_invars)

sequence post_invars = {
	{ wc:INTEGER, "parent_id",  -1 },
	{ wc:INTEGER, "quote",  	 0 }
}

function post(map data, map invars)
	integer id = map:get(invars, "parent_id")

	map:put(data, "quote", 0)
	map:put(data, "parent_id", id)
	map:put(data, "id", -1)

	if id > 0 then
		object msg = forum_db:get(id)
		if atom(msg) then
			crash("Couldn't retrieve message %d, %s", { id, mysql_error(db) })
		end if
		
		sequence subject = msg[MSG_SUBJECT]
		
		if not match("Re:", subject) then
			subject = "Re: " & subject
		end if
		
		map:put(data, "subject", subject)
		map:put(data, "body", msg[MSG_BODY])
		map:put(data, "topic_id", defaulted_value(msg[MSG_TOPIC_ID], 0))
		if map:get(invars, "quote") then
			map:put(data, "quote", 1)
			map:put(data, "quote_body", sprintf("[quote %s]\n%s\n[/quote]\n\n", {
				msg[MSG_AUTHOR_NAME], msg[MSG_BODY] }))
		else
		end if
	end if

	return { TEXT, t_post:template(data) }
end function
wc:add_handler(routine_id("post"), -1, "forum", "post", post_invars)

sequence save_invars = {
	{ wc:INTEGER, "id", 	   -1 },
	{ wc:INTEGER, "topic_id",  -1 },
	{ wc:INTEGER, "parent_id", -1 },
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

function validate_post(integer data, map:map vars)
	sequence errors = wc:new_errors("form", "view")

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
	object post = forum_db:create(map:get(vars, "parent_id", 0),
		map:get(vars, "topic_id", 0), map:get(vars, "subject"),
		map:get(vars, "body"))
	
	if atom(post) then
		crash("Couldn't create new post")
	end if
	
	log:log("topic_id = %s", { post[MSG_TOPIC_ID] })

	map:put(data, "ok", 1)
	map:put(data, "subject", post[MSG_SUBJECT])
	map:put(data, "topic_id", post[MSG_TOPIC_ID])
	map:put(data, "id", post[MSG_ID])

	return { TEXT, t_post_ok:template(data) }
end function

-- Add the handler, validation and conversion for the greeter action
wc:add_handler(routine_id("save"), routine_id("validate_post"), "forum", "save", save_invars)
