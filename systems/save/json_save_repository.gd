extends SaveRepository
class_name JsonSaveRepository

@export var save_directory: String = "user://saves"
const FILE_PREFIX := "save_"
const FILE_SUFFIX := ".json"

func save_data(slot: String, data: Dictionary) -> Dictionary:
	if not _is_safe_slot(slot):
		return {"success": false, "error": "invalid_slot"}
	var directory_error := DirAccess.make_dir_recursive_absolute(save_directory)
	if directory_error != OK and not DirAccess.dir_exists_absolute(save_directory):
		return {"success": false, "error": "cannot_create_save_directory"}
	var path := _path_for(slot)
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "cannot_open_temporary_file"}
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return {"success": false, "error": "write_failed", "code": write_error}
	var check := _read_json_file(temporary_path)
	if not check.success:
		return {"success": false, "error": "temporary_validation_failed"}
	var rename_error := DirAccess.rename_absolute(temporary_path, path)
	if rename_error != OK:
		return {"success": false, "error": "replace_failed", "code": rename_error}
	return {"success": true, "path": path}

func load_data(slot: String) -> Dictionary:
	if not _is_safe_slot(slot):
		return {"success": false, "error": "invalid_slot"}
	var result := _read_json_file(_path_for(slot))
	if not result.success:
		return result
	return {"success": true, "data": result.data}

func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"success": false, "error": "file_not_found"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "error": "cannot_open_file"}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		return {"success": false, "error": "invalid_json"}
	return {"success": true, "data": parsed}

func _path_for(slot: String) -> String:
	return "%s/%s%s%s" % [save_directory, FILE_PREFIX, slot, FILE_SUFFIX]

func _is_safe_slot(slot: String) -> bool:
	return not slot.is_empty() and slot.length() <= 32 and slot.is_valid_filename()
