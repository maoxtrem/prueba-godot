extends SceneTree

const PlayerScene = preload("res://scenes/player/player.tscn")
const DropScene = preload("res://scenes/items/item_drop.tscn")

var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var material = load("res://resources/items/test_material.tres")
	var sword = load("res://resources/items/test_weapon.tres")
	var player = PlayerScene.instantiate()
	root.add_child(player)
	await process_frame

	var inventory = player.get_node("InventoryComponent")
	var pickup = player.get_node("PickupComponent")

	var outside_drop = _create_drop(material, 2, Vector2(300.0, 0.0))
	await physics_frame
	_check(not pickup.intentar_recoger(), "no recoger fuera del alcance")
	_check(outside_drop.quantity == 2, "conservar drop fuera del alcance")
	outside_drop.queue_free()

	var complete_drop = _create_drop(material, 3, Vector2(20.0, 0.0))
	await physics_frame
	_check(pickup.prompt.visible, "mostrar indicador dentro del alcance")
	_check(pickup.intentar_recoger(), "recoger con E mediante el componente")
	_check(inventory.get_item_quantity("blood_fragment") == 3, "transferir tipo y cantidad")
	await process_frame
	_check(not is_instance_valid(complete_drop), "eliminar drop completamente recogido")
	_check(not pickup.intentar_recoger(), "evitar duplicación al repetir recogida")

	var first_drop = _create_drop(material, 2, Vector2(20.0, 0.0))
	var second_drop = _create_drop(sword, 1, Vector2(30.0, 0.0))
	await physics_frame
	_check(pickup.intentar_recoger(), "recoger primer objeto cercano")
	await physics_frame
	_check(pickup.intentar_recoger(), "gestionar segundo objeto cercano")
	_check(inventory.get_item_quantity("rusty_sword") == 1, "recoger segundo tipo de objeto")

	var full_player = PlayerScene.instantiate()
	root.add_child(full_player)
	await process_frame
	full_player.global_position = Vector2(1000.0, 0.0)
	var full_inventory = full_player.get_node("InventoryComponent")
	full_inventory.capacity = 1
	full_inventory.add_item(sword, 1)
	var full_drop = _create_drop(material, 3, Vector2(20.0, 0.0), full_player)
	await physics_frame
	_check(not full_player.get_node("PickupComponent").intentar_recoger(), "rechazar recogida con inventario lleno")
	_check(full_drop.quantity == 3, "mantener drop con inventario lleno")

	var partial_player = PlayerScene.instantiate()
	root.add_child(partial_player)
	await process_frame
	partial_player.global_position = Vector2(2000.0, 0.0)
	var partial_inventory = partial_player.get_node("InventoryComponent")
	partial_inventory.capacity = 1
	partial_inventory.add_item(material, 98)
	var partial_drop = _create_drop(material, 3, Vector2(20.0, 0.0), partial_player)
	await physics_frame
	_check(partial_player.get_node("PickupComponent").intentar_recoger(), "realizar recogida parcial")
	_check(partial_inventory.get_item_quantity("blood_fragment") == 99, "almacenar solo el espacio disponible")
	_check(partial_drop.quantity == 2, "conservar cantidad restante")

	var dead_player = PlayerScene.instantiate()
	root.add_child(dead_player)
	await process_frame
	dead_player.global_position = Vector2(3000.0, 0.0)
	dead_player.get_node("HealthComponent").take_damage(100.0)
	var dead_drop = _create_drop(material, 1, Vector2(20.0, 0.0), dead_player)
	await physics_frame
	_check(not dead_player.get_node("PickupComponent").intentar_recoger(), "no recoger cuando el jugador está muerto")
	_check(dead_drop.quantity == 1, "conservar drop ante jugador muerto")

	_check(not pickup.prompt.visible, "ocultar indicador sin objetivo")
	print("Pickup tests: ", checks, " comprobaciones correctas")
	quit()


func _create_drop(item, amount: int, position: Vector2, parent: Node = null):
	if parent == null:
		parent = root

	var drop = DropScene.instantiate()
	parent.add_child(drop)
	var parent_position := Vector2.ZERO
	if parent is Node2D:
		parent_position = parent.global_position
	drop.global_position = parent_position + position
	drop.configurar(item, amount)
	return drop


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
