extends Node
class_name EquipmentComponent

enum EquipmentSlot {
	WEAPON,
}

signal equipment_changed(slot: EquipmentSlot, item: ItemData)

@export_node_path("Node") var inventory_path: NodePath = NodePath("../InventoryComponent")
@export_node_path("Node") var health_path: NodePath = NodePath("../HealthComponent")

@onready var inventory: InventoryComponent = get_node_or_null(inventory_path)
@onready var health: HealthComponent = get_node_or_null(health_path)

var equipped_weapon: ItemData


func equip_item(item_id: String) -> Dictionary:
	if _is_owner_dead():
		return _failure("player_dead")

	if inventory == null or item_id.strip_edges().is_empty():
		return _failure("invalid_item")

	var item := _find_inventory_item(item_id)
	if item == null:
		return _failure("not_in_inventory")

	if item.item_type != ItemData.ItemType.WEAPON:
		return _failure("not_a_weapon")

	if equipped_weapon != null and equipped_weapon.id == item.id:
		return _failure("already_equipped")

	var remove_result := inventory.remove_item(item.id, 1)
	if int(remove_result.get("removed", 0)) != 1:
		return _failure("could_not_remove_item")

	var previous_weapon := equipped_weapon
	if previous_weapon != null:
		var return_result := inventory.add_item(previous_weapon, 1)
		if int(return_result.get("added", 0)) != 1:
			# Rollback: el arma nueva vuelve al inventario y la anterior sigue equipada.
			inventory.add_item(item, 1)
			return _failure("no_space_for_previous_weapon")

	equipped_weapon = item
	equipment_changed.emit(EquipmentSlot.WEAPON, equipped_weapon)
	return {
		"success": true,
		"slot": EquipmentSlot.WEAPON,
		"item": equipped_weapon,
		"replaced": previous_weapon,
	}


func unequip_weapon() -> Dictionary:
	if _is_owner_dead():
		return _failure("player_dead")

	if equipped_weapon == null:
		return _failure("nothing_equipped")

	if inventory == null:
		return _failure("missing_inventory")

	var item_to_return := equipped_weapon
	var add_result := inventory.add_item(item_to_return, 1)
	if int(add_result.get("added", 0)) != 1:
		return _failure("inventory_full")

	equipped_weapon = null
	equipment_changed.emit(EquipmentSlot.WEAPON, null)
	return {
		"success": true,
		"slot": EquipmentSlot.WEAPON,
		"item": item_to_return,
	}


func get_equipped_item(slot: EquipmentSlot) -> ItemData:
	if slot == EquipmentSlot.WEAPON:
		return equipped_weapon

	return null


func _find_inventory_item(item_id: String) -> ItemData:
	for slot in inventory.get_slots():
		if slot.item != null and slot.item.id == item_id and slot.quantity > 0:
			return slot.item

	return null


func _is_owner_dead() -> bool:
	return health != null and health.is_dead


func _failure(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
	}
