extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_instance: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame

	_send_key(KEY_B, true)
	await process_frame
	_check(main_instance.hud.upgrade_shop.visible, "B abre la tienda")
	_check(main_instance.game_manager.current_state == GameManager.GameState.UPGRADE_SELECTION, "la tienda pausa en UPGRADE_SELECTION")
	_send_key(KEY_B, true)
	await process_frame
	_check(not main_instance.hud.upgrade_shop.visible, "B cierra la tienda")
	_check(main_instance.game_manager.current_state == GameManager.GameState.PLAYING, "cerrar tienda reanuda PLAYING")

	_send_key(KEY_J, true)
	await process_frame
	_check(main_instance.hud.quest_ui.visible, "J abre misiones")
	_check(not main_instance.hud.upgrade_shop.visible, "no abrir dos modales con J")
	_send_key(KEY_J, true)
	await process_frame
	_check(not main_instance.hud.quest_ui.visible, "J cierra misiones")

	_send_key(KEY_I, true)
	await process_frame
	_check(main_instance.hud.inventory_ui.visible, "I abre inventario")
	_check(main_instance.game_manager.current_state == GameManager.GameState.PAUSED, "inventario pausa en PAUSED")
	_send_key(KEY_I, true)
	await process_frame
	_check(not main_instance.hud.inventory_ui.visible, "I cierra inventario")
	_check(main_instance.game_manager.current_state == GameManager.GameState.PLAYING, "cerrar inventario reanuda PLAYING")

	# Un modal activo bloquea los otros accesos.
	_send_key(KEY_B, true)
	await process_frame
	_send_key(KEY_J, true)
	await process_frame
	_check(main_instance.hud.upgrade_shop.visible and not main_instance.hud.quest_ui.visible, "bloquear J mientras la tienda está abierta")
	_send_key(KEY_B, true)
	await process_frame

	# Completar la oleada y verificar las restricciones del punto seguro.
	for enemy in main_instance.get_node("EnemyContainer").get_children():
		enemy.health.take_damage(1000.0)
	await process_frame
	_check(main_instance.game_manager.current_state == GameManager.GameState.BETWEEN_WAVES, "entrar en BETWEEN_WAVES")
	_check(main_instance.hud.between_waves_ui.visible, "mostrar punto seguro")
	_send_key(KEY_B, true)
	_send_key(KEY_J, true)
	_send_key(KEY_I, true)
	await process_frame
	_check(main_instance.hud.between_waves_ui.visible, "bloquear I/B/J en BETWEEN_WAVES")
	_check(main_instance.game_manager.current_state == GameManager.GameState.BETWEEN_WAVES, "mantener estado BETWEEN_WAVES")

	main_instance.hud.between_waves_ui.next_button.emit_signal("pressed")
	await process_frame
	_check(main_instance.game_manager.current_state == GameManager.GameState.PLAYING, "continuar vuelve a PLAYING")
	_send_key(KEY_B, true)
	await process_frame
	_check(main_instance.hud.upgrade_shop.visible, "B vuelve a funcionar después del punto seguro")
	_send_key(KEY_B, true)
	await process_frame
	_send_key(KEY_J, true)
	await process_frame
	_check(main_instance.hud.quest_ui.visible, "J vuelve a funcionar después del punto seguro")
	_send_key(KEY_J, true)
	await process_frame

	# GAME_OVER bloquea los tres modales.
	main_instance.debug_settings = main_instance.debug_settings.duplicate()
	main_instance.debug_settings.debug_enabled = false
	main_instance.player.configure_debug(main_instance.debug_settings)
	main_instance.player.health.take_damage(1000.0)
	await process_frame
	_send_key(KEY_B, true)
	_send_key(KEY_J, true)
	_send_key(KEY_I, true)
	await process_frame
	_check(main_instance.game_manager.current_state == GameManager.GameState.GAME_OVER, "mantener GAME_OVER")
	_check(not main_instance.hud.upgrade_shop.visible and not main_instance.hud.quest_ui.visible and not main_instance.hud.inventory_ui.visible, "bloquear modales en GAME_OVER")

	print("Modal controls tests: ", checks, " comprobaciones correctas")
	quit()

func _send_key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
