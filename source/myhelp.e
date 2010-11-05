include std/datetime.e
include edbi/edbi.e

include drivers/mysql/edbi_mysql.e
public constant edbi_results = {
routine_id("edbi_open"),
routine_id("edbi_close"),
routine_id("edbi_error_code"),
routine_id("edbi_error_message"),
routine_id("edbi_execute"),
routine_id("edbi_last_insert_id"),
routine_id("edbi_total_changes"),
routine_id("edbi_query"),
routine_id("edbi_next"),
routine_id("edbi_closeq"),
$ }

