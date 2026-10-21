extends SceneTree

var checks := 0

const InventoryComponentScript = preload("res://systems/inventory/inventory_component.gd")
const ItemDataScript = preload("res://systems/inventory/item_data.gd")

var sword = load("res://resources/items/test_weapon.tres")
var material = load("res://resources/items/test_material.tres")


func _init() -> void:
	var inventory = InventoryComponentScript.new()
	var second_inventory = InventoryComponentScript.new()
	root.add_child(inventory)
	root.add_child(second_inventory)

	var changed_count := [0]
	inventory.inventory_changed.connect(func(_slots: Array) -> void:
		changed_count[0] += 1
	)

	_check(inventory.add_item(sword, 1)["added"] == 1, "agregar un objeto")
	_check(inventory.get_item_quantity("rusty_sword") == 1, "consultar cantidad")
	_check(inventory.has_item("rusty_sword"), "comprobar existencia")
	var second_sword_add := inventory.add_item(sword, 1)
	_check(second_sword_add["added"] == 1, "crear otra pila no apilable")

	var first_material_add := inventory.add_item(material, 150)
	_check(first_material_add["added"] == 150, "agregar múltiples cantidades")
	_check(inventory.get_item_quantity("blood_fragment") == 150, "mantener cantidad total")
	_check(inventory.get_slots().size() == 4, "crear segunda pila")

	var partial_remove := inventory.remove_item("blood_fragment", 40)
	_check(partial_remove["removed"] == 40, "retirar cantidad parcial")
	_check(inventory.get_item_quantity("blood_fragment") == 110, "actualizar cantidad tras retirar")

	var full_remove := inventory.remove_item("blood_fragment", 110)
	_check(full_remove["removed"] == 110, "retirar completamente un objeto")
	_check(not inventory.has_item("blood_fragment"), "eliminar pilas vacías")
	_check(inventory.add_item(material, 0)["rejected"] == 0, "rechazar cantidad cero")
	_check(inventory.add_item(material, -1)["rejected"] == 0, "rechazar cantidad negativa")
	_check(inventory.remove_item("rusty_sword", -1)["removed"] == 0, "rechazar retiro negativo")

	var fill_result := inventory.add_item(material, 99 * 18)
	_check(fill_result["added"] == 99 * 18, "llenar los espacios disponibles")
	var no_space_result := inventory.add_item(material, 1)
	_check(no_space_result["added"] == 0 and no_space_result["rejected"] == 1, "rechazar cuando no hay espacio")
	_check(inventory.get_available_space(material) == 0, "consultar espacio disponible")

	_check(changed_count[0] > 0, "emitir inventory_changed")
	_check(second_inventory.get_item_quantity("blood_fragment") == 0, "no compartir estado entre inventarios")
	_check(second_inventory.add_item(material, 2)["added"] == 2, "usar un segundo inventario")
	_check(inventory.get_item_quantity("blood_fragment") == 99 * 18, "mantener inventarios independientes")

	print("Inventory tests: ", checks, " comprobaciones correctas")
	quit()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
