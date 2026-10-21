extends SceneTree

const HealthComponentScript = preload("res://components/health/health_component.gd")
const RegenerationComponentScript = preload("res://components/regeneration/regeneration_component.gd")

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var health := HealthComponentScript.new()
	health.max_health = 30.0
	var regeneration := RegenerationComponentScript.new()
	regeneration.health = health
	regeneration.pixeles_por_paso = 20.0
	regeneration.pasos_para_regenerar = 3
	regeneration.vida_por_regeneracion = 2.0
	root.add_child(health)
	root.add_child(regeneration)
	await process_frame

	health.take_damage(10.0)
	_check(health.current_health == 20.0, "preparar vida por debajo del máximo")

	regeneration.procesar_movimiento(20.0)
	regeneration.procesar_movimiento(20.0)
	_check(health.current_health == 20.0, "no regenerar antes de tres pasos")
	regeneration.procesar_movimiento(20.0)
	_check(health.current_health == 22.0, "regenerar 2 HP tras 3 pasos de 20 píxeles")

	regeneration.procesar_movimiento(10.0)
	regeneration.procesar_movimiento(10.0)
	regeneration.procesar_movimiento(40.0)
	_check(health.current_health == 24.0, "acumular distancias parciales correctamente")

	health.current_health = 29.0
	regeneration.distancia_acumulada = 0.0
	regeneration.procesar_movimiento(60.0)
	_check(health.current_health == 30.0, "no superar la vida máxima")

	health.take_damage(30.0)
	_check(health.is_dead, "marcar la entidad como muerta")
	regeneration.procesar_movimiento(1000.0)
	_check(health.current_health == 0.0, "no regenerar una entidad muerta")

	var living_health := HealthComponentScript.new()
	living_health.max_health = 30.0
	var living_regeneration := RegenerationComponentScript.new()
	living_regeneration.health = living_health
	root.add_child(living_health)
	root.add_child(living_regeneration)
	await process_frame
	living_health.take_damage(10.0)
	living_regeneration.procesar_movimiento(0.0)
	living_regeneration.procesar_movimiento(-20.0)
	_check(living_health.current_health == 20.0, "ignorar desplazamientos nulos y negativos")

	var null_health_regeneration := RegenerationComponentScript.new()
	root.add_child(null_health_regeneration)
	await process_frame
	null_health_regeneration.procesar_movimiento(60.0)
	_check(true, "manejar componente sin referencia de vida")

	print("Regeneration tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
