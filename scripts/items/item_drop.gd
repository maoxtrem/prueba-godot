extends Area2D
class_name ItemDrop

@onready var sprite: Sprite2D = $Sprite2D

var item_data: ItemData
var quantity: int = 0


func _ready() -> void:
	queue_redraw()


func configurar(item: ItemData, amount: int) -> void:
	item_data = item
	quantity = maxi(amount, 0)

	if not is_node_ready():
		return

	_actualizar_visual()


func recoger_cantidad(amount: int) -> int:
	if amount <= 0 or quantity <= 0:
		return 0

	var collected := mini(amount, quantity)
	quantity -= collected

	if quantity <= 0:
		queue_free()
	else:
		_actualizar_visual()

	return collected


func _actualizar_visual() -> void:
	if item_data == null:
		sprite.visible = false
		queue_redraw()
		return

	sprite.texture = item_data.icon
	sprite.visible = item_data.icon != null
	queue_redraw()


func _draw() -> void:
	if item_data != null and item_data.icon != null:
		return

	# Marcador provisional para ítems sin icono.
	draw_circle(Vector2.ZERO, 16.0, Color(0.85, 0.2, 0.3, 1.0))
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.65, 0.2, 1.0))
