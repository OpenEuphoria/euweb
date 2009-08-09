--****
-- == User database support
-- 

namespace user_db

include std/sequence.e

include db.e

global object current_user = 0
global enum USER_ID, USER_NAME, USER_EMAIL, USER_LAST_LOGIN_AT, USER_ROLES

constant select_fields = "id, user, email, login_time"

public function get(integer id)
    object user = mysql_query_one(db, "SELECT " & select_fields & " FROM users WHERE id=%d", { id })
    if atom(user) then
    	return 0
	end if
	
	object roles = mysql_query_rows(db, "SELECT role_name FROM user_roles WHERE user_id=%d", { id })
	if atom(roles) then
		user &= {{}}
	else
		for i = 1 to length(roles) do
			roles[i] = roles[i][1] 
		end for
		user &= { roles }
	end if

	return user
end function

public function get_by_code(sequence code)
	return mysql_query_one(db, "SELECT " & select_fields & " FROM users WHERE user=%s", { code })
end function

global function has_role(sequence role, object user=current_user)
	if atom(user) then 
		return 0
	end if
		
	if find("admin", user[USER_ROLES]) then
		return 1
	end if 
	
	return find(role, user[USER_ROLES])
end function
