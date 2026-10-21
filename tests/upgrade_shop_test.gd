extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	main_instance.player.configure_debug(null)

	var manager: GameManager = main_instance.get_node("GameManager")
	var waves: WaveManager = main_instance.get_node("WaveManager")
	var shop: UpgradeShop = main_instance.get_node("HUD/UpgradeShop")
	var health: HealthComponent = main_instance.get_node("Player/HealthComponent")
	var upgrades: UpgradeManager = main_instance.get_node("Player/UpgradeManager")
	var inventory_ui: InventoryUI = main_instance.get_node("HUD/InventoryUI")

	_check(manager.current_state == GameManager.GameState.PLAYING, "iniciar en PLAYING")
	_check(not shop.visible, "iniciar con tienda cerrada")

	Input.parse_input_event(_key_event(KEY_B))
	await process_frame
	_check(manager.current_state == GameManager.GameState.UPGRADE_SELECTION, "abrir tienda con B")
	_check(paused and shop.visible, "pausar y mostrar tienda")
	_check(shop.cards.size() == 4, "mostrar cuatro mejoras")
	inventory_ui.open_inventory()
	_check(not inventory_ui.visible, "impedir inventario simultáneo")

	var health_before := health.current_health
	shop._on_buy_pressed(0)
	_check(health.current_health < health_before, "actualizar vida después de comprar")
	_check(upgrades.get_upgrade_level("light_legs") == 1, "aplicar compra desde tienda")
	_check(shop.visible, "mantener tienda abierta tras comprar")
	shop._on_buy_pressed(1)
	_check(upgrades.get_upgrade_level("efficient_step") == 1, "permitir varias compras")

	Input.parse_input_event(_key_event(KEY_B))
	await process_frame
	_check(manager.current_state == GameManager.GameState.PLAYING, "cerrar tienda con B")
	_check(not paused and not shop.visible, "reanudar al cerrar con B")

	var enemies: Array[Node] = main_instance.get_node("EnemyContainer").get_children()
	for enemy in enemies:
		enemy.health.take_damage(1000.0)
	await process_frame
	var rest_ui: BetweenWavesUI = main_instance.get_node("HUD/BetweenWavesUI")
	_check(manager.current_state == GameManager.GameState.BETWEEN_WAVES, "entrar en descanso entre oleadas")
	_check(rest_ui.visible and waves.next_wave_pending, "mostrar punto seguro y conservar oleada pendiente")
	var wave_before := waves.current_wave
	main_instance.continue_between_waves()
	await process_frame
	_check(manager.current_state == GameManager.GameState.PLAYING, "volver a PLAYING al continuar")
	_check(waves.current_wave == wave_before + 1, "reanudar una única oleada pendiente")
	_check(not rest_ui.visible and not shop.visible, "ocultar el punto seguro sin abrir la tienda")
	waves.start_next_wave()
	_check(waves.current_wave == wave_before + 1, "evitar oleadas duplicadas")

	health.take_damage(1000.0)
	_check(manager.current_state == GameManager.GameState.GAME_OVER, "GAME_OVER tiene prioridad")
	Input.parse_input_event(_key_event(KEY_B))
	await process_frame
	_check(not shop.visible, "bloquear tienda en GAME_OVER")

	var second_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(second_main)
	set_current_scene(second_main)
	await process_frame
	second_main.open_upgrade_shop()
	var second_shop: UpgradeShop = second_main.get_node("HUD/UpgradeShop")
	_check(second_shop.visible, "abrir tienda para probar botón Cerrar")
	second_shop.close_button.emit_signal("pressed")
	_check(not second_shop.visible and not paused, "cerrar mediante botón Cerrar")

	print("Upgrade shop tests: ", checks, " comprobaciones correctas")
	quit()

func _key_event(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	return event

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
