extends Area2D
class_name PickupComponent

signal item_collected(item: ItemData, quantity: int)
signal pickup_target_changed(drop: ItemDrop)

@export_node_path("Node") var inventory_path: NodePath = NodePath("../InventoryComponent")
@export_node_path("Node") var health_path: NodePath = NodePath("../HealthComponent")
@export var pickup_range: float = 100.0

@onready var inventory: InventoryComponent = get_node_or_null(inventory_path)
@onready var health: HealthComponent = get_node_or_null(health_path)
@onready var prompt: Label = $PickupPrompt
@onready var sensor_shape: CollisionShape2D = $CollisionShape2D

var nearby_drops: Array[ItemDrop] = []
var closest_drop: ItemDrop
var pickup_in_progress: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_update_sensor_range()
	_update_nearest_drop()


func _physics_process(_delta: float) -> void:
	_update_nearest_drop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		intentar_recoger()


func intentar_recoger() -> bool:
	if pickup_in_progress or _is_owner_dead():
		return false

	_update_nearest_drop()
	if not is_instance_valid(closest_drop):
		return false

	if inventory == null or closest_drop.item_data == null or closest_drop.quantity <= 0:
		return false

	var available_space := inventory.get_available_space(closest_drop.item_data)
	if available_space <= 0:
		return false

	pickup_in_progress = true
	var quantity_to_add := mini(closest_drop.quantity, available_space)
	var result := inventory.add_item(
		closest_drop.item_data,
		quantity_to_add
	)
	var added := int(result.get("added", 0))

	if added > 0 and is_instance_valid(closest_drop):
		var collected_item := closest_drop.item_data
		var collected := closest_drop.recoger_cantidad(added)
		if collected > 0:
			item_collected.emit(collected_item, collected)

	pickup_in_progress = false
	_update_nearest_drop()
	return added > 0


func _on_area_entered(area: Area2D) -> void:
	if area is ItemDrop and not nearby_drops.has(area):
		nearby_drops.append(area)
		_update_nearest_drop()


func _on_area_exited(area: Area2D) -> void:
	if area is ItemDrop:
		nearby_drops.erase(area)
		_update_nearest_drop()


func _update_nearest_drop() -> void:
	var previous_drop := closest_drop
	var nearest: ItemDrop
	var nearest_distance := pickup_range

	var candidates: Array[ItemDrop] = []
	for node in get_tree().get_nodes_in_group(&"item_drops"):
		if node is ItemDrop:
			candidates.append(node)

	for drop in candidates:
		if not is_instance_valid(drop):
			continue

		if drop.item_data == null or drop.quantity <= 0:
			continue

		var distance := global_position.distance_to(drop.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = drop

	closest_drop = nearest
	if previous_drop != closest_drop:
		pickup_target_changed.emit(closest_drop)

	if is_instance_valid(closest_drop):
		prompt.text = "[E] Recoger: %s x%d" % [
			closest_drop.item_data.display_name,
			closest_drop.quantity,
		]
		prompt.visible = true
	else:
		prompt.visible = false


func _update_sensor_range() -> void:
	var circle := sensor_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = pickup_range


func _is_owner_dead() -> bool:
	return health != null and health.is_dead
