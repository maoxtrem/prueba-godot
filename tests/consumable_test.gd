extends SceneTree

var checks := 0
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BLOOD_POTION := preload("res://resources/items/blood_potion.tres")
const VITAL_ESSENCE := preload("res://resources/items/vital_essence.tres")
const FURY_ELIXIR := preload("res://resources/items/fury_elixir.tres")
const ENDURANCE_SERUM := preload("res://resources/items/endurance_serum.tres")
const BASIC_LOOT := preload("res://resources/loot/basic_enemy_loot.tres")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var health: HealthComponent = player.get_node("HealthComponent")
	var consumables: ConsumableComponent = player.get_node("ConsumableComponent")
	var status: StatusEffectComponent = player.get_node("StatusEffectComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")
	var movement: MovementCostComponent = player.get_node("MovementCostComponent")

	health.drain_health(40.0)
	inventory.add_item(BLOOD_POTION, 2)
	var heal_result := consumables.use_item("blood_potion")
	_check(heal_result.success, "usar poción válida")
	_check(is_equal_approx(health.current_health, 85.0), "curar 25 HP")
	_check(inventory.get_item_quantity("blood_potion") == 1, "retirar exactamente una poción")

	health.heal(100.0)
	var full_result := consumables.use_item("blood_potion")
	_check(not full_result.success and full_result.reason == "health_full", "rechazar vida al máximo")
	_check(inventory.get_item_quantity("blood_potion") == 1, "no retirar en fallo de vida completa")

	inventory.add_item(FURY_ELIXIR, 2)
	_check(consumables.use_item("fury_elixir").success, "usar elixir de furia")
	_check(is_equal_approx(attack.dano_efectivo, 13.0), "aplicar 30 por ciento de daño")
	var remaining_before := status.get_remaining("fury_elixir")
	_check(consumables.use_item("fury_elixir").success, "renovar elixir sin acumular")
	_check(is_equal_approx(attack.dano_efectivo, 13.0) and status.get_remaining("fury_elixir") >= remaining_before, "renovar sin apilar efecto")
	status._process(15.1)
	_check(not status.has_effect("fury_elixir") and is_equal_approx(attack.dano_efectivo, 10.0), "expirar furia y restaurar daño")

	inventory.add_item(ENDURANCE_SERUM, 1)
	_check(consumables.use_item("endurance_serum").success, "usar suero de resistencia")
	_check(is_equal_approx(movement.multiplicador_movimiento_efectivo, 0.7), "aplicar reducción de costo")
	status._process(20.1)
	_check(is_equal_approx(movement.multiplicador_movimiento_efectivo, 1.0), "expirar resistencia")

	health.take_damage(1000.0)
	inventory.add_item(VITAL_ESSENCE, 1)
	var dead_result := consumables.use_item("vital_essence")
	_check(not dead_result.success and dead_result.reason == "player_dead", "rechazar uso estando muerto")
	_check(inventory.get_item_quantity("vital_essence") == 1, "conservar consumible tras rechazo")
	_check(BASIC_LOOT.entries.size() == 9, "tabla básica conserva materiales, armas y consumibles")
	_check(is_equal_approx(BASIC_LOOT.entries[2].drop_chance, 0.15), "drop de poción al 15 por ciento")
	_check(is_equal_approx(BASIC_LOOT.entries[3].drop_chance, 0.05), "drop de esencia al 5 por ciento")
	_check(is_equal_approx(BASIC_LOOT.entries[4].drop_chance, 0.03) and is_equal_approx(BASIC_LOOT.entries[5].drop_chance, 0.03), "drops temporales al 3 por ciento")

	print("Consumable tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
