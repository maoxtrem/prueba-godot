extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_instance: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame

	var repository := JsonSaveRepository.new()
	repository.save_directory = "/tmp/ultimo_refugio_between_waves_space"
	main_instance.save_manager.repository = repository
	main_instance.save_manager.default_slot = "space_test"

	var enemies: Array[Node] = []
	for enemy in main_instance.get_node("EnemyContainer").get_children():
		enemies.append(enemy)
	_check(enemies.size() == 3, "iniciar la oleada con tres enemigos")

	# Dejar el último enemigo para el ataque real con ESPACIO.
	enemies[0].health.take_damage(1000.0)
	enemies[1].health.take_damage(1000.0)
	await process_frame
	var last_enemy: Node = enemies[2]
	last_enemy.global_position = main_instance.player.global_position + Vector2(30.0, 0.0)
	last_enemy.health.current_health = 10.0
	main_instance.player.componente_ataque.tiempo_restante = 0.0
	main_instance.player.componente_ataque.dano = 10.0

	Input.parse_input_event(_key_event(true, false))
	await process_frame
	_check(main_instance.game_manager.current_state == GameManager.GameState.BETWEEN_WAVES, "entrar en BETWEEN_WAVES tras atacar con ESPACIO")
	_check(main_instance.hud.between_waves_ui.visible, "mostrar BETWEEN_WAVES tras atacar con ESPACIO")
	_check(main_instance.get_node("EnemyContainer").get_child_count() == 0, "el ataque elimina al último enemigo")
	_check(main_instance.wave_manager.current_wave == 1, "no iniciar automáticamente la siguiente oleada")

	# Mantener ESPACIO y repetirlo no debe confirmar Siguiente oleada.
	Input.parse_input_event(_key_event(true, true))
	await process_frame
	_check(main_instance.game_manager.current_state == GameManager.GameState.BETWEEN_WAVES, "ignorar repetición de ESPACIO")
	_check(main_instance.hud.between_waves_ui.visible, "mantener visible la interfaz mientras ESPACIO sigue pulsado")
	Input.parse_input_event(_key_event(false, false))
	await process_frame
	_check(main_instance.game_manager.current_state == GameManager.GameState.BETWEEN_WAVES, "mantener BETWEEN_WAVES al liberar ESPACIO")
	_check(main_instance.hud.between_waves_ui.visible, "mantener la interfaz al liberar ESPACIO")

	var saved: Dictionary = main_instance.save_current_game()
	_check(saved.success, "guardar mientras la interfaz está abierta")
	_check(main_instance.hud.between_waves_ui.visible, "guardar no cierra BETWEEN_WAVES")

	var next_button: Button = main_instance.hud.between_waves_ui.next_button
	# En headless no existe una ventana OS para hit-test de ratón; emitir la
	# señal pressed comprueba la conexión real del Button sin llamar al método
	# de continuación directamente.
	next_button.emit_signal("pressed")
	await process_frame
	_check(main_instance.game_manager.current_state == GameManager.GameState.PLAYING, "continuar requiere una acción explícita")
	_check(main_instance.wave_manager.current_wave == 2, "iniciar exactamente la siguiente oleada")
	_check(main_instance.get_node("EnemyContainer").get_child_count() == 5, "generar cinco enemigos en la segunda oleada")
	next_button.emit_signal("pressed")
	await process_frame
	_check(main_instance.wave_manager.current_wave == 2, "ignorar un segundo clic de continuación")
	_check(main_instance.get_node("EnemyContainer").get_child_count() == 5, "no duplicar enemigos por doble clic")

	print("Between waves space tests: ", checks, " comprobaciones correctas")
	quit()

func _key_event(pressed: bool, echo: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = pressed
	event.echo = echo
	return event

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
