extends RefCounted
class_name InventorySlot

var item: ItemData
var quantity: int = 0
var weapon_instance: WeaponInstance


func _init(item_data: ItemData, initial_quantity: int = 0, instance: WeaponInstance = null) -> void:
	item = item_data
	quantity = clampi(initial_quantity, 0, get_max_stack())
	if item != null and item.item_type == ItemData.ItemType.WEAPON:
		weapon_instance = instance if instance != null else WeaponInstance.new(item)


func get_max_stack() -> int:
	if item == null:
		return 0

	return maxi(item.max_stack, 1)


func get_available_space() -> int:
	return maxi(get_max_stack() - quantity, 0)


func add_quantity(amount: int) -> int:
	if amount <= 0 or item == null:
		return 0

	var added := mini(amount, get_available_space())
	quantity += added
	return added


func remove_quantity(amount: int) -> int:
	if amount <= 0:
		return 0

	var removed := mini(amount, quantity)
	quantity -= removed
	return removed
