extends Resource
class_name QuestObjective

enum ObjectiveType { ENEMY_KILLS, WAVES_COMPLETED, ITEMS_COLLECTED }

@export var objective_type: ObjectiveType = ObjectiveType.ENEMY_KILLS
@export_range(1, 999999, 1) var target_amount: int = 1

func is_valid() -> bool:
	return target_amount > 0
