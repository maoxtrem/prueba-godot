extends Resource
class_name UpgradeData

enum EffectType {
	SPEED_PERCENT,
	MOVEMENT_COST_PERCENT,
	DAMAGE_PERCENT,
	ATTACK_RANGE_PERCENT,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_range(0.0, 100000.0, 0.1) var health_cost: float = 15.0
@export var effect_type: EffectType = EffectType.SPEED_PERCENT
@export_range(0.0, 10.0, 0.01) var effect_value: float = 0.2
@export_range(1, 100, 1) var max_level: int = 1

func is_valid() -> bool:
	return not id.strip_edges().is_empty() and not display_name.strip_edges().is_empty() and health_cost >= 0.0 and effect_value >= 0.0 and max_level > 0
