--
-- Return an icon for a given item type
--

public function type_icon(sequence typ)
	switch typ do
		case "ticket comment" then
			return "bug_error.png"

		case "news comment" then
			return "date_error.png"

		case "forum" then
			return "email.png"

		case "ticket" then
			return "bug.png"

		case "news" then
			return "date.png"

		case "wiki" then
			return "world.png"
			
		case "manual" then
			return "book.png"

		case "pastey" then
			return "camera_error.png"

		case "pastey comment" then
			return "camera_edit.png"
			
		case else
			return ""
	end switch
end function
