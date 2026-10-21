extends Control
class_name QuestUI

@onready var quest_list: VBoxContainer = $Panel/Margin/VBox/QuestList
@onready var close_button: Button = $Panel/Margin/VBox/Header/CloseButton
@onready var message_label: Label = $Panel/Margin/VBox/Message
var quest_manager: QuestManager
var cards: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(_on_close_pressed)
	visible = false

func set_manager(manager: QuestManager) -> void:
	if quest_manager != null:
		if quest_manager.quest_progress_changed.is_connected(_on_progress_changed): quest_manager.quest_progress_changed.disconnect(_on_progress_changed)
		if quest_manager.quest_completed.is_connected(_on_quest_event): quest_manager.quest_completed.disconnect(_on_quest_event)
		if quest_manager.reward_claimed.is_connected(_on_quest_event): quest_manager.reward_claimed.disconnect(_on_quest_event)
		if quest_manager.reward_pending.is_connected(_on_quest_event): quest_manager.reward_pending.disconnect(_on_quest_event)
	quest_manager = manager
	if quest_manager != null:
		quest_manager.quest_progress_changed.connect(_on_progress_changed)
		quest_manager.quest_completed.connect(_on_quest_event)
		quest_manager.reward_claimed.connect(_on_quest_event)
		quest_manager.reward_pending.connect(_on_quest_event)
		_build_cards()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_quests"): return
	var scene := get_tree().current_scene
	if scene != null:
		if visible and scene.has_method("close_quests"): scene.close_quests()
		elif not visible and scene.has_method("open_quests"): scene.open_quests()
	get_viewport().set_input_as_handled()

func show_quests() -> void:
	if quest_manager == null: return
	_refresh()
	visible = true
	close_button.grab_focus()

func hide_quests() -> void:
	visible = false

func _build_cards() -> void:
	for child in quest_list.get_children(): child.queue_free()
	cards.clear()
	if quest_manager == null: return
	for quest in quest_manager.available_quests:
		if quest == null: continue
		var panel := PanelContainer.new()
		var box := VBoxContainer.new()
		var title := Label.new(); title.text = quest.display_name
		var description := Label.new(); description.text = quest.description; description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var progress_label := Label.new()
		var reward_label := Label.new()
		var button := Button.new(); button.text = "Reclamar"; button.pressed.connect(_on_claim_pressed.bind(quest.id))
		box.add_child(title); box.add_child(description); box.add_child(progress_label); box.add_child(reward_label); box.add_child(button)
		panel.add_child(box); quest_list.add_child(panel)
		cards.append({"quest": quest, "progress": progress_label, "reward": reward_label, "button": button})
	_refresh()

func _refresh(_arg = null) -> void:
	if quest_manager == null: return
	for card in cards:
		var quest: QuestData = card.quest
		var objective: QuestObjective = quest.objectives[0] if not quest.objectives.is_empty() else null
		var current := quest_manager.get_progress(quest.id)
		var target := objective.target_amount if objective != null else 0
		var can_claim := quest_manager.can_claim(quest.id)
		card.progress.text = "Progreso: %d / %d — %s" % [current, target, "Completada" if quest_manager.is_completed(quest.id) else "Activa"]
		card.reward.text = _reward_text(quest)
		card.button.disabled = not can_claim
		card.button.text = "Reclamar" if can_claim else ("Pendiente" if quest_manager.has_pending_reward(quest.id) else "Reclamada")

func _reward_text(quest: QuestData) -> String:
	var texts: Array[String] = []
	for reward in quest.rewards:
		texts.append(("+%d HP" % reward.amount) if reward.reward_type == QuestReward.RewardType.HEALTH else "+%d %s" % [reward.amount, reward.item_id])
	return "Recompensa: " + ", ".join(texts)

func _on_claim_pressed(quest_id: String) -> void:
	var result := quest_manager.claim_quest(quest_id)
	message_label.text = "Recompensa entregada." if result.get("success", false) else "Recompensa pendiente: inventario lleno."
	_refresh()

func _on_progress_changed(_quest: QuestData, _progress: int, _target: int) -> void: _refresh()
func _on_quest_event(_quest: QuestData) -> void: _refresh()

func _on_close_pressed() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("close_quests"): scene.close_quests()
