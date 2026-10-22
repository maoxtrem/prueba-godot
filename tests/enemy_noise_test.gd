extends SceneTree

var checks := 0
var noise_count := 0
var last_noise


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	await process_frame
	var noise_manager = main_instance.noise_manager
	noise_manager.noise_emitted.connect(_on_noise_emitted)
	var player: CharacterBody2D = main_instance.player
	var enemies: Array[Node] = main_instance.get_node("EnemyContainer").get_children()
	var near: Enemy = enemies[0]
	var far: Enemy = enemies[1]
	player.global_position = Vector2(2000.0, 2000.0)
	near.global_position = Vector2(2050.0, 2000.0)
	far.global_position = Vector2(3000.0, 3000.0)
	(enemies[2] as Enemy).global_position = Vector2(3500.0, 3500.0)
	for enemy in enemies:
		enemy.ai_state = Enemy.AIState.IDLE
		enemy.alert_sent = false

	var dagger_stats: WeaponStats = load("res://resources/weapons/vital_dagger_stats.tres")
	var sword_stats: WeaponStats = load("res://resources/weapons/rusty_sword_stats.tres")
	var spear_stats: WeaponStats = load("res://resources/weapons/crimson_spear_stats.tres")
	var crossbow_stats: WeaponStats = load("res://resources/weapons/crossbow_stats.tres")
	var pistol_stats: WeaponStats = load("res://resources/weapons/pistol_stats.tres")
	_check(dagger_stats.noise_radius == 30.0, "configurar ruido de daga")
	_check(sword_stats.noise_radius == 60.0, "configurar ruido de espada")
	_check(spear_stats.noise_radius == 80.0, "configurar ruido de lanza")
	_check(crossbow_stats.noise_radius == 100.0, "configurar ruido de ballesta")
	_check(pistol_stats.noise_radius == 250.0, "configurar ruido de pistola")
	var invalid_stats := WeaponStats.new()
	invalid_stats.noise_radius = -1.0
	_check(not invalid_stats.is_valid(), "rechazar radio negativo")

	var silent_event = noise_manager.emit_noise(player.global_position, 0.0, player, &"silent")
	_check(silent_event == null and noise_count == 0, "no crear ruido con radio cero")
	var direct_event = noise_manager.emit_noise(player.global_position, 100.0, player, &"test")
	_check(direct_event != null and noise_count == 1, "crear un evento de ruido válido")
	_check(near.ai_state == Enemy.AIState.INVESTIGATE, "escuchar ruido dentro del radio")
	_check(far.ai_state == Enemy.AIState.IDLE, "ignorar ruido fuera del radio")
	_check(near.investigation_position == player.global_position, "guardar posición exacta del ruido")
	player.global_position = Vector2(2200.0, 2200.0)
	_check(near.investigation_position == Vector2(2000.0, 2000.0), "no mover destino con el jugador")
	near.investigate_duration = 0.1
	for _frame in range(20):
		await physics_frame
	_check(near.ai_state == Enemy.AIState.RETURN or near.ai_state == Enemy.AIState.IDLE, "volver tras investigar")
	_check(not near.alert_sent, "no propagar alerta al escuchar ruido")

	# Integración real: un disparo aceptado emite ruido una sola vez.
	player.global_position = Vector2(2000.0, 2000.0)
	near.global_position = Vector2(2150.0, 2000.0)
	near.ai_state = Enemy.AIState.IDLE
	var pistol: ItemData = load("res://resources/items/weapon_pistol.tres")
	var ammo: ItemData = load("res://resources/items/pistol_ammo.tres")
	player.inventario.clear_items()
	player.inventario.add_item(ammo, 3)
	player.componente_ataque.aplicar_instancia_arma(WeaponInstance.new(pistol))
	player.componente_ataque.tiempo_restante = 0.0
	var before_shot := noise_count
	_check(player.componente_ataque.disparar(player, Vector2.RIGHT), "aceptar disparo con munición")
	_check(noise_count == before_shot + 1, "emitir un ruido por disparo aceptado")
	_check(last_noise.radius == 250.0 and near.ai_state == Enemy.AIState.INVESTIGATE, "investigar ruido de pistola")
	var rejected_count := noise_count
	_check(not player.componente_ataque.disparar(player, Vector2.RIGHT), "rechazar disparo durante cooldown")
	_check(noise_count == rejected_count, "no emitir ruido por disparo rechazado")

	# Ataque sin arma: se acepta según el contrato actual, pero es silencioso.
	player.componente_ataque.aplicar_estadisticas_arma(null)
	player.componente_ataque.tiempo_restante = 0.0
	var before_unarmed := noise_count
	_check(player.componente_ataque.atacar(player, &"grupo_inexistente"), "aceptar ataque básico sin objetivo")
	_check(noise_count == before_unarmed, "puños sin ruido")

	main_instance.game_manager.pause_game()
	var paused_count := noise_count
	_check(noise_manager.emit_noise(player.global_position, 250.0, player, &"paused") == null, "bloquear ruido durante pausa")
	_check(noise_count == paused_count, "no propagar ruido durante pausa")
	var paused_elapsed := near.investigate_elapsed
	for _frame in range(20):
		await physics_frame
	_check(near.investigate_elapsed == paused_elapsed, "pausar temporizador de investigación")
	main_instance.game_manager.resume_game()
	main_instance.game_manager.enter_game_over()
	_check(noise_manager.emit_noise(player.global_position, 250.0, player, &"game_over") == null, "bloquear ruido durante GAME_OVER")

	print("Enemy noise tests: ", checks, " comprobaciones correctas")
	quit()


func _on_noise_emitted(event) -> void:
	noise_count += 1
	last_noise = event


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
