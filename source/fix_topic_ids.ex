/*
    Populates the topic_id field of the messages for quicker access in many
    forum operations.
*/

include std/get.e
include std/sequence.e

include db.e

function get_children_ids(integer post_id)
    atom res
    object tmp, data, sequence_ids = {}

    if mysql_query(db, "SELECT id FROM messages WHERE parent_id=%d", {post_id}) then
        printf(1, "Could not find any children for post: %d", {post_id})
        puts(1, mysql_error(db) & "\n")
        db:close()
        abort(1)
    end if

    res = mysql_use_result(db)

    while sequence(data) entry do
        tmp = value(data[1])
        if tmp[1] = GET_SUCCESS then
            sequence_ids &= tmp[2]
        end if
    entry
        data = mysql_fetch_row(res)
    end while

    return sequence_ids
end function

function get_all_children_ids(integer id)
    sequence ids = {id}
    integer idx = 1

    while 1 do
        if idx > length(ids) then
            exit
        end if
    
        ids &= get_children_ids(ids[idx])
    
        idx += 1
    end while
    
    return ids
end function

db:open()

object parents = mysql_query_rows(db, "SELECT id FROM messages WHERE parent_id=0 ORDER BY id")
if atom(parents) then
    printf(1, "%s\n", { mysql_error(db) })
    abort(1)
end if

for i = 1 to length(parents) do
    integer id = defaulted_value(parents[i][1], -1)
    object children = get_all_children_ids(id)
    sequence in_ = ""
    
    for j = 1 to length(children) do
        if j > 1 then
            in_ &= sprintf(",%d", { children[j] })
        else
            in_ &= sprintf("%d", { children[j] })
        end if
    end for

    sequence sql = sprintf("UPDATE messages SET topic_id=%d WHERE id IN (" & in_ & ")", { id })
    if mysql_query(db, sql) then
        printf(1, "Failed: %s\n%s\n", { sql, mysql_error(db) })
        abort(1)
    end if
end for


db:close()
