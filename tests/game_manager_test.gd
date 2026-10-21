extends SceneTree

var checks := 0
var state_changes := 0
var restart_signals := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame

	var manager: GameManager = main_instance.get_node("GameManager")
	var waves: WaveManager = main_instance.get_node("WaveManager")
	var player_health: HealthComponent = main_instance.get_node("Player/HealthComponent")
	var game_over_ui: GameOverUI = main_instance.get_node("HUD/GameOverUI")
	var inventory_ui: InventoryUI = main_instance.get_node("HUD/InventoryUI")
	manager.state_changed.connect(_on_state_changed)
	manager.restart_requested.connect(_on_restart_requested)

	_check(manager.current_state == GameManager.GameState.PLAYING, "iniciar en PLAYING")
	_check(waves.current_wave >= 1, "iniciar la primera oleada")
	_check(not paused, "partida activa sin pausa")

	var wave_before_game_over := waves.current_wave
	var kills_before_game_over := waves.total_kills
	player_health.take_damage(100.0)
	_check(manager.current_state == GameManager.GameState.GAME_OVER, "transicionar a GAME_OVER")
	_check(state_changes == 1, "emitir una única transición de muerte")
	_check(paused, "pausar la simulación en GAME_OVER")
	_check(not waves.waves_enabled, "desactivar nuevas oleadas")
	_check(game_over_ui.visible, "mostrar pantalla de derrota")
	_check(game_over_ui.wave_label.text == "Oleada alcanzada: %d" % wave_before_game_over, "mostrar oleada final")
	_check(game_over_ui.kills_label.text == "Enemigos eliminados: %d" % kills_before_game_over, "mostrar eliminaciones finales")

	var wave_after_game_over := waves.current_wave
	waves.start_next_wave()
	_check(waves.current_wave == wave_after_game_over, "bloquear inicio de oleada posterior")
	_check(not manager.enter_game_over(), "no repetir GAME_OVER")
	_check(state_changes == 1, "no repetir señal de estado")

	var post_game_over_enemy: Enemy = main_instance.get_node("EnemyContainer").get_child(0)
	var drops_before_post_death: int = main_instance.get_node("ItemDropContainer").get_child_count()
	var kills_before_post_death: int = waves.total_kills
	post_game_over_enemy.health.take_damage(100.0)
	_check(waves.total_kills == kills_before_post_death, "no contabilizar muertes posteriores")
	_check(main_instance.get_node("ItemDropContainer").get_child_count() == drops_before_post_death, "no generar drops posteriores")

	var inventory_visible_before := inventory_ui.visible
	inventory_ui.open_inventory()
	_check(inventory_ui.visible == inventory_visible_before, "bloquear inventario en GAME_OVER")

	var restart_result := manager.request_restart()
	_check(restart_result, "aceptar solicitud de reinicio")
	_check(not paused, "quitar pausa antes de recargar")
	_check(restart_signals == 1, "emitir señal de reinicio")

	print("Game manager tests: ", checks, " comprobaciones correctas")
	quit()


func _on_state_changed(_previous: GameManager.GameState, _new_state: GameManager.GameState) -> void:
	state_changes += 1


func _on_restart_requested() -> void:
	restart_signals += 1


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
