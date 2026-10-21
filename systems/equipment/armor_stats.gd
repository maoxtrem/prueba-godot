extends Resource
class_name ArmorStats

@export_range(0.0, 1.0, 0.01) var damage_reduction: float = 0.0
@export_range(-1.0, 1.0, 0.01) var movement_speed_modifier: float = 0.0
@export_range(-1.0, 1.0, 0.01) var movement_cost_modifier: float = 0.0

func is_valid() -> bool:
	return damage_reduction >= 0.0 and damage_reduction <= 1.0 and movement_speed_modifier > -1.0 and movement_cost_modifier > -1.0

func damage_multiplier() -> float:
	return 1.0 - clampf(damage_reduction, 0.0, 1.0)

func speed_multiplier() -> float:
	return maxf(1.0 + movement_speed_modifier, 0.0)

func movement_cost_multiplier() -> float:
	return maxf(1.0 + movement_cost_modifier, 0.0)
