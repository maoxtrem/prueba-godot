extends RefCounted
class_name WeaponInstance

static var _next_id: int = 1

var item: ItemData
var instance_id: String
var upgrade_level: int = 0

func _init(item_data: ItemData, id: String = "") -> void:
	item = item_data
	instance_id = id if not id.is_empty() else _new_id()

func damage_multiplier() -> float:
	return 1.0 + 0.1 * upgrade_level

static func _new_id() -> String:
	var result := "weapon_%d" % _next_id
	_next_id += 1
	return result
