extends SceneTree

var checks := 0
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SWORD := preload("res://resources/items/test_weapon.tres")
const MATERIAL := preload("res://resources/items/test_material.tres")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")
	var upgrades: WeaponUpgradeManager = player.get_node("WeaponUpgradeManager")
	upgrades.setup(inventory, equipment)
	inventory.add_item(SWORD, 2)
	inventory.add_item(MATERIAL, 35)
	var slots := inventory.get_slots()
	var first: WeaponInstance = slots[0].weapon_instance
	var second: WeaponInstance = slots[1].weapon_instance
	_check(first.instance_id != second.instance_id, "crear IDs distintos por ejemplar")
	_check(upgrades.get_next_cost(first) == 5, "consultar costo de nivel uno")
	_check(upgrades.upgrade_weapon(first.instance_id).success, "mejorar arma almacenada a +1")
	_check(first.upgrade_level == 1 and inventory.get_item_quantity("blood_fragment") == 30, "consumir cinco fragmentos")
	_check(second.upgrade_level == 0, "no compartir nivel entre armas")
	_check(upgrades.upgrade_weapon(first.instance_id).success and upgrades.upgrade_weapon(first.instance_id).success, "mejorar hasta +3")
	_check(first.upgrade_level == 3 and inventory.get_item_quantity("blood_fragment") == 0, "consumir costos 10 y 20")
	_check(not upgrades.upgrade_weapon(first.instance_id).success and first.upgrade_level == 3, "rechazar nivel +4")
	_check(is_equal_approx(SWORD.weapon_stats.damage * first.damage_multiplier(), 23.4), "calcular daño base con +30 por ciento")

	inventory.add_item(MATERIAL, 5)
	_check(equipment.equip_item("rusty_sword", first.instance_id).success, "equipar ejemplar mejorado")
	_check(equipment.get_equipped_weapon_instance() == first, "conservar instancia al equipar")
	_check(is_equal_approx(attack.dano_efectivo, 23.4), "aplicar daño del arma mejorada")
	_check(upgrades.upgrade_weapon(first.instance_id).success == false, "rechazar mejora sin fragmentos suficientes")

	inventory.add_item(MATERIAL, 5)
	_check(upgrades.upgrade_weapon(second.instance_id).success, "mejorar segundo ejemplar almacenado")
	_check(second.upgrade_level == 1 and first.upgrade_level == 3, "mantener niveles independientes")
	_check(equipment.unequip_weapon().success, "desequipar conservando instancia")
	_check(inventory.get_slots().any(func(slot: InventorySlot) -> bool: return slot.weapon_instance == first and slot.weapon_instance.upgrade_level == 3), "conservar nivel al desequipar")
	_check(equipment.equip_item("rusty_sword", second.instance_id).success, "equipar segundo ejemplar")
	inventory.add_item(MATERIAL, 5)
	_check(upgrades.upgrade_weapon(second.instance_id).success, "mejorar arma equipada")
	_check(is_equal_approx(attack.dano_efectivo, 21.6), "actualizar daño del arma equipada")

	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	var main_inventory: InventoryComponent = main_instance.get_node("Player/InventoryComponent")
	var main_ui: InventoryUI = main_instance.get_node("HUD/InventoryUI")
	main_inventory.add_item(SWORD, 1)
	main_inventory.add_item(MATERIAL, 5)
	var grid: GridContainer = main_ui.get_node("InventoryWindow/Margin/VBox/Body/LeftPanel/LeftMargin/LeftVBox/SlotGrid")
	grid.get_child(0)._on_pressed()
	main_ui.get_node("InventoryWindow/Margin/VBox/ActionBar/UpgradeButton").emit_signal("pressed")
	_check(main_inventory.get_slots()[0].weapon_instance.upgrade_level == 1, "mejorar arma desde InventoryUI")

	print("Weapon upgrade tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
