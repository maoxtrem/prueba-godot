extends Node
class_name StatusEffectComponent

signal status_effect_changed(effect_id: String, active: bool, remaining: float)

@export_node_path("Node") var attack_path: NodePath = NodePath("../AttackComponent")
@export_node_path("Node") var movement_path: NodePath = NodePath("../MovementCostComponent")

@onready var attack: AttackComponent = get_node_or_null(attack_path)
@onready var movement: MovementCostComponent = get_node_or_null(movement_path)

var active_effects: Dictionary = {}

func _process(delta: float) -> void:
	var expired: Array[String] = []
	for effect_id in active_effects:
		active_effects[effect_id]["remaining"] -= delta
		if active_effects[effect_id]["remaining"] <= 0.0:
			expired.append(effect_id)
	for effect_id in expired:
		active_effects.erase(effect_id)
		status_effect_changed.emit(effect_id, false, 0.0)
	if not expired.is_empty():
		_refresh_effective_stats()

func apply_effect(data: ConsumableData) -> bool:
	if data == null or not data.is_valid() or data.consumable_type != ConsumableData.ConsumableType.TEMPORARY_EFFECT:
		return false
	active_effects[data.effect_id] = {
		"data": data,
		"remaining": data.duration,
	}
	_refresh_effective_stats()
	status_effect_changed.emit(data.effect_id, true, data.duration)
	return true

func get_remaining(effect_id: String) -> float:
	if not active_effects.has(effect_id):
		return 0.0
	return maxf(float(active_effects[effect_id]["remaining"]), 0.0)

func has_effect(effect_id: String) -> bool:
	return active_effects.has(effect_id)

func _refresh_effective_stats() -> void:
	var damage_multiplier := 1.0
	var movement_multiplier := 1.0
	for effect_id in active_effects:
		var data: ConsumableData = active_effects[effect_id]["data"]
		match data.effect_type:
			ConsumableData.EffectType.FURY_DAMAGE:
				damage_multiplier = 1.0 + data.effect_magnitude
			ConsumableData.EffectType.ENDURANCE_MOVEMENT_COST:
				movement_multiplier = maxf(1.0 - data.effect_magnitude, 0.0)
	if attack != null:
		attack.aplicar_multiplicador_consumible(damage_multiplier)
	if movement != null:
		movement.aplicar_multiplicador_consumible(movement_multiplier)
