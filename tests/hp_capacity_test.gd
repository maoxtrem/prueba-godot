extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAPACITY_POTION := preload("res://resources/items/vital_capacity_potion.tres")
const HEALING_POTION := preload("res://resources/items/vital_essence.tres")

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	var health: HealthComponent = player.health
	var inventory: InventoryComponent = player.inventario
	var consumables: ConsumableComponent = player.get_node("ConsumableComponent")
	_check(health.max_health == 100.0 and health.current_health == 100.0, "iniciar con 100 HP máximos")

	inventory.add_item(CAPACITY_POTION, 4)
	health.drain_health(20.0)
	_check(consumables.use_item("vital_capacity_potion").success, "usar expansión vital")
	_check(health.max_health == 125.0 and health.current_health == 105.0, "aumentar máximo y actual en 25")
	_check(inventory.get_item_quantity("vital_capacity_potion") == 3, "consumir exactamente una expansión")

	for _index in range(3):
		_check(consumables.use_item("vital_capacity_potion").success, "acumular expansión")
	_check(health.max_health == 200.0 and health.current_health == 180.0, "acumular cuatro expansiones")
	_check(inventory.get_item_quantity("vital_capacity_potion") == 0, "no duplicar consumo")

	health.drain_health(50.0)
	inventory.add_item(HEALING_POTION, 1)
	_check(consumables.use_item("vital_essence").success, "usar curación normal con máximo ampliado")
	_check(health.current_health == 180.0 and health.current_health <= health.max_health, "respetar máximo dinámico al curar")

	var previous_max := health.max_health
	_check(not health.increase_max_health(0.0, 25.0), "rechazar expansión nula")
	_check(health.max_health == previous_max, "conservar máximo ante expansión inválida")

	var dead_player := PLAYER_SCENE.instantiate()
	root.add_child(dead_player)
	await process_frame
	dead_player.health.take_damage(1000.0)
	dead_player.inventario.add_item(CAPACITY_POTION, 1)
	_check(not dead_player.get_node("ConsumableComponent").use_item("vital_capacity_potion").success, "bloquear expansión en GAME_OVER/muerte")
	_check(dead_player.health.max_health == 100.0, "no ampliar al jugador muerto")

	print("HP capacity tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
