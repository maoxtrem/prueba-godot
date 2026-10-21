extends SceneTree

const PlayerScene = preload("res://scenes/player/player.tscn")
const ItemDataScript = preload("res://systems/inventory/item_data.gd")

var checks := 0
var equipment_signal_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sword = load("res://resources/items/test_weapon.tres")
	var material = load("res://resources/items/test_material.tres")
	var second_weapon = ItemDataScript.new()
	second_weapon.id = "iron_sword"
	second_weapon.display_name = "Espada de hierro"
	second_weapon.description = "Una segunda arma para probar reemplazos."
	second_weapon.item_type = ItemData.ItemType.WEAPON
	second_weapon.max_stack = 1

	var player = PlayerScene.instantiate()
	root.add_child(player)
	await process_frame
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	equipment.equipment_changed.connect(_on_equipment_changed)

	inventory.add_item(sword, 1)
	var equip_result: Dictionary = equipment.equip_item("rusty_sword")
	_check(equip_result.get("success", false), "equipar un arma disponible")
	_check(equipment.equipped_weapon == sword, "conservar referencia del arma equipada")
	_check(inventory.get_item_quantity("rusty_sword") == 0, "retirar el arma del inventario")

	inventory.add_item(material, 1)
	_check(not equipment.equip_item("blood_fragment").get("success", false), "rechazar material como arma")
	_check(not equipment.equip_item("missing_weapon").get("success", false), "rechazar arma inexistente")

	var unequip_result: Dictionary = equipment.unequip_weapon()
	_check(unequip_result.get("success", false), "desequipar correctamente")
	_check(inventory.get_item_quantity("rusty_sword") == 1, "devolver el arma al inventario")
	_check(equipment.equipped_weapon == null, "vaciar ranura de arma")

	inventory.add_item(second_weapon, 1)
	equipment.equip_item("rusty_sword")
	var replace_result: Dictionary = equipment.equip_item("iron_sword")
	_check(replace_result.get("success", false), "reemplazar el arma equipada")
	_check(equipment.equipped_weapon == second_weapon, "equipar la nueva arma")
	_check(inventory.get_item_quantity("rusty_sword") == 1, "devolver el arma anterior")
	_check(inventory.get_item_quantity("iron_sword") == 0, "retirar la nueva arma del inventario")
	_check(inventory.get_item_quantity("rusty_sword") + inventory.get_item_quantity("iron_sword") + 1 == 2, "no duplicar objetos")

	var full_player = PlayerScene.instantiate()
	root.add_child(full_player)
	await process_frame
	var full_inventory = full_player.get_node("InventoryComponent")
	var full_equipment = full_player.get_node("EquipmentComponent")
	full_inventory.capacity = 1
	full_inventory.add_item(sword, 1)
	_check(full_equipment.equip_item("rusty_sword").get("success", false), "preparar prueba de inventario lleno")
	full_inventory.add_item(material, 1)
	_check(not full_equipment.unequip_weapon().get("success", false), "fallar desequipado sin espacio")
	_check(full_equipment.equipped_weapon == sword, "conservar arma si no hay espacio")
	_check(full_inventory.get_item_quantity("blood_fragment") == 1, "conservar contenido del inventario lleno")

	var dead_player = PlayerScene.instantiate()
	root.add_child(dead_player)
	await process_frame
	var dead_inventory = dead_player.get_node("InventoryComponent")
	var dead_equipment = dead_player.get_node("EquipmentComponent")
	dead_inventory.add_item(sword, 1)
	dead_player.get_node("HealthComponent").take_damage(100.0)
	_check(not dead_equipment.equip_item("rusty_sword").get("success", false), "bloquear equipamiento al morir")
	_check(not dead_equipment.unequip_weapon().get("success", false), "bloquear desequipamiento al morir")

	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	var main_inventory = main_instance.get_node("Player/InventoryComponent")
	var main_equipment = main_instance.get_node("Player/EquipmentComponent")
	var inventory_ui = main_instance.get_node("HUD/InventoryUI")
	main_inventory.add_item(sword, 1)
	var grid = inventory_ui.get_node("InventoryWindow/Margin/VBox/Body/LeftPanel/LeftMargin/LeftVBox/SlotGrid")
	grid.get_child(0)._on_pressed()
	inventory_ui.get_node("InventoryWindow/Margin/VBox/ActionBar/EquipButton").emit_signal("pressed")
	_check(main_equipment.equipped_weapon == sword, "actualizar equipamiento desde la interfaz")
	var equipped_label: Label = inventory_ui.get_node("InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/EquipmentPanel/EquipmentMargin/EquipmentVBox/WeaponRow/WeaponName")
	_check(equipped_label.text.contains("Arma: Espada oxidada"), "actualizar ranura visual equipada")
	_check(equipped_label.text.contains("Daño: 18.0"), "mostrar estadísticas del arma equipada")

	print("Equipment tests: ", checks, " comprobaciones correctas; señales: ", equipment_signal_count)
	quit()


func _on_equipment_changed(_slot: EquipmentComponent.EquipmentSlot, _item: ItemData) -> void:
	equipment_signal_count += 1


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
