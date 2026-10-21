extends Node
class_name EquipmentComponent

enum EquipmentSlot {
	WEAPON,
	ARMOR,
}

signal equipment_changed(slot: EquipmentSlot, item: ItemData)

@export_node_path("Node") var inventory_path: NodePath = NodePath("../InventoryComponent")
@export_node_path("Node") var health_path: NodePath = NodePath("../HealthComponent")

@onready var inventory: InventoryComponent = get_node_or_null(inventory_path)
@onready var health: HealthComponent = get_node_or_null(health_path)

var equipped_weapon: ItemData
var equipped_armor: ItemData


func equip_item(item_id: String) -> Dictionary:
	if _blocked():
		return _failure("player_dead" if _is_owner_dead() else "game_over")

	if inventory == null or item_id.strip_edges().is_empty():
		return _failure("invalid_item")

	var item := _find_inventory_item(item_id)
	if item == null:
		return _failure("not_in_inventory")

	var target_slot: EquipmentSlot
	if item.item_type == ItemData.ItemType.WEAPON:
		target_slot = EquipmentSlot.WEAPON
	elif item.item_type == ItemData.ItemType.ARMOR:
		if item.armor_stats == null or not item.armor_stats.is_valid():
			return _failure("invalid_armor")
		target_slot = EquipmentSlot.ARMOR
	else:
		return _failure("not_equipable")

	var previous := get_equipped_item(target_slot)
	if previous != null and previous.id == item.id:
		return _failure("already_equipped")

	var remove_result := inventory.remove_item(item.id, 1)
	if int(remove_result.get("removed", 0)) != 1:
		return _failure("could_not_remove_item")

	if previous != null:
		var return_result := inventory.add_item(previous, 1)
		if int(return_result.get("added", 0)) != 1:
			inventory.add_item(item, 1)
			return _failure("no_space_for_previous_item")

	_set_equipped(target_slot, item)
	equipment_changed.emit(target_slot, item)
	return {
		"success": true,
		"slot": target_slot,
		"item": item,
		"replaced": previous,
	}


func unequip_weapon() -> Dictionary:
	return unequip_item(EquipmentSlot.WEAPON)

func unequip_armor() -> Dictionary:
	return unequip_item(EquipmentSlot.ARMOR)

func unequip_item(slot: EquipmentSlot) -> Dictionary:
	if _blocked():
		return _failure("player_dead" if _is_owner_dead() else "game_over")
	var item_to_return := get_equipped_item(slot)
	if item_to_return == null:
		return _failure("nothing_equipped")
	if inventory == null:
		return _failure("missing_inventory")
	var add_result := inventory.add_item(item_to_return, 1)
	if int(add_result.get("added", 0)) != 1:
		return _failure("inventory_full")
	_set_equipped(slot, null)
	equipment_changed.emit(slot, null)
	return {"success": true, "slot": slot, "item": item_to_return}


func get_equipped_item(slot: EquipmentSlot) -> ItemData:
	return equipped_weapon if slot == EquipmentSlot.WEAPON else equipped_armor

func get_enemy_damage_multiplier() -> float:
	if equipped_armor == null or equipped_armor.armor_stats == null:
		return 1.0
	return equipped_armor.armor_stats.damage_multiplier()

func get_armor_speed_multiplier() -> float:
	if equipped_armor == null or equipped_armor.armor_stats == null:
		return 1.0
	return equipped_armor.armor_stats.speed_multiplier()

func get_armor_movement_cost_multiplier() -> float:
	if equipped_armor == null or equipped_armor.armor_stats == null:
		return 1.0
	return equipped_armor.armor_stats.movement_cost_multiplier()

func _set_equipped(slot: EquipmentSlot, item: ItemData) -> void:
	if slot == EquipmentSlot.WEAPON:
		equipped_weapon = item
	else:
		equipped_armor = item


func _find_inventory_item(item_id: String) -> ItemData:
	for slot in inventory.get_slots():
		if slot.item != null and slot.item.id == item_id and slot.quantity > 0:
			return slot.item

	return null


func _is_owner_dead() -> bool:
	return health != null and health.is_dead

func _is_game_over() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.has_method("is_game_over") and scene.is_game_over()

func _blocked() -> bool:
	return _is_owner_dead() or _is_game_over()


func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
	}
