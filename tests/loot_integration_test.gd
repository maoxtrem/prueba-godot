extends SceneTree

var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	await process_frame

	var player = main_instance.get_node("Player")
	var player_health = player.get_node("HealthComponent")
	player_health.current_health = 50.0

	var enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	main_instance.get_node("EnemyContainer").add_child(enemy)
	await process_frame

	var guaranteed_table = load("res://resources/loot/basic_enemy_loot.tres")
	var guaranteed_entries: Array[LootEntry] = []
	var material = load("res://resources/items/test_material.tres")
	var sword = load("res://resources/items/test_weapon.tres")
	guaranteed_entries.append(_entry(material, 1.0, 2, 2))
	guaranteed_entries.append(_entry(sword, 1.0, 1, 1))
	guaranteed_table.entries = guaranteed_entries
	enemy.get_node("LootComponent").loot_table = guaranteed_table
	enemy.jugador = player
	enemy.global_position = Vector2(100.0, 100.0)
	enemy.get_node("HealthComponent").take_damage(100.0)

	_check(main_instance.get_node("ItemDropContainer").get_child_count() == 2, "integrar drops con la muerte real")
	_check(player_health.current_health == 70.0, "conservar recompensa de vida")
	print("Loot integration tests: ", checks, " comprobaciones correctas")
	quit()


func _entry(item, chance: float, minimum: int, maximum: int):
	var entry = load("res://systems/loot/loot_entry.gd").new()
	entry.item = item
	entry.drop_chance = chance
	entry.min_quantity = minimum
	entry.max_quantity = maximum
	return entry


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
