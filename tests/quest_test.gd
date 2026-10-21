extends SceneTree

var checks := 0
const QUESTS := [
	preload("res://resources/quests/first_kills.tres"),
	preload("res://resources/quests/hunter.tres"),
	preload("res://resources/quests/survivor.tres"),
	preload("res://resources/quests/collector.tres"),
]
const MATERIAL := preload("res://resources/items/test_material.tres")
const SWORD := preload("res://resources/items/test_weapon.tres")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var inventory := InventoryComponent.new()
	var health := HealthComponent.new()
	root.add_child(inventory)
	root.add_child(health)
	await process_frame
	var manager := QuestManager.new()
	for quest in QUESTS: manager.available_quests.append(quest)
	root.add_child(manager)
	manager.setup(inventory, health)
	_check(manager.get_progress("first_kills") == 0, "activar misiones al iniciar")
	for total in range(1, 6): manager.register_enemy_kill(total)
	manager.register_enemy_kill(5)
	_check(manager.get_progress("first_kills") == 5 and manager.is_completed("first_kills"), "registrar bajas sin duplicar eventos")
	health.drain_health(50.0)
	_check(manager.claim_quest("first_kills").success and is_equal_approx(health.current_health, 80.0), "entregar recompensa de HP")
	_check(not manager.claim_quest("first_kills").success, "evitar recompensa duplicada")

	for total in range(6, 16): manager.register_enemy_kill(total)
	_check(manager.is_completed("hunter"), "completar misión de cazador")
	_check(manager.claim_quest("hunter").success and inventory.get_item_quantity("blood_fragment") == 10, "entregar recompensa de materiales")

	for wave in [1, 1, 2, 3]: manager.register_wave_completed(wave)
	_check(manager.get_progress("survivor") == 3, "contar oleadas sin duplicar")
	_check(manager.claim_quest("survivor").success, "reclamar recompensa de superviviente")

	inventory.capacity = 1
	inventory.remove_item("blood_fragment", 10)
	inventory.add_item(SWORD, 1)
	manager.register_items_collected(10)
	_check(manager.is_completed("collector"), "completar misión de recolección")
	var pending := manager.claim_quest("collector")
	_check(not pending.success and pending.pending and manager.has_pending_reward("collector"), "conservar recompensa pendiente con inventario lleno")
	inventory.remove_item("rusty_sword", 1)
	_check(manager.claim_quest("collector").success and inventory.get_item_quantity("blood_fragment") == 15, "reclamar recompensa pendiente después")

	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	var quest_ui: QuestUI = main_instance.get_node("HUD/QuestUI")
	var open_event := InputEventKey.new()
	open_event.keycode = KEY_J
	open_event.pressed = true
	Input.parse_input_event(open_event)
	await process_frame
	_check(quest_ui.visible and paused, "abrir misiones con J y pausar")
	Input.parse_input_event(open_event)
	await process_frame
	_check(not quest_ui.visible and not paused, "cerrar misiones con J y reanudar")
	# El recurso de Debug de la escena está configurado para pruebas de movimiento;
	# desactivarlo aquí permite comprobar de forma determinista GAME_OVER.
	main_instance.debug_settings.debug_enabled = false
	main_instance.player.configure_debug(main_instance.debug_settings)
	main_instance.get_node("Player/HealthComponent").take_damage(100.0)
	Input.parse_input_event(open_event)
	await process_frame
	_check(not quest_ui.visible, "bloquear misiones durante GAME_OVER")

	print("Quest tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
