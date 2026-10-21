extends Resource
class_name ConsumableData

enum ConsumableType {
	HEAL,
	TEMPORARY_EFFECT,
	MAX_HEALTH_INCREASE,
}

enum EffectType {
	NONE,
	FURY_DAMAGE,
	ENDURANCE_MOVEMENT_COST,
}

@export var effect_id: String = ""
@export var consumable_type: ConsumableType = ConsumableType.HEAL
@export_range(0.0, 100000.0, 0.1) var healing_amount: float = 0.0
@export var effect_type: EffectType = EffectType.NONE
@export_range(0.0, 10.0, 0.01) var effect_magnitude: float = 0.0
@export_range(0.0, 86400.0, 0.1) var duration: float = 0.0
@export_range(0.0, 100000.0, 0.1) var max_health_increase: float = 0.0

func is_valid() -> bool:
	if effect_id.strip_edges().is_empty():
		return false
	if consumable_type == ConsumableType.HEAL:
		return healing_amount > 0.0
	if consumable_type == ConsumableType.MAX_HEALTH_INCREASE:
		return max_health_increase > 0.0
	return effect_type != EffectType.NONE and effect_magnitude > 0.0 and duration > 0.0
