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
	main_instance.player.configure_debug(null)

	var player: CharacterBody2D = main_instance.player
	var waves: WaveManager = main_instance.wave_manager
	var camera: Camera2D = player.get_node("Camera2D")
	_check(WORLD_BOUNDS.RECT.size == Vector2(4000.0, 4000.0), "usar mapa de 4000x4000")
	_check(camera.limit_left == 0 and camera.limit_top == 0 and camera.limit_right == 4000 and camera.limit_bottom == 4000, "configurar límites de cámara")
	_check(WORLD_BOUNDS.contains_position(player.global_position), "iniciar jugador dentro del mapa")
	_check(waves.minimum_spawn_distance == 250.0, "configurar distancia mínima de aparición")
	_check(waves.maximum_spawn_distance == 650.0, "configurar distancia máxima de aparición")

	player.global_position = Vector2(48.0, 48.0)
	for _index in range(8):
		var position := waves._find_spawn_position()
		_check(WORLD_BOUNDS.contains_position(position), "generar enemigo dentro del mapa")
		_check(position.distance_to(player.global_position) >= waves.minimum_spawn_distance, "respetar distancia mínima en borde")
		_check(position.distance_to(player.global_position) <= waves.maximum_spawn_distance, "respetar distancia máxima en borde")

	var before := player.global_position
	player.global_position = Vector2(-100.0, 4100.0)
	player.global_position = WORLD_BOUNDS.clamp_position(player.global_position)
	_check(WORLD_BOUNDS.contains_position(player.global_position), "clamp de posición en límites")
	_check(before != player.global_position, "aplicar corrección de posición fuera del mapa")

	print("World layout tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
