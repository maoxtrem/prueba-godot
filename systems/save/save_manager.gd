extends Node
class_name SaveManager

signal save_completed(slot: String)
signal save_failed(slot: String, reason: String)

@export var default_slot: String = "slot1"
var repository: SaveRepository
var serializer: SaveSerializer
var game_root: Node

func setup(root_node: Node, repository_node: SaveRepository = null, serializer_node: SaveSerializer = null) -> void:
	game_root = root_node
	repository = repository_node if repository_node != null else JsonSaveRepository.new()
	serializer = serializer_node if serializer_node != null else SaveSerializer.new()

func save_game(slot: String = "") -> Dictionary:
	var target := slot if not slot.is_empty() else default_slot
	if game_root == null: return _failure(target, "missing_game_root")
	var data := serializer.serialize_game(game_root, target)
	var valid := serializer.validate(data)
	if not valid.success: return _failure(target, valid.error)
	var result := repository.save_data(target, data)
	if result.success: save_completed.emit(target)
	else: save_failed.emit(target, result.get("error", "save_failed"))
	return result

func load_game(slot: String = "", apply_state: bool = false) -> Dictionary:
	var target := slot if not slot.is_empty() else default_slot
	if repository == null: repository = JsonSaveRepository.new()
	var result := repository.load_data(target)
	if not result.success: return result
	if serializer == null: serializer = SaveSerializer.new()
	var loaded := serializer.deserialize(result.data)
	if loaded.success and apply_state:
		if game_root == null or not game_root.has_method("restore_from_save"):
			return {"success": false, "error": "restore_not_supported"}
		var restored: Dictionary = game_root.restore_from_save(loaded.data)
		if not restored.success: return restored
	return loaded

func has_save(slot: String = "") -> bool:
	var target := slot if not slot.is_empty() else default_slot
	if repository == null: repository = JsonSaveRepository.new()
	if not repository.has_data(target): return false
	var loaded := repository.load_data(target)
	if not loaded.success: return false
	if serializer == null: serializer = SaveSerializer.new()
	return serializer.validate(loaded.data).success

func delete_save(slot: String = "") -> Dictionary:
	var target := slot if not slot.is_empty() else default_slot
	if repository == null: repository = JsonSaveRepository.new()
	return repository.delete_data(target)

func _failure(slot: String, reason: String) -> Dictionary:
	save_failed.emit(slot, reason)
	return {"success": false, "error": reason}
