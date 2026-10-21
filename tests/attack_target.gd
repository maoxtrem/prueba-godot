extends Node2D
class_name AttackTestTarget

var received_damage: float = 0.0


func _ready() -> void:
	add_to_group(&"enemigos")


func recibir_dano(amount: float) -> void:
	received_damage += amount
