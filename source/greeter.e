-- StdLib includes
include std/map.e

-- Webclay includes
include webclay/webclay.e as wc
include webclay/validate.e as valid

-- Local includes
include templates/hello.etml as t_hello

-- Conversions used for both the greeter form and greeter action
sequence greeter_conversion = {
	{ wc:SEQUENCE, "name",     "World" },
	{ wc:SEQUENCE, "greeting", "Hello" }
}

--**
-- Present the greeting form
--
-- Web Action:
--     ##greeter##, ##form##

function greet_form(map:map data, map:map vars)
	map:copy(vars, data)

	return { TEXT, t_hello:template(data) }
end function

-- Add the handler and conversion for the greeter form.
wc:add_handler(routine_id("greet_form"), -1, "greeter", "index", greeter_conversion)

--**
-- Validate the information sent by the greeter form to the greet action
--
-- Web Validation:
--     * Name must not be empty
--     * Greeting must not be Goodbye

function validate_greet_form(integer data, map:map vars)
	sequence errors = wc:new_errors("greeter", "index")

	if not valid:not_empty(map:get(vars, "name")) then
		errors = wc:add_error(errors, "name", "Name is empty!")
	end if

	if not valid:not_empty(map:get(vars, "greeting")) then
		errors = wc:add_error(errors, "greeting", "Greeting is empty!")
	end if

	if equal(map:get(vars, "greeting"), "Goodbye") then
		errors = wc:add_error(errors, "greeting", 
			"We are not going anywhere, do not say goodbye!")
	end if

	return errors
end function

--**
-- Actually greet the person
--
-- Web Action:
--     ##greeter##, ##greet##

function greet(map:map data, map:map vars)
	-- Put our CGI vars directly into the template data
	map:put(data, "greet_name", map:get(vars, "name", ""))
	map:put(data, "greet_greeting", map:get(vars, "greeting", ""))

	map:copy(vars, data)

	return { TEXT, t_hello:template(data) }
end function

-- Add the handler, validation and conversion for the greeter action
wc:add_handler(routine_id("greet"), routine_id("validate_greet_form"),
	"greeter", "greet", greeter_conversion)
