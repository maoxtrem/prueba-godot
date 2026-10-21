extends SceneTree

const PlayerScene = preload("res://scenes/player/player.tscn")
const Sword = preload("res://resources/items/test_weapon.tres")

var checks := 0
var purchase_signals := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player = PlayerScene.instantiate()
	root.add_child(player)
	await process_frame
	var health: HealthComponent = player.get_node("HealthComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")
	var movement: MovementCostComponent = player.get_node("MovementCostComponent")
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var upgrades: UpgradeManager = player.get_node("UpgradeManager")
	upgrades.setup(health, attack, movement, player)
	upgrades.upgrade_purchased.connect(_on_upgrade_purchased)

	_check(upgrades.available_upgrades.size() == 4, "cargar las cuatro mejoras")
	_check(upgrades.purchase_upgrade("light_legs"), "comprar Piernas ligeras")
	_check(health.current_health == 85.0, "descontar el costo de vida")
	_check(purchase_signals == 1, "emitir señal de compra")
	_check(player.velocidad_efectiva == 240.0, "aplicar velocidad efectiva")
	_check(upgrades.purchase_upgrade("efficient_step"), "comprar Paso eficiente")
	_check(is_equal_approx(movement.multiplicador_movimiento_efectivo, 0.8), "aplicar costo de movimiento efectivo")

	_check(upgrades.purchase_upgrade("sharpened_blood"), "comprar Sangre afilada")
	_check(is_equal_approx(attack.dano_efectivo, 12.5), "aplicar daño de mejora sin arma")
	_check(upgrades.purchase_upgrade("hunter_vision"), "comprar Visión de cazador")
	_check(is_equal_approx(attack.alcance_efectivo, 180.0), "aplicar alcance de mejora sin arma")

	inventory.add_item(Sword, 1)
	_check(equipment.equip_item("rusty_sword").get("success", false), "equipar arma con mejora activa")
	_check(is_equal_approx(attack.dano_efectivo, 22.5), "conservar daño al equipar arma")
	_check(is_equal_approx(attack.alcance_efectivo, 120.0), "conservar alcance al equipar arma")
	_check(equipment.unequip_weapon().get("success", false), "desequipar sin perder mejoras")
	_check(is_equal_approx(attack.dano_efectivo, 12.5), "conservar daño al desequipar")

	_check(upgrades.purchase_upgrade("light_legs"), "subir una mejora de nivel")
	_check(upgrades.purchase_upgrade("light_legs"), "subir una mejora al nivel máximo")
	var health_before_max := health.current_health
	_check(not upgrades.purchase_upgrade("light_legs"), "rechazar nivel superior al máximo")
	_check(health.current_health == health_before_max, "no cobrar nivel inválido")

	health.current_health = 10.0
	_check(not upgrades.purchase_upgrade("efficient_step"), "rechazar vida insuficiente")
	_check(health.current_health == 10.0, "no cobrar compra fallida")
	health.take_damage(10.0)
	_check(health.is_dead, "marcar jugador muerto")
	_check(not upgrades.purchase_upgrade("hunter_vision"), "rechazar compra estando muerto")

	var second_player = PlayerScene.instantiate()
	root.add_child(second_player)
	await process_frame
	var second_upgrades: UpgradeManager = second_player.get_node("UpgradeManager")
	_check(second_upgrades.get_upgrade_level("light_legs") == 0, "no compartir niveles entre partidas")

	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	await process_frame
	var main_upgrades: UpgradeManager = main_instance.get_node("Player/UpgradeManager")
	var main_health: HealthComponent = main_instance.get_node("Player/HealthComponent")
	main_health.take_damage(100.0)
	_check(not main_upgrades.purchase_upgrade("light_legs"), "rechazar compras en GAME_OVER")

	print("Upgrade manager tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)

func _on_upgrade_purchased(_upgrade: UpgradeData, _level: int, _health_remaining: float) -> void:
	purchase_signals += 1
