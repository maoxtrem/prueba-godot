extends Node
class_name InventoryComponent

signal inventory_changed(slots: Array[InventorySlot])

@export_range(1, 999999, 1) var capacity: int = 20

var slots: Array[InventorySlot] = []


func add_item(item: ItemData, quantity: int) -> Dictionary:
	if not _is_valid_item(item) or quantity <= 0:
		return {
			"success": false,
			"added": 0,
			"rejected": maxi(quantity, 0),
		}

	var remaining := quantity
	if item.item_type == ItemData.ItemType.WEAPON:
		while remaining > 0 and slots.size() < capacity:
			slots.append(InventorySlot.new(item, 1))
			remaining -= 1
		var added_weapons := quantity - remaining
		if added_weapons > 0:
			_emit_inventory_changed()
		return {"success": remaining == 0, "added": added_weapons, "rejected": remaining}

	# Primero se completan las pilas existentes del mismo ID.
	for slot in slots:
		if remaining <= 0:
			break

		if slot.item.id != item.id:
			continue

		remaining -= slot.add_quantity(remaining)

	# Después se crean nuevas pilas hasta agotar la capacidad.
	while remaining > 0 and slots.size() < capacity:
		var slot := InventorySlot.new(item)
		var added := slot.add_quantity(remaining)

		if added <= 0:
			break

		slots.append(slot)
		remaining -= added

	var added_total := quantity - remaining
	if added_total > 0:
		_emit_inventory_changed()

	return {
		"success": remaining == 0,
		"added": added_total,
		"rejected": remaining,
	}

func add_weapon_instance(instance: WeaponInstance) -> Dictionary:
	if instance == null or instance.item == null or instance.item.item_type != ItemData.ItemType.WEAPON:
		return {"success": false, "added": 0, "rejected": 1}
	if slots.size() >= capacity:
		return {"success": false, "added": 0, "rejected": 1}
	slots.append(InventorySlot.new(instance.item, 1, instance))
	_emit_inventory_changed()
	return {"success": true, "added": 1, "rejected": 0}


func remove_item(item_id: String, quantity: int) -> Dictionary:
	if item_id.strip_edges().is_empty() or quantity <= 0:
		return {
			"success": false,
			"removed": 0,
			"rejected": maxi(quantity, 0),
		}

	var remaining := quantity
	for index in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break

		var slot := slots[index]
		if slot.item.id != item_id:
			continue

		remaining -= slot.remove_quantity(remaining)
		if slot.quantity == 0:
			slots.remove_at(index)

	var removed := quantity - remaining
	if removed > 0:
		_emit_inventory_changed()

	return {
		"success": remaining == 0,
		"removed": removed,
		"rejected": remaining,
	}


func has_item(item_id: String, quantity: int = 1) -> bool:
	return quantity > 0 and get_item_quantity(item_id) >= quantity


func get_item_quantity(item_id: String) -> int:
	if item_id.strip_edges().is_empty():
		return 0

	var total := 0
	for slot in slots:
		if slot.item.id == item_id:
			total += slot.quantity

	return total


func get_available_space(item: ItemData) -> int:
	if not _is_valid_item(item):
		return 0

	var available := (capacity - slots.size()) * item.max_stack
	for slot in slots:
		if slot.item.id == item.id:
			available += slot.get_available_space()

	return maxi(available, 0)


func get_slots() -> Array[InventorySlot]:
	return slots.duplicate()


func _is_valid_item(item: ItemData) -> bool:
	return (
		item != null
		and not item.id.strip_edges().is_empty()
		and item.max_stack > 0
	)


func _emit_inventory_changed() -> void:
	inventory_changed.emit(get_slots())
