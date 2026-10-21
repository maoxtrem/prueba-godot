extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const DAGGER := preload("res://resources/items/test_vital_dagger.tres")
const SWORD := preload("res://resources/items/test_weapon.tres")
const TARGET_SCRIPT := preload("res://tests/attack_target.gd")

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	var target := TARGET_SCRIPT.new()
	root.add_child(target)
	await process_frame

	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")
	var dagger_instance: WeaponInstance

	inventory.add_item(DAGGER, 1)
	dagger_instance = inventory.get_slots()[0].weapon_instance
	_check(is_equal_approx(dagger_instance.current_durability, 100.0), "inicializar la daga en su máximo")
	_check(equipment.equip_item("vital_dagger", dagger_instance.instance_id).success, "equipar daga durable")

	player.global_position = Vector2.ZERO
	target.global_position = Vector2(50.0, 0.0)
	var health_before: float = player.health.current_health
	_check(attack.atacar(player, &"enemigos"), "aceptar impacto válido")
	_check(is_equal_approx(dagger_instance.current_durability, 99.0), "descontar una durabilidad por impacto")
	_check(is_equal_approx(player.health.current_health, health_before - 1.0), "conservar costo HP del ataque")

	var after_hit := dagger_instance.current_durability
	_check(not attack.atacar(player, &"enemigos") and is_equal_approx(dagger_instance.current_durability, after_hit), "no desgastar durante cooldown")

	attack.tiempo_restante = 0.0
	target.global_position = Vector2(500.0, 0.0)
	var before_miss := dagger_instance.current_durability
	_check(attack.atacar(player, &"enemigos"), "conservar comportamiento de ataque sin objetivo")
	_check(is_equal_approx(dagger_instance.current_durability, before_miss), "no desgastar al fallar")

	attack.tiempo_restante = 0.0
	target.global_position = Vector2(50.0, 0.0)
	dagger_instance.current_durability = 1.0
	var before_break: float = player.health.current_health
	_check(attack.atacar(player, &"enemigos"), "aceptar el último golpe disponible")
	_check(dagger_instance.is_broken() and is_equal_approx(dagger_instance.current_durability, 0.0), "marcar el arma como rota")
	_check(is_equal_approx(player.health.current_health, before_break - 1.0), "cobrar HP del último golpe")
	attack.tiempo_restante = 0.0
	var before_rejected: float = player.health.current_health
	_check(not attack.atacar(player, &"enemigos") and is_equal_approx(player.health.current_health, before_rejected), "bloquear ataques con arma rota")

	var second_player := PLAYER_SCENE.instantiate()
	root.add_child(second_player)
	await process_frame
	var second_inventory: InventoryComponent = second_player.get_node("InventoryComponent")
	second_inventory.add_item(SWORD, 2)
	var sword_a: WeaponInstance = second_inventory.get_slots()[0].weapon_instance
	var sword_b: WeaponInstance = second_inventory.get_slots()[1].weapon_instance
	sword_a.current_durability = 12.0
	_check(is_equal_approx(sword_b.current_durability, 80.0) and is_equal_approx(sword_a.current_durability, 12.0), "mantener durabilidad independiente por ejemplar")

	print("Weapon durability tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
