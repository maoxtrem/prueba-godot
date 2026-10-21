extends Resource
class_name LootTable

@export var entries: Array[LootEntry] = []


func roll_loot(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if rng == null:
		return results

	for entry in entries:
		if entry == null or not entry.is_valid():
			continue

		if rng.randf() > entry.get_safe_chance():
			continue

		results.append({
			"item": entry.item,
			"quantity": rng.randi_range(
				entry.get_safe_min_quantity(),
				entry.get_safe_max_quantity()
			),
		})

	return results
