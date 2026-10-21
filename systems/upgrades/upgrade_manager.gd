extends Node
class_name UpgradeManager

signal upgrade_purchased(upgrade: UpgradeData, new_level: int, health_remaining: float)
signal upgrades_changed

@export var available_upgrades: Array[UpgradeData] = []

var health: HealthComponent
var attack: AttackComponent
var movement: MovementCostComponent
var player: Node
var game_manager: GameManager
var upgrade_levels: Dictionary = {}

func setup(health_component: HealthComponent, attack_component: AttackComponent, movement_component: MovementCostComponent, player_node: Node, game_manager_node: GameManager = null) -> void:
	health = health_component
	attack = attack_component
	movement = movement_component
	player = player_node
	game_manager = game_manager_node
	_refresh_effective_stats()

func purchase_upgrade(upgrade_id: String) -> bool:
	var upgrade := _find_upgrade(upgrade_id)
	if upgrade == null or not upgrade.is_valid() or health == null or health.is_dead:
		return false
	if game_manager != null and game_manager.is_game_over():
		return false
	var level: int = int(upgrade_levels.get(upgrade.id, 0))
	if level >= upgrade.max_level:
		return false
	if upgrade.health_cost > 0.0 and not health.spend_health(upgrade.health_cost):
		return false
	level += 1
	upgrade_levels[upgrade.id] = level
	_refresh_effective_stats()
	upgrade_purchased.emit(upgrade, level, health.current_health)
	upgrades_changed.emit()
	return true

func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))

func reset_upgrades() -> void:
	upgrade_levels.clear()
	_refresh_effective_stats()
	upgrades_changed.emit()

func restore_levels(restored_levels: Dictionary) -> bool:
	for key in restored_levels.keys():
		var upgrade := _find_upgrade(String(key))
		var level := int(restored_levels[key])
		if upgrade == null or level < 0 or level > upgrade.max_level:
			return false
	upgrade_levels.clear()
	for key in restored_levels.keys():
		upgrade_levels[String(key)] = int(restored_levels[key])
	_refresh_effective_stats()
	upgrades_changed.emit()
	return true

func _find_upgrade(upgrade_id: String) -> UpgradeData:
	for upgrade in available_upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null

func _refresh_effective_stats() -> void:
	var speed_multiplier := 1.0
	var movement_cost_multiplier := 1.0
	var damage_multiplier := 1.0
	var range_multiplier := 1.0
	for upgrade in available_upgrades:
		if upgrade == null or not upgrade.is_valid():
			continue
		var level := get_upgrade_level(upgrade.id)
		if level <= 0:
			continue
		var effect := UpgradeEffect.new(upgrade.effect_type, upgrade.effect_value)
		match upgrade.effect_type:
			UpgradeData.EffectType.SPEED_PERCENT:
				speed_multiplier *= effect.multiplier(level)
			UpgradeData.EffectType.MOVEMENT_COST_PERCENT:
				movement_cost_multiplier *= effect.multiplier(level)
			UpgradeData.EffectType.DAMAGE_PERCENT:
				damage_multiplier *= effect.multiplier(level)
			UpgradeData.EffectType.ATTACK_RANGE_PERCENT:
				range_multiplier *= effect.multiplier(level)
	if player != null and player.has_method("aplicar_velocidad_efectiva"):
		player.aplicar_velocidad_efectiva(player.velocidad * speed_multiplier)
	if movement != null:
		movement.aplicar_multiplicador_efectivo(movement.multiplicador_movimiento_base * movement_cost_multiplier)
	if attack != null:
		attack.aplicar_multiplicadores_mejoras(damage_multiplier, range_multiplier)
