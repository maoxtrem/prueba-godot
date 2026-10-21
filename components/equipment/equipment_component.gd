extends Node
class_name EquipmentComponent

enum EquipmentSlot {
	WEAPON,
	ARMOR,
}

signal equipment_changed(slot: EquipmentSlot, item: ItemData)
signal weapon_instance_changed(instance: WeaponInstance)
signal weapon_durability_changed(instance: WeaponInstance, current: float, maximum: float)

@export_node_path("Node") var inventory_path: NodePath = NodePath("../InventoryComponent")
@export_node_path("Node") var health_path: NodePath = NodePath("../HealthComponent")

@onready var inventory: InventoryComponent = get_node_or_null(inventory_path)
@onready var health: HealthComponent = get_node_or_null(health_path)

var equipped_weapon: ItemData
var equipped_weapon_instance: WeaponInstance
var equipped_armor: ItemData


func equip_item(item_id: String, instance_id: String = "") -> Dictionary:
	if _blocked():
		return _failure("player_dead" if _is_owner_dead() else "game_over")

	if inventory == null or item_id.strip_edges().is_empty():
		return _failure("invalid_item")

	var selected_slot := _find_inventory_slot(item_id, instance_id)
	if selected_slot == null:
		return _failure("not_in_inventory")
	var item: ItemData = selected_slot.item

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

	var previous_weapon_instance := equipped_weapon_instance
	var removed_slot_index := inventory.slots.find(selected_slot)
	if removed_slot_index < 0:
		return _failure("could_not_remove_item")
	inventory.slots.remove_at(removed_slot_index)
	inventory._emit_inventory_changed()

	if previous != null:
		var return_result := inventory.add_weapon_instance(previous_weapon_instance) if target_slot == EquipmentSlot.WEAPON else inventory.add_item(previous, 1)
		if int(return_result.get("added", 0)) != 1:
			if target_slot == EquipmentSlot.WEAPON:
				inventory.add_weapon_instance(selected_slot.weapon_instance)
			else:
				inventory.add_item(item, 1)
			return _failure("no_space_for_previous_item")

	_set_equipped(target_slot, item)
	if target_slot == EquipmentSlot.WEAPON:
		_disconnect_weapon_instance(previous_weapon_instance)
		equipped_weapon_instance = selected_slot.weapon_instance
		_connect_weapon_instance(equipped_weapon_instance)
	equipment_changed.emit(target_slot, item)
	if target_slot == EquipmentSlot.WEAPON:
		weapon_instance_changed.emit(equipped_weapon_instance)
	return {
		"success": true,
		"slot": target_slot,
		"item": item,
		"replaced": previous,
		"instance": selected_slot.weapon_instance,
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
	var add_result: Dictionary
	if slot == EquipmentSlot.WEAPON:
		add_result = inventory.add_weapon_instance(equipped_weapon_instance)
	else:
		add_result = inventory.add_item(item_to_return, 1)
	if int(add_result.get("added", 0)) != 1:
		return _failure("inventory_full")
	_set_equipped(slot, null)
	if slot == EquipmentSlot.WEAPON:
		_disconnect_weapon_instance(equipped_weapon_instance)
		equipped_weapon_instance = null
	equipment_changed.emit(slot, null)
	if slot == EquipmentSlot.WEAPON:
		weapon_instance_changed.emit(null)
	return {"success": true, "slot": slot, "item": item_to_return}


func get_equipped_item(slot: EquipmentSlot) -> ItemData:
	return equipped_weapon if slot == EquipmentSlot.WEAPON else equipped_armor

func get_equipped_weapon_instance() -> WeaponInstance:
	return equipped_weapon_instance

func restore_equipment(weapon_instance: WeaponInstance, armor: ItemData) -> void:
	_disconnect_weapon_instance(equipped_weapon_instance)
	equipped_weapon_instance = weapon_instance
	_connect_weapon_instance(equipped_weapon_instance)
	equipped_weapon = weapon_instance.item if weapon_instance != null else null
	equipped_armor = armor
	equipment_changed.emit(EquipmentSlot.WEAPON, equipped_weapon)
	weapon_instance_changed.emit(equipped_weapon_instance)
	equipment_changed.emit(EquipmentSlot.ARMOR, equipped_armor)

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


func _find_inventory_slot(item_id: String, instance_id: String = "") -> InventorySlot:
	for slot in inventory.get_slots():
		if slot.item != null and slot.item.id == item_id and slot.quantity > 0:
			if instance_id.is_empty() or (slot.weapon_instance != null and slot.weapon_instance.instance_id == instance_id):
				return slot

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

func _connect_weapon_instance(instance: WeaponInstance) -> void:
	if instance != null and not instance.durability_changed.is_connected(_on_weapon_durability_changed):
		instance.durability_changed.connect(_on_weapon_durability_changed)

func _disconnect_weapon_instance(instance: WeaponInstance) -> void:
	if instance != null and instance.durability_changed.is_connected(_on_weapon_durability_changed):
		instance.durability_changed.disconnect(_on_weapon_durability_changed)

func _on_weapon_durability_changed(instance: WeaponInstance, current: float, maximum: float) -> void:
	weapon_durability_changed.emit(instance, current, maximum)
