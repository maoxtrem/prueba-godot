
extends Node
class_name HealthComponent

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0

var current_health: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func reset_health() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	_notify_change()



func spend_health(amount: float) -> bool:
	if is_dead or amount <= 0.0:
		return false

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

	current_health = maxf(
		current_health - amount,
		0.0
	)

	_notify_change()
