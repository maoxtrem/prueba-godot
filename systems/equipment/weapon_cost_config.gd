extends Resource
class_name WeaponCostConfig

@export_range(0.0, 999999.0, 0.1) var health_cost: float = 0.0
@export_range(0.0, 999999.0, 0.1) var durability_cost: float = 0.0
@export var ammo_item_id: String = ""
@export_range(0, 999999, 1) var ammo_per_attack: int = 0
@export var uses_durability: bool = false
@export var uses_ammo: bool = false

func is_valid() -> bool:
	if health_cost < 0.0 or durability_cost < 0.0 or ammo_per_attack < 0:
		return false
	if uses_durability:
		if durability_cost <= 0.0:
			return false
	elif durability_cost != 0.0:
		return false
	if uses_ammo:
		var ammo_id := ammo_item_id.strip_edges()
		return not ammo_id.is_empty() and ammo_id == ammo_item_id and ammo_id.is_valid_filename() and not ammo_id.contains("/") and not ammo_id.contains("\\") and ammo_per_attack > 0
	return ammo_item_id.strip_edges().is_empty() and ammo_per_attack == 0

func uses_health() -> bool:
	return health_cost > 0.0
