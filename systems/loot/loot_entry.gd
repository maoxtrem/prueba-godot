extends Resource
class_name LootEntry

@export var item: ItemData
@export_range(0.0, 1.0, 0.01) var drop_chance: float = 0.0
@export_range(1, 999999, 1) var min_quantity: int = 1
@export_range(1, 999999, 1) var max_quantity: int = 1


func is_valid() -> bool:
	return (
		item != null
		and not item.id.strip_edges().is_empty()
		and item.max_stack > 0
		and drop_chance > 0.0
		and min_quantity > 0
		and max_quantity >= min_quantity
	)


func get_safe_chance() -> float:
	return clampf(drop_chance, 0.0, 1.0)


func get_safe_min_quantity() -> int:
	return maxi(min_quantity, 1)


func get_safe_max_quantity() -> int:
	return maxi(max_quantity, get_safe_min_quantity())
