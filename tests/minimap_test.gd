extends SceneTree

const WORLD_BOUNDS = preload("res://systems/world/world_bounds.gd")
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	await process_frame

	var minimap = main_instance.hud.minimap
	var player: CharacterBody2D = main_instance.player
	var enemies: Array[Node] = main_instance.get_node("EnemyContainer").get_children()
	_check(minimap.visible, "minimapa visible durante la partida")
	_check(minimap.size == Vector2(180.0, 180.0), "tamaño provisional del minimapa")
	_check(minimap.position.x >= 0.0 and minimap.position.y >= 0.0, "minimapa dentro del viewport")
	var viewport_size := root.get_viewport().get_visible_rect().size
	_check(minimap.position.x + minimap.size.x <= viewport_size.x, "minimapa no exceder el borde derecho")
	_check(minimap.position.y + minimap.size.y <= viewport_size.y, "minimapa no exceder el borde inferior")
	_check(minimap.anchor_left == 1.0 and minimap.anchor_right == 1.0, "anclar minimapa a la esquina superior derecha")
	_check(minimap.mouse_filter == Control.MOUSE_FILTER_IGNORE, "no interceptar clics del juego")
	_check(minimap.process_mode == Node.PROCESS_MODE_ALWAYS, "procesar durante pausas")
	_send_key(KEY_M)
	await process_frame
	_check(not minimap.visible, "ocultar minimapa con M")
	_send_key(KEY_M)
	await process_frame
	_check(minimap.visible, "mostrar minimapa con M")
	_check(enemies.size() == 3, "recibir los tres enemigos de la oleada")
	_check(minimap.get_enemy_markers().size() == 3, "mostrar enemigos vivos")

	player.global_position = Vector2(2000.0, 2000.0)
	_check(minimap.world_to_map(player.global_position) == minimap.size * 0.5, "convertir el centro del mundo")
	_check(minimap.world_to_map(Vector2.ZERO) == Vector2.ZERO, "convertir el origen del mundo")
	_check(minimap.world_to_map(WORLD_BOUNDS.RECT.end) == minimap.size, "convertir el límite del mundo")

	var moved_enemy: Enemy = enemies[0]
	moved_enemy.global_position = Vector2(3500.0, 500.0)
	var marker: Vector2 = minimap.world_to_map(moved_enemy.global_position)
	_check(marker.x > minimap.size.x * 0.8 and marker.y < minimap.size.y * 0.2, "actualizar marcador al mover enemigo")

	moved_enemy.health.is_dead = true
	_check(minimap.get_enemy_markers().size() == 2, "eliminar marcador de enemigo muerto")
	moved_enemy.queue_free()
	await process_frame
	_check(minimap.get_enemy_markers().size() == 2, "no conservar referencias inválidas")

	var offset_rect := Rect2(Vector2(100.0, 200.0), Vector2(1000.0, 500.0))
	minimap.set_sources(player, main_instance.get_node("EnemyContainer"), offset_rect)
	_check(minimap.world_to_map(offset_rect.position) == Vector2.ZERO, "respetar límites con origen distinto de cero")
	_check(minimap.world_to_map(offset_rect.end) == minimap.size, "respetar límite desplazado")

	print("Minimap tests: ", checks, " comprobaciones correctas")
	quit()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)


func _send_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
