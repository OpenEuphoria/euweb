include std/io.e
include std/map.e
include std/datetime.e

public procedure dump_map(sequence fname_prefix, map m)
	sequence base_fn = sprintf("%s_%s.",  { fname_prefix, datetime:format(now(), "%Y%m%d%H%M%S") }) 
	save_map(m, base_fn & "map")
end procedure
