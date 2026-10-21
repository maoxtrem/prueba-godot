extends SceneTree

const PlayerScene = preload("res://scenes/player/player.tscn")
const EnemyScene = preload("res://scenes/enemies/enemy.tscn")
const TargetScript = preload("res://tests/attack_target.gd")
const ItemDataScript = preload("res://systems/inventory/item_data.gd")
const WeaponStatsScript = preload("res://systems/equipment/weapon_stats.gd")

var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sword = load("res://resources/items/test_weapon.tres")
	var dagger = load("res://resources/items/test_vital_dagger.tres")
	var spear = load("res://resources/items/test_crimson_spear.tres")
	_check(sword.weapon_stats.damage == 18.0, "cargar estadísticas de espada")
	_check(dagger.weapon_stats.cooldown == 0.25, "cargar estadísticas de daga")
	_check(spear.weapon_stats.attack_range == 180.0, "cargar estadísticas de lanza")

	var player = PlayerScene.instantiate()
	root.add_child(player)
	var target = TargetScript.new()
	root.add_child(target)
	await process_frame

	player.global_position = Vector2.ZERO
	target.global_position = Vector2(90.0, 0.0)
	var health = player.get_node("HealthComponent")
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")

	_check(attack.dano_efectivo == attack.dano, "usar daño base sin arma")
	_check(attack.costo_vida_efectivo == attack.costo_vida, "usar costo base sin arma")
	_check(attack.alcance_efectivo == attack.alcance, "usar alcance base sin arma")
	_check(attack.tiempo_recarga_efectivo == attack.tiempo_recarga, "usar recarga base sin arma")

	inventory.add_item(sword, 1)
	equipment.equip_item("rusty_sword")
	_check(attack.dano_efectivo == 18.0, "aplicar daño de espada")
	_check(attack.costo_vida_efectivo == 5.0, "aplicar costo de espada")
	_check(attack.alcance_efectivo == 100.0, "aplicar alcance de espada")
	_check(attack.tiempo_recarga_efectivo == 0.6, "aplicar recarga de espada")

	var starting_health: float = health.current_health
	player.atacar()
	_check(true, "invocar ataque del jugador")
	_check(is_equal_approx(health.current_health, starting_health - 5.0), "consumir costo de vida de espada")
	_check(target.received_damage == 18.0, "hacer daño de espada")
	_check(not player.atacar(), "respetar cooldown")
	attack.tiempo_restante = 0.0

	inventory.add_item(dagger, 1)
	equipment.equip_item("vital_dagger")
	_check(attack.dano_efectivo == 8.0, "reemplazar por daño de daga")
	_check(attack.costo_vida_efectivo == 1.0, "reemplazar por costo de daga")
	_check(attack.tiempo_recarga_efectivo == 0.25, "reemplazar por recarga de daga")
	target.global_position = Vector2(60.0, 0.0)
	target.received_damage = 0.0
	var dagger_health: float = health.current_health
	player.atacar()
	_check(is_equal_approx(health.current_health, dagger_health - 1.0), "consumir costo de daga")
	_check(target.received_damage == 8.0, "hacer daño de daga")
	attack.tiempo_restante = 0.0

	inventory.add_item(spear, 1)
	equipment.equip_item("crimson_spear")
	_check(attack.dano_efectivo == 25.0, "reemplazar por daño de lanza")
	_check(attack.alcance_efectivo == 180.0, "reemplazar por alcance de lanza")
	target.global_position = Vector2(150.0, 0.0)
	target.received_damage = 0.0
	player.atacar()
	_check(target.received_damage == 25.0, "atacar dentro del alcance de lanza")

	target.global_position = Vector2(190.0, 0.0)
	attack.tiempo_restante = 0.0
	target.received_damage = 0.0
	player.atacar()
	_check(target.received_damage == 0.0, "rechazar objetivo fuera del alcance")

	equipment.unequip_weapon()
	_check(attack.dano_efectivo == attack.dano, "restaurar daño base al desequipar")
	_check(attack.costo_vida_efectivo == attack.costo_vida, "restaurar costo base al desequipar")

	var invalid_weapon = ItemDataScript.new()
	invalid_weapon.id = "invalid_weapon"
	invalid_weapon.display_name = "Arma inválida"
	invalid_weapon.item_type = ItemData.ItemType.WEAPON
	invalid_weapon.max_stack = 1
	var invalid_stats = WeaponStatsScript.new()
	invalid_stats.damage = -10.0
	invalid_stats.health_cost = -1.0
	invalid_stats.attack_range = -5.0
	invalid_stats.cooldown = 0.0
	invalid_weapon.weapon_stats = invalid_stats
	inventory.add_item(invalid_weapon, 1)
	equipment.equip_item("invalid_weapon")
	_check(attack.dano_efectivo == attack.dano, "usar fallback con estadísticas inválidas")
	_check(attack.costo_vida_efectivo == attack.costo_vida, "usar costo base con estadísticas inválidas")

	var enemy = EnemyScene.instantiate()
	root.add_child(enemy)
	await process_frame
	var enemy_attack: AttackComponent = enemy.get_node("AttackComponent")
	_check(enemy_attack.dano_efectivo == enemy_attack.dano, "no modificar ataque enemigo")
	_check(enemy_attack.alcance_efectivo == enemy_attack.alcance, "no modificar alcance enemigo")

	print("Weapon stats tests: ", checks, " comprobaciones correctas")
	quit()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
