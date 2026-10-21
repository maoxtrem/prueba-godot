extends RefCounted
class_name WeaponInstance

static var _next_id: int = 1

var item: ItemData
var instance_id: String
var upgrade_level: int = 0
var current_durability: float = -1.0

signal durability_changed(instance: WeaponInstance, current: float, maximum: float)

func _init(item_data: ItemData, id: String = "") -> void:
	item = item_data
	instance_id = id if not id.is_empty() else _new_id()
	current_durability = initial_durability()

func initial_durability() -> float:
	if item == null or item.weapon_stats == null or not item.weapon_stats.uses_durability():
		return -1.0
	return item.weapon_stats.get_max_durability()

func has_durability() -> bool:
	return current_durability >= 0.0 and item != null and item.weapon_stats != null and item.weapon_stats.uses_durability()

func is_broken() -> bool:
	return has_durability() and current_durability <= 0.0

func can_spend_durability() -> bool:
	if not has_durability():
		return true
	return current_durability >= item.weapon_stats.get_durability_cost()

func consume_durability() -> bool:
	if not has_durability():
		return true
	var cost := item.weapon_stats.get_durability_cost()
	if cost <= 0.0 or current_durability < cost:
		return false
	current_durability = clampf(current_durability - cost, 0.0, item.weapon_stats.get_max_durability())
	durability_changed.emit(self, current_durability, item.weapon_stats.get_max_durability())
	return true

func restore_durability(value: float = -1.0) -> bool:
	if not has_durability():
		current_durability = -1.0
		return true
	var maximum := item.weapon_stats.get_max_durability()
	var restored := maximum if value < 0.0 else value
	if restored < 0.0 or restored > maximum:
		return false
	var changed := not is_equal_approx(current_durability, restored)
	current_durability = restored
	if changed:
		durability_changed.emit(self, current_durability, maximum)
	return true

func damage_multiplier() -> float:
	return 1.0 + 0.1 * upgrade_level

static func _new_id() -> String:
	var result := "weapon_%d" % _next_id
	_next_id += 1
	return result
