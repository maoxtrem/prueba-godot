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

	var health: HealthComponent = main_instance.player.health
	var hud: GameHUD = main_instance.hud
	_check(hud.health_label.text == "100 / 100 HP", "mostrar HP completo del jugador")
	health.take_damage(25.0)
	_check(hud.health_label.text == "75 / 100 HP", "actualizar HP reducido del jugador")
	health.increase_max_health(50.0, 50.0)
	_check(hud.health_label.text == "125 / 150 HP", "mostrar HP máximo ampliado")

	var enemy: Enemy = main_instance.get_node("EnemyContainer").get_child(0)
	_check(enemy.etiqueta_vida.text == "30 / 30 HP", "mostrar HP completo del enemigo")
	enemy.health.take_damage(5.0)
	_check(enemy.etiqueta_vida.text == "25 / 30 HP", "actualizar daño del enemigo")
	enemy.health.heal(2.0)
	_check(enemy.etiqueta_vida.text == "27 / 30 HP", "actualizar regeneración del enemigo")
	enemy.health.take_damage(1000.0)
	_check(enemy.etiqueta_vida.text == "0 / 30 HP", "mostrar HP cero al morir")

	print("Health display tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
