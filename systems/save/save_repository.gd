extends RefCounted
class_name SaveRepository

func save_data(_slot: String, _data: Dictionary) -> Dictionary:
	return {"success": false, "error": "save_repository_not_implemented"}

func load_data(_slot: String) -> Dictionary:
	return {"success": false, "error": "save_repository_not_implemented"}
