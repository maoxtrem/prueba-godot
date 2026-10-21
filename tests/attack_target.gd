extends Area2D
class_name AttackTestTarget

var received_damage: float = 0.0


func _ready() -> void:
	add_to_group(&"enemigos")
	collision_layer = 2
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	collision.shape = circle
	add_child(collision)


func recibir_dano(amount: float) -> void:
	received_damage += amount
