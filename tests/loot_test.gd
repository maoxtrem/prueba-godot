extends SceneTree

const LootEntryScript = preload("res://systems/loot/loot_entry.gd")
const LootTableScript = preload("res://systems/loot/loot_table.gd")
const LootComponentScript = preload("res://systems/loot/loot_component.gd")

var checks := 0


func _init() -> void:
	var material = load("res://resources/items/test_material.tres")
	var sword = load("res://resources/items/test_weapon.tres")

	var zero_table = LootTableScript.new()
	var zero_entries: Array[LootEntry] = []
	zero_entries.append(_entry(material, 0.0, 1, 3))
	zero_table.entries = zero_entries
	var zero_rng := RandomNumberGenerator.new()
	zero_rng.seed = 100
	_check(zero_table.roll_loot(zero_rng).is_empty(), "probabilidad cero no genera drops")

	var guaranteed_table = LootTableScript.new()
	var guaranteed_entries: Array[LootEntry] = []
	guaranteed_entries.append(_entry(material, 1.0, 2, 4))
	guaranteed_entries.append(_entry(sword, 1.0, 1, 1))
	guaranteed_table.entries = guaranteed_entries
	var guaranteed_rng := RandomNumberGenerator.new()
	guaranteed_rng.seed = 200
	var guaranteed_loot := guaranteed_table.roll_loot(guaranteed_rng)
	_check(guaranteed_loot.size() == 2, "probabilidad cien genera cada entrada")
	_check(guaranteed_loot[0]["quantity"] >= 2 and guaranteed_loot[0]["quantity"] <= 4, "cantidad dentro de límites")
	_check(guaranteed_loot[1]["quantity"] == 1, "cantidad fija")

	var root_node := Node2D.new()
	root.add_child(root_node)
	var loot_component = LootComponentScript.new()
	loot_component.loot_table = guaranteed_table
	loot_component.drop_scene = load("res://scenes/items/item_drop.tscn")
	var component_rng := RandomNumberGenerator.new()
	component_rng.seed = 300
	loot_component.set_random_generator(component_rng)
	root_node.add_child(loot_component)

	var drops := loot_component.generate_loot_at(Vector2(42.0, 24.0), root_node)
	_check(drops.size() == 2, "generar varios objetos")
	_check(drops[0].global_position == Vector2(42.0, 24.0), "crear drops en la muerte")
	_check(loot_component.generate_loot_at(Vector2.ZERO, root_node).is_empty(), "evitar duplicación")

	print("Loot tests: ", checks, " comprobaciones correctas")
	quit()


func _entry(item, chance: float, minimum: int, maximum: int):
	var entry = LootEntryScript.new()
	entry.item = item
	entry.drop_chance = chance
	entry.min_quantity = minimum
	entry.max_quantity = maximum
	return entry


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
