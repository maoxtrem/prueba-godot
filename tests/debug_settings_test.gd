extends SceneTree

const PlayerScene = preload("res://scenes/player/player.tscn")
const EnemyScene = preload("res://scenes/enemies/enemy.tscn")
const DebugSettingsScript = preload("res://systems/debug/debug_settings.gd")

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player = PlayerScene.instantiate()
	var enemy = EnemyScene.instantiate()
	root.add_child(player)
	root.add_child(enemy)
	await process_frame

	var health: HealthComponent = player.get_node("HealthComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")
	var movement: MovementCostComponent = player.get_node("MovementCostComponent")
	var enemy_health: HealthComponent = enemy.get_node("HealthComponent")
	var enemy_attack: AttackComponent = enemy.get_node("AttackComponent")
	var settings: DebugSettings = DebugSettingsScript.new()
	settings.debug_enabled = false
	settings.enemy_damage_multiplier = 0.1
	player.configure_debug(settings)

	health.reset_health()
	player.recibir_dano_de_enemigo(10.0)
	_check(health.current_health == 90.0, "aplicar daño normal con Debug desactivado")

	health.reset_health()
	settings.debug_enabled = true
	settings.player_invulnerable = true
	player.recibir_dano_de_enemigo(10.0)
	_check(health.current_health == 100.0, "ignorar daño enemigo con invulnerabilidad")
	movement.procesar_movimiento(100.0)
	_check(is_equal_approx(health.current_health, 99.0), "mantener consumo de movimiento con invulnerabilidad")

	health.reset_health()
	settings.player_invulnerable = false
	player.recibir_dano_de_enemigo(10.0)
	_check(is_equal_approx(health.current_health, 99.0), "reducir daño enemigo al 10 por ciento")

	health.reset_health()
	settings.infinite_health = true
	player.recibir_dano_de_enemigo(10.0)
	movement.procesar_movimiento(100.0)
	_check(health.current_health == 100.0, "mantener vida con infinite_health")
	_check(health.spend_health(10.0), "permitir compras con infinite_health")
	_check(health.current_health == 100.0, "no descontar HP con infinite_health")

	settings.infinite_health = false
	enemy.global_position = Vector2(60.0, 0.0)
	player.global_position = Vector2.ZERO
	health.reset_health()
	enemy_health.reset_health()
	enemy_attack.tiempo_restante = 0.0
	var enemy_before := health.current_health
	enemy_attack.atacar(enemy, &"jugadores")
	_check(is_equal_approx(health.current_health, enemy_before - 1.0), "mantener ataque enemigo con multiplicador")

	var enemy_before_player_attack := enemy_health.current_health
	attack.tiempo_restante = 0.0
	player.atacar()
	_check(enemy_health.current_health < enemy_before_player_attack, "permitir ataques del jugador")

	_check(enemy_attack.dano_efectivo == enemy_attack.dano, "no modificar estadísticas del enemigo")

	settings.debug_enabled = false
	health.reset_health()
	player.recibir_dano_de_enemigo(100.0)
	_check(health.is_dead, "permitir GAME_OVER normal con Debug desactivado")

	print("Debug settings tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
