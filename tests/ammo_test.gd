extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SWORD := preload("res://resources/items/test_weapon.tres")
const AMMO := preload("res://resources/items/crossbow_bolt.tres")

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var ammo_manager: AmmoManager = player.get_node("AmmoManager")
	ammo_manager.setup(inventory, player.health)

	var package := ammo_manager.get_package("crossbow_bolt")
	_check(package.success and package.quantity == 10 and package.health_cost == 5.0, "cargar paquete de virotes")
	_check(package.item.item_type == ItemData.ItemType.AMMO and package.item.max_stack == 99, "validar tipo y apilado de munición")
	_check(ammo_manager.buy_ammo("crossbow_bolt").success, "comprar paquete con HP suficiente")
	_check(inventory.get_item_quantity("crossbow_bolt") == 10, "entregar paquete completo")
	_check(is_equal_approx(player.health.current_health, 95.0), "descontar HP exacto")
	_check(ammo_manager.buy_ammo("crossbow_bolt").success and inventory.get_item_quantity("crossbow_bolt") == 20, "apilar paquetes del mismo tipo")

	player.health.current_health = 5.0
	var health_before: float = player.health.current_health
	_check(not ammo_manager.buy_ammo("pistol_ammo").success, "rechazar HP insuficiente")
	_check(is_equal_approx(player.health.current_health, health_before) and inventory.get_item_quantity("pistol_ammo") == 0, "no cobrar ni entregar tras fallo de HP")

	inventory.capacity = 1
	inventory.clear_items()
	inventory.add_item(SWORD, 1)
	var full_health: float = player.health.current_health
	_check(not ammo_manager.buy_ammo("special_ammo").success, "rechazar inventario lleno")
	_check(is_equal_approx(player.health.current_health, full_health) and inventory.get_item_quantity("special_ammo") == 0, "no cobrar ante inventario lleno")

	var unknown := ammo_manager.get_package("unknown_ammo")
	_check(not unknown.success and not ammo_manager.buy_ammo("unknown_ammo").success, "rechazar tipo desconocido")
	_check(ammo_manager.get_available("crossbow_bolt") == 0, "consultar cantidad disponible")

	var game_manager := GameManager.new()
	root.add_child(game_manager)
	game_manager.current_state = GameManager.GameState.GAME_OVER
	ammo_manager.game_manager = game_manager
	var before_game_over: float = player.health.current_health
	_check(not ammo_manager.buy_ammo("crossbow_bolt").success, "bloquear compra en GAME_OVER")
	_check(is_equal_approx(player.health.current_health, before_game_over), "no consumir HP en GAME_OVER")

	var debug_settings := DebugSettings.new()
	debug_settings.debug_enabled = true
	debug_settings.infinite_health = true
	player.configure_debug(debug_settings)
	game_manager.current_state = GameManager.GameState.PLAYING
	inventory.capacity = 20
	var before_debug_health: float = player.health.current_health
	_check(ammo_manager.buy_ammo("pistol_ammo").success, "comprar con vida infinita de Debug")
	_check(is_equal_approx(player.health.current_health, before_debug_health), "Debug infinito no altera HP")

	var ranged := WeaponStats.new()
	var ranged_cost := WeaponCostConfig.new()
	ranged.combat_type = WeaponStats.CombatType.RANGED
	ranged.cost_config = ranged_cost
	ranged_cost.uses_ammo = true
	ranged_cost.ammo_item_id = "crossbow_bolt"
	ranged_cost.ammo_per_attack = 2
	_check(ranged.is_valid() and ranged.uses_ammo() and ranged.get_ammo_item_id() == "crossbow_bolt" and ranged.get_ammo_per_attack() == 2, "consultar munición desde WeaponCostConfig")

	print("Ammo tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
