extends Node
class_name ConsumableComponent

signal consumable_used(item: ItemData, data: ConsumableData)
signal consumable_use_failed(item_id: String, reason: String)

@export_node_path("Node") var inventory_path: NodePath = NodePath("../InventoryComponent")
@export_node_path("Node") var health_path: NodePath = NodePath("../HealthComponent")
@export_node_path("Node") var status_effect_path: NodePath = NodePath("../StatusEffectComponent")

@onready var inventory: InventoryComponent = get_node_or_null(inventory_path)
@onready var health: HealthComponent = get_node_or_null(health_path)
@onready var status_effects: StatusEffectComponent = get_node_or_null(status_effect_path)

var use_in_progress := false

func use_item(item_id: String) -> Dictionary:
	var validation := can_use_item(item_id)
	if not validation.get("success", false):
		return _failure(item_id, validation.get("reason", "invalid_use"))
	var item: ItemData = validation.item
	var data: ConsumableData = validation.data

	use_in_progress = true
	var remove_result := inventory.remove_item(item_id, 1)
	if int(remove_result.get("removed", 0)) != 1:
		use_in_progress = false
		return _failure(item_id, "could_not_remove_item")

	var applied := true
	if data.consumable_type == ConsumableData.ConsumableType.HEAL:
		health.heal(data.healing_amount)
	else:
		applied = status_effects.apply_effect(data)
	if not applied:
		# La operación es atómica: si el efecto falla, se devuelve la unidad.
		inventory.add_item(item, 1)
		use_in_progress = false
		return _failure(item_id, "effect_failed")

	use_in_progress = false
	consumable_used.emit(item, data)
	return {"success": true, "item": item, "data": data}

func can_use_item(item_id: String) -> Dictionary:
	if use_in_progress:
		return {"success": false, "reason": "use_in_progress"}
	if health == null or health.is_dead:
		return {"success": false, "reason": "player_dead"}
	if _is_game_over():
		return {"success": false, "reason": "game_over"}
	if inventory == null or not inventory.has_item(item_id):
		return {"success": false, "reason": "not_in_inventory"}
	var item := _find_item(item_id)
	if item == null or item.item_type != ItemData.ItemType.CONSUMABLE or item.consumable_data == null:
		return {"success": false, "reason": "not_consumable"}
	var data := item.consumable_data
	if not data.is_valid():
		return {"success": false, "reason": "invalid_consumable"}
	if data.consumable_type == ConsumableData.ConsumableType.HEAL and health.current_health >= health.max_health:
		return {"success": false, "reason": "health_full"}
	if data.consumable_type == ConsumableData.ConsumableType.TEMPORARY_EFFECT and status_effects == null:
		return {"success": false, "reason": "missing_status_component"}
	return {"success": true, "item": item, "data": data}

func _find_item(item_id: String) -> ItemData:
	if inventory == null:
		return null
	for slot in inventory.get_slots():
		if slot.item != null and slot.item.id == item_id and slot.quantity > 0:
			return slot.item
	return null

func _is_game_over() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.has_method("is_game_over") and scene.is_game_over()

func _failure(item_id: String, reason: String) -> Dictionary:
	consumable_use_failed.emit(item_id, reason)
	return {"success": false, "reason": reason}
