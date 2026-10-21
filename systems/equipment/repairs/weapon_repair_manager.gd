extends Node
class_name WeaponRepairManager

signal weapon_repaired(instance: WeaponInstance, restored: float, cost: int)
signal repair_failed(reason: String)

@export var material_id: String = "blood_fragment"
@export var full_repair_costs: Dictionary = {
	"vital_dagger": 10,
	"rusty_sword": 8,
	"crimson_spear": 12,
}

var inventory: InventoryComponent
var equipment: EquipmentComponent
var game_manager: GameManager

func setup(inventory_component: InventoryComponent, equipment_component: EquipmentComponent, game_manager_node: GameManager = null) -> void:
	inventory = inventory_component
	equipment = equipment_component
	game_manager = game_manager_node

func get_quote(instance: WeaponInstance) -> Dictionary:
	if instance == null:
		return _quote_failure("weapon_not_found")
	if not instance.has_durability():
		return _quote_failure("no_durability")
	var maximum := instance.item.weapon_stats.get_max_durability()
	var missing := maxf(maximum - instance.current_durability, 0.0)
	if missing <= 0.0:
		return {"success": false, "reason": "already_full", "current": instance.current_durability, "maximum": maximum, "cost": 0, "restored": 0.0}
	var full_cost := _get_full_cost(instance)
	if full_cost <= 0:
		return _quote_failure("invalid_repair_cost")
	var unit := maximum / float(full_cost)
	var available := inventory.get_item_quantity(material_id) if inventory != null else 0
	var possible_restore := minf(missing, float(available) * unit)
	var cost := _cost_for_restore(possible_restore, unit)
	return {
		"success": cost > 0,
		"reason": "" if cost > 0 else "insufficient_material",
		"current": instance.current_durability,
		"maximum": maximum,
		"missing": missing,
		"restored": possible_restore,
		"cost": cost,
		"full_cost": full_cost,
	}

func repair_weapon(instance_id: String) -> Dictionary:
	if _blocked():
		return _failure("game_over")
	var instance := _find_instance(instance_id)
	if instance == null:
		return _failure("weapon_not_found")
	var quote := get_quote(instance)
	if not quote.success:
		return _failure(String(quote.get("reason", "cannot_repair")))
	var old_durability := instance.current_durability
	var material := _material_item()
	var removed := inventory.remove_item(material_id, int(quote.cost)) if inventory != null else {"removed": 0}
	if int(removed.get("removed", 0)) != int(quote.cost):
		return _failure("material_transaction_failed")
	if not instance.restore_durability(old_durability + float(quote.restored)):
		if material != null:
			inventory.add_item(material, int(quote.cost))
		return _failure("durability_transaction_failed")
	weapon_repaired.emit(instance, float(quote.restored), int(quote.cost))
	return {"success": true, "instance": instance, "restored": float(quote.restored), "cost": int(quote.cost), "current": instance.current_durability}

func can_repair(instance: WeaponInstance) -> bool:
	return get_quote(instance).get("success", false) and not _blocked()

func _get_full_cost(instance: WeaponInstance) -> int:
	if instance == null or instance.item == null:
		return 0
	return maxi(int(full_repair_costs.get(instance.item.id, 0)), 0)

func _cost_for_restore(restored: float, unit: float) -> int:
	if restored <= 0.0 or unit <= 0.0:
		return 0
	return maxi(ceili(restored / unit), 1)

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

func _material_item() -> ItemData:
	for slot in inventory.get_slots():
		if slot.item != null and slot.item.id == material_id:
			return slot.item
	return null

func _blocked() -> bool:
	if game_manager != null and game_manager.is_game_over():
		return true
	return equipment != null and equipment.health != null and equipment.health.is_dead

func _failure(reason: String) -> Dictionary:
	repair_failed.emit(reason)
	return {"success": false, "reason": reason}

func _quote_failure(reason: String) -> Dictionary:
	return {"success": false, "reason": reason}
