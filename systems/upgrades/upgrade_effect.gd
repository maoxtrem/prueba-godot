extends RefCounted
class_name UpgradeEffect

var effect_type: UpgradeData.EffectType
var value: float

func _init(type: UpgradeData.EffectType, effect_value: float) -> void:
	effect_type = type
	value = maxf(effect_value, 0.0)

func multiplier(level: int) -> float:
	var scaled_value := value * maxi(level, 0)
	if effect_type == UpgradeData.EffectType.MOVEMENT_COST_PERCENT:
		return maxf(1.0 - scaled_value, 0.0)
	return 1.0 + scaled_value
