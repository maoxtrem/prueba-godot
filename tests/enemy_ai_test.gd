extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	var debug: DebugSettings = main_instance.debug_settings.duplicate()
	debug.debug_enabled = true
	debug.player_invulnerable = true
	main_instance.player.configure_debug(debug)
	var player: CharacterBody2D = main_instance.player
	var manager: GameManager = main_instance.game_manager
	var enemies: Array[Node] = main_instance.get_node("EnemyContainer").get_children()
	var source: Enemy = enemies[0]
	var companion_a: Enemy = enemies[1]
	var companion_b: Enemy = enemies[2]
	player.global_position = Vector2(200.0, 200.0)
	source.global_position = Vector2(300.0, 200.0)
	companion_a.global_position = Vector2(500.0, 200.0)
	companion_b.global_position = Vector2(300.0, 400.0)
	for enemy in enemies:
		enemy.set_spawn_position(enemy.global_position)
		enemy.ai_state = Enemy.AIState.IDLE
		enemy.alert_sent = false
	await physics_frame
	await physics_frame
	_check(source.ai_state == Enemy.AIState.CHASE, "detectar jugador cercano")
	_check(source.activation_reason == "direct_detection", "registrar detección directa")
	_check(_count_state(enemies, Enemy.AIState.CHASE) == 3, "alertar como máximo a dos compañeros")
	_check(not companion_a.alert_sent and not companion_b.alert_sent, "evitar propagación automática de alertas")

	var known_position := source.last_known_player_position
	player.global_position = Vector2(1000.0, 1000.0)
	await physics_frame
	_check(source.ai_state == Enemy.AIState.SEARCH, "pasar a SEARCH al perder objetivo")
	_check(source.last_known_player_position == known_position, "conservar última posición conocida")

	manager.pause_game()
	var elapsed := source.search_elapsed
	for _frame in range(30):
		await physics_frame
	_check(source.search_elapsed == elapsed, "pausar temporizador de búsqueda")
	manager.resume_game()
	source.search_duration = 0.1
	for _frame in range(30):
		await physics_frame
	_check(source.ai_state == Enemy.AIState.RETURN or source.ai_state == Enemy.AIState.IDLE, "finalizar SEARCH y entrar en RETURN")

	for _frame in range(120):
		await physics_frame
	_check(source.ai_state == Enemy.AIState.IDLE or source.ai_state == Enemy.AIState.CHASE, "regresar a IDLE en el origen")

	source.ai_state = Enemy.AIState.IDLE
	source.alert_sent = false
	source.recibir_dano(1.0)
	_check(source.ai_state == Enemy.AIState.CHASE, "activar CHASE al recibir daño")
	manager.enter_game_over()
	var state_before := source.ai_state
	for _frame in range(20):
		await physics_frame
	_check(source.ai_state == state_before, "bloquear IA durante GAME_OVER")

	print("Enemy AI tests: ", checks, " comprobaciones correctas")
	quit()

func _count_state(enemies: Array[Node], state: int) -> int:
	var count := 0
	for enemy in enemies:
		if enemy.ai_state == state:
			count += 1
	return count

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
