extends Resource
class_name QuestData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var objectives: Array[QuestObjective] = []
@export var rewards: Array[QuestReward] = []
@export var active_on_start: bool = true

func is_valid() -> bool:
	return not id.strip_edges().is_empty() and not objectives.is_empty()
