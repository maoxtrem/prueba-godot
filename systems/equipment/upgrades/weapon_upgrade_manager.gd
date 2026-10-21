extends Node
class_name WeaponUpgradeManager

signal weapon_upgraded(instance: WeaponInstance, new_level: int)
signal upgrade_failed(reason: String)

@export var material_id: String = "blood_fragment"
@export var costs: Array[int] = [5, 10, 20]
@export var max_level: int = 3

var inventory: InventoryComponent
var equipment: EquipmentComponent
var game_manager: GameManager

func setup(inventory_component: InventoryComponent, equipment_component: EquipmentComponent, game_manager_node: GameManager = null) -> void:
	inventory = inventory_component
	equipment = equipment_component
	game_manager = game_manager_node

func get_next_cost(instance: WeaponInstance) -> int:
	if instance == null or instance.upgrade_level >= max_level:
		return 0
	if instance.upgrade_level < costs.size():
		return maxi(costs[instance.upgrade_level], 0)
	return 0

func can_upgrade(instance: WeaponInstance) -> bool:
	return instance != null and instance.upgrade_level < max_level and inventory != null and inventory.has_item(material_id, get_next_cost(instance)) and not _blocked()

func upgrade_weapon(instance_id: String) -> Dictionary:
	if _blocked():
		return _failure("game_over")
	var instance := _find_instance(instance_id)
	if instance == null:
		return _failure("weapon_not_found")
	if instance.upgrade_level >= max_level:
		return _failure("max_level")
	var cost := get_next_cost(instance)
	if inventory == null or not inventory.has_item(material_id, cost):
		return _failure("insufficient_material")
	var removed := inventory.remove_item(material_id, cost)
	if int(removed.get("removed", 0)) != cost:
		return _failure("material_transaction_failed")
	instance.upgrade_level += 1
	if equipment != null and equipment.get_equipped_weapon_instance() == instance:
		equipment.weapon_instance_changed.emit(instance)
	weapon_upgraded.emit(instance, instance.upgrade_level)
	return {"success": true, "instance": instance, "level": instance.upgrade_level, "cost": cost}

func _find_instance(instance_id: String) -> WeaponInstance:
	if instance_id.is_empty():
		return null
	if equipment != null and equipment.get_equipped_weapon_instance() != null and equipment.get_equipped_weapon_instance().instance_id == instance_id:
		return equipment.get_equipped_weapon_instance()
	if inventory != null:
		for slot in inventory.get_slots():
			if slot.weapon_instance != null and slot.weapon_instance.instance_id == instance_id:
				return slot.weapon_instance
	return null

func _blocked() -> bool:
	if game_manager != null and game_manager.is_game_over():
		return true
	return equipment != null and equipment.health != null and equipment.health.is_dead

func _failure(reason: String) -> Dictionary:
	upgrade_failed.emit(reason)
	return {"success": false, "reason": reason}
