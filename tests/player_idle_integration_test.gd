extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame

	var player = main_instance.get_node("Player")
	var health: HealthComponent = player.get_node("HealthComponent")
	var manager: GameManager = main_instance.get_node("GameManager")
	var normal_debug: DebugSettings = main_instance.debug_settings.duplicate()
	normal_debug.debug_enabled = false
	normal_debug.player_invulnerable = false
	main_instance.player.configure_debug(normal_debug)
	var initial_position: Vector2 = player.global_position

	for _frame in range(720):
		await physics_frame

	var state_after_idle := manager.current_state
	var health_after_idle := health.current_health
	var enemies: Array[Node] = main_instance.get_node("EnemyContainer").get_children()
	print("Idle diagnóstico: estado=", state_after_idle, " vida=", health_after_idle, " posición=", player.global_position, " enemigos=", enemies.size())

	_check(state_after_idle == GameManager.GameState.PLAYING, "permanecer en PLAYING al estar quieto fuera de detección")
	_check(is_equal_approx(health_after_idle, health.max_health), "no recibir daño de enemigos en IDLE distante")
	_check(player.velocidad_efectiva > 0.0, "conservar velocidad efectiva después de estar quieto")

	var position_before_input: Vector2 = player.global_position
	Input.action_press("ui_right")
	for _frame in range(30):
		await physics_frame
	Input.action_release("ui_right")
	var moved_after_idle: bool = player.global_position.distance_to(position_before_input) > 0.1
	print("Movimiento diagnóstico: se_movió=", moved_after_idle, " estado=", manager.current_state, " velocidad=", player.velocity)
	_check(moved_after_idle or health.is_dead, "moverse o estar correctamente detenido por muerte")
	_check(initial_position != Vector2.ZERO, "iniciar en posición válida")
	paused = false

	var debug_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(debug_main)
	set_current_scene(debug_main)
	await process_frame
	var debug_settings: DebugSettings = debug_main.debug_settings.duplicate()
	debug_settings.debug_enabled = true
	debug_settings.player_invulnerable = true
	debug_main.debug_settings = debug_settings
	debug_main.player.configure_debug(debug_settings)
	var debug_player = debug_main.get_node("Player")
	var debug_health: HealthComponent = debug_player.get_node("HealthComponent")
	var debug_manager: GameManager = debug_main.get_node("GameManager")
	var debug_enemies: Array[Node] = debug_main.get_node("EnemyContainer").get_children()
	for index in range(debug_enemies.size()):
		var angle := TAU * float(index) / float(maxi(debug_enemies.size(), 1))
		debug_enemies[index].global_position = debug_player.global_position + Vector2.RIGHT.rotated(angle) * 80.0

	for _frame in range(180):
		await physics_frame
	_check(debug_manager.current_state == GameManager.GameState.PLAYING, "mantener PLAYING con Debug invulnerable")
	_check(debug_health.current_health == debug_health.max_health, "no perder vida con invulnerabilidad Debug")
	_check((debug_player.collision_mask & 2) == 0, "no colisionar físicamente con la capa de enemigos")
	var debug_position_before: Vector2 = debug_player.global_position
	Input.action_press("ui_right")
	for _frame in range(30):
		await physics_frame
	Input.action_release("ui_right")
	_check(debug_player.global_position.distance_to(debug_position_before) > 0.1, "escapar atravesando varios enemigos con Debug")

	print("Player idle integration tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
