extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Reproducir el flujo de F5: menú principal -> Nueva partida.
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	set_current_scene(menu)
	await process_frame
	var main_instance = menu.get_node("Main")
	menu._on_new_game_pressed()
	await process_frame

	var waves: WaveManager = main_instance.wave_manager
	var manager: GameManager = main_instance.game_manager
	var rest_ui: BetweenWavesUI = main_instance.hud.between_waves_ui
	var repository := JsonSaveRepository.new()
	repository.save_directory = "/tmp/ultimo_refugio_between_waves"
	main_instance.save_manager.repository = repository
	main_instance.save_manager.default_slot = "between_test"

	var completed_wave := waves.current_wave
	for enemy in main_instance.get_node("EnemyContainer").get_children():
		enemy.health.take_damage(1000.0)
	await process_frame

	_check(manager.current_state == GameManager.GameState.BETWEEN_WAVES, "entrar en BETWEEN_WAVES")
	_check(rest_ui.visible, "mostrar interfaz de descanso")
	_check(not rest_ui.save_button.disabled, "disponer de Guardar partida")
	_check(rest_ui.next_button.visible and not rest_ui.next_button.disabled, "disponer de Siguiente oleada")
	_check(waves.current_wave == completed_wave and not waves.wave_active, "no iniciar la siguiente automáticamente")
	_check(main_instance.get_node("EnemyContainer").get_child_count() == 0, "no conservar enemigos activos en el descanso")

	var saved: Dictionary = main_instance.save_current_game()
	_check(saved.success, "guardar en el punto seguro")
	_check(manager.current_state == GameManager.GameState.BETWEEN_WAVES, "guardar no cambia el estado")
	_check(rest_ui.message_label.text == "", "guardar desde la lógica no altera el estado visual")
	rest_ui.save_button.emit_signal("pressed")
	await process_frame
	_check(rest_ui.message_label.text == "Partida guardada.", "mostrar confirmación de guardado")

	var restored = load("res://scenes/main.tscn").instantiate()
	restored.start_in_menu = true
	root.add_child(restored)
	set_current_scene(restored)
	await process_frame
	restored.save_manager.repository = repository
	restored.save_manager.default_slot = "between_test"
	var continued: Dictionary = restored.continue_saved_game()
	_check(continued.success, "cargar partida desde el menú")
	_check(restored.game_manager.current_state == GameManager.GameState.BETWEEN_WAVES, "restaurar BETWEEN_WAVES")
	_check(restored.hud.between_waves_ui.visible, "mostrar descanso después de cargar")
	_check(restored.get_node("EnemyContainer").get_child_count() == 0, "cargar sin generar enemigos")

	var next_wave: int = restored.wave_manager.current_wave + 1
	_check(restored.continue_between_waves(), "autorizar siguiente oleada")
	await process_frame
	_check(restored.game_manager.current_state == GameManager.GameState.PLAYING, "volver a PLAYING")
	_check(restored.wave_manager.current_wave == next_wave, "generar la oleada correspondiente")
	_check(restored.get_node("EnemyContainer").get_child_count() == 5, "generar exactamente la siguiente oleada")
	restored.continue_between_waves()
	_check(restored.wave_manager.current_wave == next_wave, "impedir doble inicio")

	# Repetir la finalización con Debug desactivado para verificar que no depende
	# del modo de pruebas.
	var normal: Node = load("res://scenes/main.tscn").instantiate()
	normal.debug_settings = normal.debug_settings.duplicate()
	normal.debug_settings.debug_enabled = false
	root.add_child(normal)
	set_current_scene(normal)
	await process_frame
	var normal_waves: WaveManager = normal.wave_manager
	for enemy in normal.get_node("EnemyContainer").get_children():
		enemy.health.take_damage(1000.0)
	await process_frame
	_check(normal.game_manager.current_state == GameManager.GameState.BETWEEN_WAVES, "entrar en BETWEEN_WAVES con Debug desactivado")
	_check(normal.hud.between_waves_ui.visible, "mostrar descanso con Debug desactivado")
	_check(normal_waves.current_wave == 1 and normal.get_node("EnemyContainer").get_child_count() == 0, "no iniciar oleada extra con Debug desactivado")

	print("Between waves tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
