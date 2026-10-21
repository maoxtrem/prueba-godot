extends Node
class_name LootComponent

@export var loot_table: LootTable
@export var drop_scene: PackedScene
@export_node_path("Node2D") var drop_parent_path: NodePath

var random_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var loot_processed: bool = false


func _ready() -> void:
	random_generator.randomize()

	var death_source := get_parent().get_node_or_null("HealthComponent")
	if death_source != null and death_source.has_signal("died"):
		death_source.died.connect(_on_owner_died)


func set_random_generator(generator: RandomNumberGenerator) -> void:
	if generator != null:
		random_generator = generator


func generate_loot_at(death_position: Vector2, drop_parent: Node) -> Array[Node2D]:
	if loot_processed:
		return []

	loot_processed = true
	var generated_drops: Array[Node2D] = []
	if is_inside_tree():
		var current_scene := get_tree().current_scene
		if current_scene != null and current_scene.has_method("is_game_over") and current_scene.is_game_over():
			return generated_drops
	if loot_table == null or drop_scene == null or not is_instance_valid(drop_parent):
		return generated_drops

	for result in loot_table.roll_loot(random_generator):
		var item := result.get("item") as ItemData
		var quantity := int(result.get("quantity", 0))
		if item == null or quantity <= 0:
			continue

		var drop := drop_scene.instantiate() as Node2D
		if drop == null or not drop.has_method("configurar"):
			if is_instance_valid(drop):
				drop.queue_free()
			continue

		drop_parent.add_child(drop)
		drop.global_position = death_position
		drop.configurar(item, quantity)
		generated_drops.append(drop)

	return generated_drops


func _on_owner_died() -> void:
	var drop_parent := _resolve_drop_parent()
	generate_loot_at(get_parent().global_position, drop_parent)


func _resolve_drop_parent() -> Node:
	if not drop_parent_path.is_empty():
		var configured_parent := get_node_or_null(drop_parent_path)
		if configured_parent != null:
			return configured_parent

	var current_scene := get_tree().current_scene
	if current_scene != null:
		var scene_drop_parent := current_scene.find_child("ItemDropContainer", true, false)
		if scene_drop_parent != null:
			return scene_drop_parent

	return get_tree().root.find_child("ItemDropContainer", true, false)
