extends Resource
class_name WeaponCostConfig

@export_range(0.0, 999999.0, 0.1) var health_cost: float = 0.0
@export_range(0.0, 999999.0, 0.1) var durability_cost: float = 0.0
@export var ammo_item_id: String = ""
@export_range(0, 999999, 1) var ammo_per_attack: int = 0
@export var uses_durability: bool = false
@export var uses_ammo: bool = false

func validate() -> Dictionary:
	if health_cost < 0.0:
		return {"success": false, "error": "negative_health_cost"}
	if durability_cost < 0.0:
		return {"success": false, "error": "negative_durability_cost"}
	if ammo_per_attack < 0:
		return {"success": false, "error": "negative_ammo_cost"}
	if uses_durability and durability_cost <= 0.0:
		return {"success": false, "error": "durability_cost_required"}
	if not uses_durability and durability_cost != 0.0:
		return {"success": false, "error": "durability_flag_required"}
	if uses_ammo:
		var ammo_id := ammo_item_id.strip_edges()
		if ammo_id.is_empty() or ammo_id != ammo_item_id:
			return {"success": false, "error": "ammo_id_required"}
		if not ammo_id.is_valid_filename() or ammo_id.contains("/") or ammo_id.contains("\\"):
			return {"success": false, "error": "invalid_ammo_id"}
		if ammo_per_attack <= 0:
			return {"success": false, "error": "ammo_cost_required"}
	elif not ammo_item_id.strip_edges().is_empty() or ammo_per_attack != 0:
		return {"success": false, "error": "ammo_flag_required"}
	return {"success": true, "error": ""}

func is_valid() -> bool:
	return bool(validate()["success"])

func uses_health() -> bool:
	return health_cost > 0.0
