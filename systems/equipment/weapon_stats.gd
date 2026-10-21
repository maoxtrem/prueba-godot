extends Resource
class_name WeaponStats

@export_range(0.0, 999999.0, 0.1) var damage: float = 0.0
@export_range(0.0, 999999.0, 0.1) var health_cost: float = 0.0
@export_range(0.0, 999999.0, 0.1) var attack_range: float = 0.0
@export_range(0.01, 999999.0, 0.01) var cooldown: float = 0.4


func is_valid() -> bool:
	return (
		damage >= 0.0
		and health_cost >= 0.0
		and attack_range >= 0.0
		and cooldown > 0.0
	)
