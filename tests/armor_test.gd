extends SceneTree

var checks := 0
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CLOTH := preload("res://resources/items/reinforced_cloth.tres")
const IRON := preload("res://resources/items/iron_cuirass.tres")
const CRIMSON := preload("res://resources/items/crimson_armor.tres")
const SWORD := preload("res://resources/items/test_weapon.tres")
const BASIC_LOOT := preload("res://resources/loot/basic_enemy_loot.tres")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var health: HealthComponent = player.get_node("HealthComponent")
	var movement: MovementCostComponent = player.get_node("MovementCostComponent")
	var attack: AttackComponent = player.get_node("AttackComponent")

	inventory.add_item(CLOTH, 1)
	_check(equipment.equip_item("reinforced_cloth").success, "equipar tela reforzada")
	_check(inventory.get_item_quantity("reinforced_cloth") == 0, "retirar armadura del inventario")
	health.reset_health()
	player.recibir_dano_de_enemigo(20.0)
	_check(is_equal_approx(health.current_health, 82.0), "reducir daño enemigo al 90 por ciento")
	health.reset_health()
	movement.procesar_movimiento(100.0)
	_check(is_equal_approx(health.current_health, 99.0), "no aplicar defensa al costo de caminar")
	_check(is_equal_approx(attack.costo_vida_efectivo, 3.0), "no aplicar defensa al costo de atacar")

	inventory.add_item(IRON, 1)
	_check(equipment.equip_item("iron_cuirass").success, "reemplazar armadura")
	_check(equipment.equipped_armor == IRON and inventory.get_item_quantity("reinforced_cloth") == 1, "devolver armadura anterior")
	_check(is_equal_approx(player.velocidad_efectiva, 180.0), "aplicar penalización de velocidad")
	_check(is_equal_approx(movement.multiplicador_movimiento_efectivo, 1.0), "coraza sin penalización de costo")

	inventory.add_item(CRIMSON, 1)
	_check(equipment.equip_item("crimson_armor").success, "equipar armadura carmesí")
	_check(is_equal_approx(movement.multiplicador_movimiento_efectivo, 1.2), "aplicar penalización de costo")
	_check(is_equal_approx(player.velocidad_efectiva, 200.0), "carmesí conserva velocidad base")
	_check(equipment.equipped_weapon == null, "armadura no modifica el arma")
	inventory.add_item(SWORD, 1)
	_check(equipment.equip_item("rusty_sword").success, "equipar arma con armadura")
	_check(equipment.equipped_armor == CRIMSON, "conservar armadura al equipar arma")

	var ui_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui_main)
	set_current_scene(ui_main)
	await process_frame
	var ui_inventory: InventoryComponent = ui_main.get_node("Player/InventoryComponent")
	var ui_equipment: EquipmentComponent = ui_main.get_node("Player/EquipmentComponent")
	var ui: InventoryUI = ui_main.get_node("HUD/InventoryUI")
	ui_inventory.add_item(CLOTH, 1)
	var grid: GridContainer = ui.get_node("InventoryWindow/Margin/VBox/Body/LeftPanel/LeftMargin/LeftVBox/SlotGrid")
	grid.get_child(0)._on_pressed()
	ui.get_node("InventoryWindow/Margin/VBox/ActionBar/EquipArmorButton").emit_signal("pressed")
	_check(ui_equipment.equipped_armor == CLOTH, "equipar armadura desde la interfaz")
	_check(ui.get_node("InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/ArmorPanel/ArmorMargin/ArmorRow/ArmorName").text.contains("Tela reforzada"), "mostrar armadura equipada")
	_check(is_equal_approx(BASIC_LOOT.entries[6].drop_chance, 0.08), "drop de tela al 8 por ciento")
	_check(is_equal_approx(BASIC_LOOT.entries[7].drop_chance, 0.03), "drop de coraza al 3 por ciento")
	_check(is_equal_approx(BASIC_LOOT.entries[8].drop_chance, 0.01), "drop de armadura carmesí al 1 por ciento")

	print("Armor tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
