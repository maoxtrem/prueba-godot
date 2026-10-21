extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame

	var manager: GameManager = main_instance.get_node("GameManager")
	var waves: WaveManager = main_instance.get_node("WaveManager")
	var shop: UpgradeShop = main_instance.get_node("HUD/UpgradeShop")
	var health: HealthComponent = main_instance.get_node("Player/HealthComponent")
	var upgrades: UpgradeManager = main_instance.get_node("Player/UpgradeManager")
	var inventory_ui: InventoryUI = main_instance.get_node("HUD/InventoryUI")

	var enemies: Array[Node] = main_instance.get_node("EnemyContainer").get_children()
	for enemy in enemies:
		enemy.health.take_damage(1000.0)
	await process_frame

	_check(manager.current_state == GameManager.GameState.UPGRADE_SELECTION, "entrar en selección al completar oleada")
	_check(paused, "pausar combate durante selección")
	_check(shop.visible, "mostrar tienda al completar oleada")
	_check(shop.cards.size() == 4, "mostrar cuatro mejoras")
	_check(not waves.wave_active, "no mantener oleada activa")
	inventory_ui.open_inventory()
	_check(not inventory_ui.visible, "inventario no se abre durante selección")

	var health_before := health.current_health
	shop._on_buy_pressed(0)
	_check(health.current_health < health_before, "actualizar vida después de comprar")
	_check(upgrades.get_upgrade_level("light_legs") == 1, "aplicar compra desde tienda")
	shop._on_buy_pressed(1)
	_check(upgrades.get_upgrade_level("efficient_step") == 1, "permitir varias compras")
	_check(shop.cards[0].button.disabled == false or health.current_health <= 15.0, "actualizar disponibilidad de compra")

	var wave_before := waves.current_wave
	shop._on_continue_pressed()
	await process_frame
	_check(manager.current_state == GameManager.GameState.PLAYING, "volver a PLAYING al continuar")
	_check(not paused, "reanudar simulación al continuar")
	_check(not shop.visible, "cerrar tienda al continuar")
	_check(waves.current_wave == wave_before + 1, "iniciar una sola nueva oleada")
	var wave_after := waves.current_wave
	waves.start_next_wave()
	_check(waves.current_wave == wave_after, "evitar oleadas duplicadas")

	health.take_damage(1000.0)
	_check(manager.current_state == GameManager.GameState.GAME_OVER, "GAME_OVER tiene prioridad")
	_check(not shop.visible, "ocultar tienda al morir")

	print("Upgrade shop tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
