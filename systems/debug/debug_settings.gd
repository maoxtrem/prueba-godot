extends Resource
class_name DebugSettings

@export var debug_enabled: bool = false
@export var player_invulnerable: bool = false
@export var infinite_health: bool = false
@export_range(0.0, 10.0, 0.01) var enemy_damage_multiplier: float = 0.1


func is_player_invulnerable() -> bool:
	return debug_enabled and player_invulnerable


func has_infinite_health() -> bool:
	return debug_enabled and infinite_health


func get_enemy_damage_multiplier() -> float:
	if not debug_enabled:
		return 1.0
	return maxf(enemy_damage_multiplier, 0.0)
