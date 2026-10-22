extends Control
class_name Minimap

const WORLD_BOUNDS = preload("res://systems/world/world_bounds.gd")

@export var player_marker_color := Color(0.2, 0.65, 1.0, 1.0)
@export var enemy_marker_color := Color(0.9, 0.2, 0.2, 1.0)
@export var map_background_color := Color(0.025, 0.035, 0.05, 0.92)
@export var map_border_color := Color(0.35, 0.45, 0.55, 1.0)
@export var player_marker_radius := 4.0
@export var enemy_marker_radius := 3.0

var player: Node2D
var enemy_container: Node2D
var world_rect: Rect2 = WORLD_BOUNDS.RECT


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func set_sources(player_node: Node2D, enemies_node: Node2D, bounds: Rect2 = WORLD_BOUNDS.RECT) -> void:
	player = player_node
	enemy_container = enemies_node
	world_rect = bounds if bounds.size.x > 0.0 and bounds.size.y > 0.0 else WORLD_BOUNDS.RECT
	queue_redraw()


func world_to_map(world_position: Vector2) -> Vector2:
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return size * 0.5
	var normalized := Vector2(
		(world_position.x - world_rect.position.x) / world_rect.size.x,
		(world_position.y - world_rect.position.y) / world_rect.size.y
	)
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	return Vector2(normalized.x * size.x, normalized.y * size.y)


func get_enemy_markers() -> Array[Vector2]:
	var markers: Array[Vector2] = []
	if not is_instance_valid(enemy_container):
		return markers
	for node in enemy_container.get_children():
		if not is_instance_valid(node) or not node is Enemy:
			continue
		var enemy := node as Enemy
		if enemy.health.is_dead:
			continue
		markers.append(world_to_map(enemy.global_position))
	return markers


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), map_background_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), map_border_color, false, 2.0)

	for marker in get_enemy_markers():
		draw_circle(marker, enemy_marker_radius, enemy_marker_color)

	if is_instance_valid(player):
		draw_circle(world_to_map(player.global_position), player_marker_radius, player_marker_color)
