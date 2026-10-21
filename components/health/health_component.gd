
extends Node
class_name HealthComponent

signal health_changed(current: float, maximum: float)
signal max_health_changed(previous: float, maximum: float)
signal died

@export var max_health: float = 100.0

var current_health: float = 0.0
var is_dead: bool = false
var debug_settings: DebugSettings
var debug_player_context: bool = false


func configure_debug(settings: DebugSettings, is_player: bool = false) -> void:
	debug_settings = settings
	debug_player_context = is_player

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func reset_health() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)


func set_max_health(value: float, preserve_current: bool = false) -> bool:
	if value <= 0.0 or not is_finite(value):
		return false
	var previous := max_health
	max_health = value
	if preserve_current:
		current_health = clampf(current_health, 0.0, max_health)
	else:
		current_health = minf(current_health, max_health)
	max_health_changed.emit(previous, max_health)
	health_changed.emit(current_health, max_health)
	return true


func increase_max_health(amount: float, restore_amount: float = 0.0) -> bool:
	if amount <= 0.0 or not is_finite(amount) or not is_finite(restore_amount):
		return false
	var previous := max_health
	var next_max := max_health + amount
	if not is_finite(next_max) or next_max <= 0.0:
		return false
	max_health = next_max
	current_health = clampf(current_health + maxf(restore_amount, 0.0), 0.0, max_health)
	max_health_changed.emit(previous, max_health)
	health_changed.emit(current_health, max_health)
	return true


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	if debug_player_context and debug_settings != null and debug_settings.is_player_invulnerable():
		return
	if debug_player_context and debug_settings != null and debug_settings.has_infinite_health():
		return

	current_health = maxf(current_health - amount, 0.0)
	_notify_change()



func spend_health(amount: float) -> bool:
	if is_dead or amount <= 0.0:
		return false
	if debug_player_context and debug_settings != null and debug_settings.has_infinite_health():
		return true

	if current_health <= amount:
		return false

	current_health -= amount
	_notify_change()

	return true



func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	current_health = minf(
		current_health + amount,
		max_health
	)

	_notify_change()


func _notify_change() -> void:
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0 and not is_dead:
		is_dead = true
		died.emit()


func drain_health(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	if debug_player_context and debug_settings != null and debug_settings.has_infinite_health():
		return

	current_health = maxf(
		current_health - amount,
		0.0
	)

	_notify_change()
