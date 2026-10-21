extends Resource
class_name WeaponStats

enum CombatType {
	MELEE_SHORT,
	MELEE_LONG,
	RANGED,
}

@export_range(0.0, 999999.0, 0.1) var damage: float = 0.0
@export_range(0.0, 999999.0, 0.1) var health_cost: float = 0.0
@export_range(0.0, 999999.0, 0.1) var attack_range: float = 0.0
@export_range(0.01, 999999.0, 0.01) var cooldown: float = 0.4
@export var combat_type: CombatType = CombatType.MELEE_SHORT
@export_range(0.0, 999999.0, 1.0) var projectile_speed: float = 0.0
@export_range(0.0, 999999.0, 0.1) var max_durability: float = 0.0
@export var cost_config: WeaponCostConfig


func validate() -> Dictionary:
	if not (
		damage >= 0.0
		and health_cost >= 0.0
		and attack_range >= 0.0
		and cooldown > 0.0
		and projectile_speed >= 0.0
		and max_durability >= 0.0
	):
		return {"success": false, "error": "invalid_base_stats"}
	if cost_config == null:
		return {"success": true, "error": ""}
	# El costo legacy y el configurable no pueden competir como fuentes de verdad.
	if health_cost != 0.0:
		return {"success": false, "error": "legacy_cost_conflict"}
	var config_result := cost_config.validate()
	if not bool(config_result["success"]):
		return {"success": false, "error": "cost_config_" + str(config_result["error"])}
	if cost_config.uses_durability and max_durability <= 0.0:
		return {"success": false, "error": "max_durability_required"}
	if combat_type == CombatType.RANGED and projectile_speed <= 0.0:
		return {"success": false, "error": "projectile_speed_required"}
	return {"success": true, "error": ""}

func is_valid() -> bool:
	return bool(validate()["success"])

func get_health_cost() -> float:
	return cost_config.health_cost if cost_config != null else health_cost

func get_durability_cost() -> float:
	return cost_config.durability_cost if cost_config != null else 0.0

func uses_durability() -> bool:
	return cost_config != null and cost_config.uses_durability

func uses_ammo() -> bool:
	return cost_config != null and cost_config.uses_ammo

func get_ammo_item_id() -> String:
	return cost_config.ammo_item_id if cost_config != null else ""

func get_ammo_per_attack() -> int:
	return cost_config.ammo_per_attack if cost_config != null else 0

func get_max_durability() -> float:
	return max_durability
