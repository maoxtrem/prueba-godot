extends Node
class_name QuestManager

signal quest_progress_changed(quest: QuestData, progress: int, target: int)
signal quest_completed(quest: QuestData)
signal reward_claimed(quest: QuestData)
signal reward_pending(quest: QuestData)

@export var available_quests: Array[QuestData] = []

var inventory: InventoryComponent
var health: HealthComponent
var game_manager: GameManager
var progress: Dictionary = {}
var completed: Dictionary = {}
var claimed: Dictionary = {}
var pending_rewards: Dictionary = {}
var last_enemy_total: int = 0
var last_completed_wave: int = 0

func setup(inventory_component: InventoryComponent, health_component: HealthComponent, game_manager_node: GameManager = null) -> void:
	inventory = inventory_component
	health = health_component
	game_manager = game_manager_node
	for quest in available_quests:
		if quest != null and quest.is_valid() and quest.active_on_start and not progress.has(quest.id):
			progress[quest.id] = 0

func register_enemy_kill(total_kills: int = 0) -> void:
	if total_kills > 0:
		if total_kills <= last_enemy_total: return
		var delta := total_kills - last_enemy_total
		last_enemy_total = total_kills
		_register_event(QuestObjective.ObjectiveType.ENEMY_KILLS, delta)
	else:
		_register_event(QuestObjective.ObjectiveType.ENEMY_KILLS, 1)

func register_wave_completed(wave: int = 0) -> void:
	if wave > 0:
		if wave <= last_completed_wave: return
		var delta := wave - last_completed_wave
		last_completed_wave = wave
		_register_event(QuestObjective.ObjectiveType.WAVES_COMPLETED, delta)
	else:
		_register_event(QuestObjective.ObjectiveType.WAVES_COMPLETED, 1)

func register_items_collected(quantity: int) -> void:
	if quantity > 0:
		_register_event(QuestObjective.ObjectiveType.ITEMS_COLLECTED, quantity)

func get_progress(quest_id: String) -> int:
	return int(progress.get(quest_id, 0))

func is_completed(quest_id: String) -> bool:
	return bool(completed.get(quest_id, false))

func has_pending_reward(quest_id: String) -> bool:
	return pending_rewards.has(quest_id)

func restore_state(restored: Dictionary) -> bool:
	if restored == null: return true
	for quest_id in restored.get("progress", {}).keys():
		if _find_quest(String(quest_id)) == null: return false
	progress = restored.get("progress", {}).duplicate(true)
	completed = restored.get("completed", {}).duplicate(true)
	claimed = restored.get("claimed", {}).duplicate(true)
	pending_rewards.clear()
	for quest_id in restored.get("pending_rewards", {}).keys():
		var rewards: Array[QuestReward] = []
		for entry in restored.pending_rewards[quest_id]:
			var reward := QuestReward.new()
			reward.reward_type = int(entry.get("reward_type", 0))
			reward.amount = int(entry.get("amount", 0))
			reward.item_id = String(entry.get("item_id", ""))
			reward.item = _find_item(reward.item_id)
			if not reward.is_valid() or (reward.reward_type == QuestReward.RewardType.MATERIAL and reward.item == null): return false
			rewards.append(reward)
		pending_rewards[String(quest_id)] = rewards
	return true

func can_claim(quest_id: String) -> bool:
	return is_completed(quest_id) and not claimed.get(quest_id, false)

func claim_quest(quest_id: String) -> Dictionary:
	if _is_game_over():
		return {"success": false, "reason": "game_over"}
	if not can_claim(quest_id):
		return {"success": false, "reason": "not_claimable"}
	var quest := _find_quest(quest_id)
	if quest == null:
		return {"success": false, "reason": "quest_not_found"}
	var pending: Array = pending_rewards.get(quest_id, _copy_rewards(quest.rewards))
	var remaining: Array[QuestReward] = []
	for reward in pending:
		if reward == null or not reward.is_valid():
			continue
		if reward.reward_type == QuestReward.RewardType.HEALTH:
			if health != null and not health.is_dead:
				health.heal(reward.amount)
		else:
			var item: ItemData = reward.item if reward.item != null else _find_item(reward.item_id)
			if item == null or inventory == null:
				remaining.append(reward)
				continue
			var result := inventory.add_item(item, reward.amount)
			var added := int(result.get("added", 0))
			if added < reward.amount:
				var left := reward.duplicate() as QuestReward
				left.amount = reward.amount - added
				remaining.append(left)
	if remaining.is_empty():
		pending_rewards.erase(quest_id)
		claimed[quest_id] = true
		reward_claimed.emit(quest)
		return {"success": true, "pending": false}
	pending_rewards[quest_id] = remaining
	reward_pending.emit(quest)
	return {"success": false, "pending": true, "reason": "inventory_full"}

func _register_event(event_type: QuestObjective.ObjectiveType, amount: int) -> void:
	if _is_game_over():
		return
	for quest in available_quests:
		if quest == null or not quest.is_valid() or not progress.has(quest.id) or is_completed(quest.id):
			continue
		for objective in quest.objectives:
			if objective != null and objective.is_valid() and objective.objective_type == event_type:
				var current := get_progress(quest.id)
				var next := mini(current + amount, objective.target_amount)
				if next == current:
					continue
				progress[quest.id] = next
				quest_progress_changed.emit(quest, next, objective.target_amount)
				if next >= objective.target_amount:
					completed[quest.id] = true
					quest_completed.emit(quest)

func _find_quest(quest_id: String) -> QuestData:
	for quest in available_quests:
		if quest != null and quest.id == quest_id:
			return quest
	return null

func _find_item(item_id: String) -> ItemData:
	if inventory != null:
		for slot in inventory.get_slots():
			if slot.item != null and slot.item.id == item_id:
				return slot.item
	# Las recompensas pendientes también deben poder restaurarse cuando el
	# material todavía no está presente en el inventario.
	return SaveSerializer.new().resolve_item(item_id)

func _copy_rewards(rewards: Array[QuestReward]) -> Array:
	var result: Array = []
	for reward in rewards:
		result.append(reward.duplicate(true))
	return result

func _is_game_over() -> bool:
	return game_manager != null and game_manager.is_game_over()
