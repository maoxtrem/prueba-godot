extends Resource
class_name QuestReward

enum RewardType { HEALTH, MATERIAL }

@export var reward_type: RewardType = RewardType.HEALTH
@export_range(1, 999999, 1) var amount: int = 1
@export var item_id: String = "blood_fragment"
@export var item: ItemData

func is_valid() -> bool:
	return amount > 0 and (reward_type == RewardType.HEALTH or not item_id.strip_edges().is_empty())
