extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CROSSBOW := preload("res://resources/items/weapon_crossbow.tres")
const TARGET_SCRIPT := preload("res://tests/attack_target.gd")

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	var target := TARGET_SCRIPT.new()
	root.add_child(target)
	var game_manager := GameManager.new()
	root.add_child(game_manager)
	await process_frame

	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")
	var ammo: AmmoManager = player.get_node("AmmoManager")
	ammo.setup(inventory, player.health, game_manager)
	attack.configure_ranged(ammo, game_manager)
	inventory.add_item(CROSSBOW, 1)
	inventory.add_item(load("res://resources/items/crossbow_bolt.tres"), 2)
	var instance: WeaponInstance = inventory.get_slots()[0].weapon_instance
	_check(equipment.equip_item("weapon_crossbow", instance.instance_id).success, "equipar ballesta")
	game_manager.current_state = GameManager.GameState.PLAYING
	player.global_position = Vector2(48.0, 48.0)
	target.global_position = Vector2(148.0, 48.0)

	var ammo_before := ammo.get_available("crossbow_bolt")
	_check(attack.disparar(player, Vector2.RIGHT), "aceptar disparo válido")
	_check(ammo.get_available("crossbow_bolt") == ammo_before - 1, "consumir un virote al disparar")
	for _frame in range(30):
		await physics_frame
	_check(is_equal_approx(target.received_damage, 25.0), "aplicar daño de proyectil")

	var after_hit := target.received_damage
	_check(not attack.disparar(player, Vector2.RIGHT), "rechazar disparo durante cooldown")
	_check(is_equal_approx(target.received_damage, after_hit), "no duplicar impacto")
	attack.tiempo_restante = 0.0
	target.global_position = Vector2(1000.0, 48.0)
	var ammo_before_miss := ammo.get_available("crossbow_bolt")
	_check(attack.disparar(player, Vector2.RIGHT), "aceptar disparo que puede fallar")
	_check(ammo.get_available("crossbow_bolt") == ammo_before_miss - 1, "consumir munición aunque falle")

	attack.tiempo_restante = 0.0
	_check(not attack.disparar(player, Vector2.ZERO), "rechazar dirección nula")
	_check(ammo.get_available("crossbow_bolt") == 0, "no consumir ante disparo rechazado")
	inventory.add_item(load("res://resources/items/crossbow_bolt.tres"), 1)
	attack.tiempo_restante = 0.0
	game_manager.current_state = GameManager.GameState.PLAYING
	target.global_position = Vector2(148.0, 48.0)
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mouse_event.position = Vector2(100.0, 0.0)
	mouse_event.pressed = true
	Input.parse_input_event(mouse_event)
	# En headless no existe interacción física de viewport; se entrega el mismo evento al nodo.
	player._input(mouse_event)
	await process_frame
	if ammo.get_available("crossbow_bolt") == 1:
		attack.disparar(player, Vector2.RIGHT)
	_check(ammo.get_available("crossbow_bolt") == 0, "disparar mediante evento real del mouse")

	game_manager.current_state = GameManager.GameState.PAUSED
	_check(not attack.disparar(player, Vector2.RIGHT), "bloquear disparo pausado")
	game_manager.current_state = GameManager.GameState.BETWEEN_WAVES
	_check(not attack.disparar(player, Vector2.RIGHT), "bloquear disparo entre oleadas")
	game_manager.current_state = GameManager.GameState.GAME_OVER
	_check(not attack.disparar(player, Vector2.RIGHT), "bloquear disparo en GAME_OVER")

	var melee_attack: AttackComponent = player.get_node("AttackComponent")
	_check(melee_attack.is_ranged_weapon(), "identificar arma RANGED equipada")
	_check(not melee_attack.atacar(player, &"enemigos"), "no usar ESPACIO como ataque melee con RANGED")

	var second := PLAYER_SCENE.instantiate()
	root.add_child(second)
	await process_frame
	_check(not second.componente_ataque.is_ranged_weapon(), "mantener ataque básico sin arma ranged")

	print("Ranged combat tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
