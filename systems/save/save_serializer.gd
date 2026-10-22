extends RefCounted
class_name SaveSerializer

const WORLD_BOUNDS = preload("res://systems/world/world_bounds.gd")

const SCHEMA_VERSION := 1
const MAX_WEAPON_LEVEL := 3

func serialize_game(main_node: Node, save_id: String) -> Dictionary:
	var player: Node = main_node.get_node("Player")
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var upgrades: UpgradeManager = player.get_node("UpgradeManager")
	var quests: QuestManager = main_node.get_node_or_null("QuestManager")
	var waves: WaveManager = main_node.get_node("WaveManager")
	var effects: StatusEffectComponent = player.get_node_or_null("StatusEffectComponent")
	return {
		"schema_version": SCHEMA_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"save_id": save_id,
		"game": {
			"game_state": int(main_node.get_node("GameManager").current_state),
			"health": {"current": player.health.current_health, "maximum": player.health.max_health},
			"player_position": {"x": player.global_position.x, "y": player.global_position.y},
			"inventory": _serialize_inventory(inventory),
			"equipment": _serialize_equipment(equipment),
			"upgrades": _serialize_upgrades(upgrades),
			"quests": _serialize_quests(quests),
			"wave": {"current": waves.current_wave, "kills": waves.total_kills},
			"temporary_effects": _serialize_effects(effects),
		}
	}

func validate(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return _invalid("root_not_object")
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return _invalid("unsupported_schema_version")
	if not data.get("save_id", "") is String or String(data.get("save_id", "")).is_empty():
		return _invalid("invalid_save_id")
	var game = data.get("game", null)
	if not game is Dictionary:
		return _invalid("missing_game_state")
	var health = game.get("health", null)
	if not health is Dictionary or not health.get("current", 0) is float and not health.get("current", 0) is int or not health.get("maximum", 0) is float and not health.get("maximum", 0) is int:
		return _invalid("invalid_health")
	if float(health.get("maximum", 0)) <= 0.0 or float(health.get("current", -1)) < 0.0 or float(health.get("current", 0)) > float(health.get("maximum", 0)):
		return _invalid("invalid_health_values")
	var player_position = game.get("player_position", null)
	if player_position != null:
		if not player_position is Dictionary or not _is_number(player_position.get("x", null)) or not _is_number(player_position.get("y", null)):
			return _invalid("invalid_player_position")
		if not WORLD_BOUNDS.contains_position(Vector2(float(player_position.x), float(player_position.y))):
			return _invalid("player_position_out_of_bounds")
	var wave = game.get("wave", null)
	if not wave is Dictionary or int(wave.get("current", -1)) < 0 or int(wave.get("kills", -1)) < 0:
		return _invalid("invalid_wave_state")
	var inventory = game.get("inventory", null)
	if not _validate_inventory(inventory):
		return _invalid("invalid_inventory")
	var equipment = game.get("equipment", null)
	if not _validate_equipment(equipment, inventory):
		return _invalid("invalid_equipment")
	if not _validate_upgrades(game.get("upgrades", null)):
		return _invalid("invalid_upgrades")
	if not _validate_quests(game.get("quests", null)):
		return _invalid("invalid_quests")
	if not _validate_effects(game.get("temporary_effects", [])):
		return _invalid("invalid_temporary_effects")
	return {"success": true, "data": data}

func deserialize(data: Variant) -> Dictionary:
	var result := validate(data)
	if not result.success:
		return result
	return {"success": true, "data": result.data.duplicate(true)}

func resolve_item(item_id: String) -> ItemData:
	if item_id.is_empty(): return null
	var directory := DirAccess.open("res://resources/items")
	if directory == null: return null
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.ends_with(".tres"):
			var resource := load("res://resources/items/" + filename)
			if resource is ItemData and resource.id == item_id:
				directory.list_dir_end()
				return resource
		filename = directory.get_next()
	directory.list_dir_end()
	return null

func resolve_consumable_effect(effect_id: String) -> ConsumableData:
	var directory := DirAccess.open("res://resources/items")
	if directory == null: return null
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.ends_with(".tres"):
			var resource := load("res://resources/items/" + filename)
			if resource is ItemData and resource.consumable_data != null and resource.consumable_data.effect_id == effect_id:
				directory.list_dir_end(); return resource.consumable_data
		filename = directory.get_next()
	directory.list_dir_end()
	return null

func _serialize_inventory(inventory: InventoryComponent) -> Dictionary:
	var result: Array = []
	for slot in inventory.get_slots():
		var entry := {"item_id": slot.item.id, "quantity": slot.quantity}
		if slot.weapon_instance != null:
			entry["weapon_instance"] = _serialize_weapon_instance(slot.weapon_instance)
		result.append(entry)
	return {"capacity": inventory.capacity, "slots": result}

func _serialize_equipment(equipment: EquipmentComponent) -> Dictionary:
	var result: Dictionary = {"armor_item_id": equipment.equipped_armor.id if equipment.equipped_armor != null else ""}
	var weapon := equipment.get_equipped_weapon_instance()
	result["weapon"] = _serialize_weapon_instance(weapon)
	return result

func _serialize_weapon_instance(instance: WeaponInstance) -> Dictionary:
	if instance == null: return {}
	var result := {"item_id": instance.item.id, "instance_id": instance.instance_id, "upgrade_level": instance.upgrade_level}
	if instance.has_durability():
		result["current_durability"] = instance.current_durability
	return result

func _serialize_upgrades(upgrades: UpgradeManager) -> Dictionary:
	var result: Dictionary = {}
	for key in upgrades.upgrade_levels.keys(): result[String(key)] = int(upgrades.upgrade_levels[key])
	return result

func _serialize_quests(quests: QuestManager) -> Dictionary:
	if quests == null: return {}
	var pending: Dictionary = {}
	for quest_id in quests.pending_rewards.keys():
		pending[String(quest_id)] = _serialize_rewards(quests.pending_rewards[quest_id])
	return {"progress": quests.progress.duplicate(true), "completed": quests.completed.duplicate(true), "claimed": quests.claimed.duplicate(true), "pending_rewards": pending}

func _serialize_rewards(rewards: Array) -> Array:
	var result: Array = []
	for reward in rewards:
		result.append({"reward_type": int(reward.reward_type), "amount": int(reward.amount), "item_id": reward.item_id})
	return result

func _serialize_effects(effects: StatusEffectComponent) -> Array:
	var result: Array = []
	if effects == null: return result
	for effect_id in effects.active_effects.keys(): result.append({"effect_id": String(effect_id), "remaining": float(effects.active_effects[effect_id].remaining)})
	return result

func _validate_inventory(value: Variant) -> bool:
	if not value is Dictionary: return false
	var capacity_value = value.get("capacity", 0); var slots = value.get("slots", null)
	if not _is_integer(capacity_value): return false
	var capacity := int(capacity_value)
	if capacity < 1 or not slots is Array or slots.size() > capacity: return false
	var instances: Dictionary = {}
	for entry in slots:
		if not entry is Dictionary: return false
		var item_id := String(entry.get("item_id", "")); var item := resolve_item(item_id)
		var quantity_value = entry.get("quantity", 0)
		if not _is_integer(quantity_value): return false
		var quantity := int(quantity_value)
		if item == null or quantity <= 0 or quantity > item.max_stack: return false
		if item.item_type == ItemData.ItemType.WEAPON:
			var weapon = entry.get("weapon_instance", null)
			if not weapon is Dictionary: return false
			var instance_id := String(weapon.get("instance_id", "")); var level_value = weapon.get("upgrade_level", -1)
			if not _is_integer(level_value): return false
			var level := int(level_value)
			if instance_id.is_empty() or instances.has(instance_id) or level < 0 or level > MAX_WEAPON_LEVEL or quantity != 1: return false
			if not _validate_weapon_durability(item, weapon): return false
			instances[instance_id] = true
		elif entry.has("weapon_instance"):
			return false
	return true

func _validate_equipment(value: Variant, inventory: Dictionary) -> bool:
	if not value is Dictionary: return false
	var weapon = value.get("weapon", {})
	if weapon != null and not weapon is Dictionary: return false
	if weapon is Dictionary and not weapon.is_empty():
		var item := resolve_item(String(weapon.get("item_id", "")))
		var level_value = weapon.get("upgrade_level", -1)
		if not _is_integer(level_value): return false
		var level := int(level_value)
		var instance_id := String(weapon.get("instance_id", ""))
		if item == null or item.item_type != ItemData.ItemType.WEAPON or level < 0 or level > MAX_WEAPON_LEVEL or instance_id.is_empty(): return false
		if not _validate_weapon_durability(item, weapon): return false
		for entry in inventory.get("slots", []):
			var stored = entry.get("weapon_instance", {})
			if stored is Dictionary and String(stored.get("instance_id", "")) == instance_id: return false
	var armor_id := String(value.get("armor_item_id", ""))
	if not armor_id.is_empty():
		var armor := resolve_item(armor_id)
		if armor == null or armor.item_type != ItemData.ItemType.ARMOR: return false
	return true

func _validate_weapon_durability(item: ItemData, weapon: Dictionary) -> bool:
	if item == null or item.weapon_stats == null:
		return false
	var uses_durability := item.weapon_stats.uses_durability()
	if not weapon.has("current_durability"):
		return true # Guardado anterior: se inicializa al máximo al restaurar.
	var value = weapon.get("current_durability")
	if not _is_number(value):
		return false
	if not uses_durability:
		return false
	return float(value) >= 0.0 and float(value) <= item.weapon_stats.get_max_durability()

func _validate_upgrades(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in value.keys():
		var upgrade := _find_upgrade(String(key))
		if not key is String or upgrade == null or not _is_integer(value[key]) or int(value[key]) < 0 or int(value[key]) > upgrade.max_level: return false
	return true

func _is_known_upgrade(upgrade_id: String) -> bool:
	return _find_upgrade(upgrade_id) != null

func _find_upgrade(upgrade_id: String) -> UpgradeData:
	var directory := DirAccess.open("res://resources/upgrades")
	if directory == null: return null
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.ends_with(".tres"):
			var resource := load("res://resources/upgrades/" + filename)
			if resource is UpgradeData and resource.id == upgrade_id:
				directory.list_dir_end(); return resource
		filename = directory.get_next()
	directory.list_dir_end()
	return null

func _validate_quests(value: Variant) -> bool:
	if value == null: return true
	if not value is Dictionary: return false
	for field in ["progress", "completed", "claimed"]:
		if not value.get(field, {}) is Dictionary: return false
		for quest_id in value[field].keys():
			if not quest_id is String or not _is_known_quest(String(quest_id)): return false
	var pending = value.get("pending_rewards", {})
	if not pending is Dictionary: return false
	for quest_id in pending.keys():
		if not quest_id is String or not _is_known_quest(String(quest_id)): return false
		if not pending[quest_id] is Array: return false
		for reward in pending[quest_id]:
			if not reward is Dictionary or not _is_integer(reward.get("reward_type", -1)) or not _is_integer(reward.get("amount", 0)):
				return false
			if int(reward.reward_type) < QuestReward.RewardType.HEALTH or int(reward.reward_type) > QuestReward.RewardType.MATERIAL or int(reward.amount) <= 0:
				return false
			if int(reward.reward_type) == QuestReward.RewardType.MATERIAL:
				var item := resolve_item(String(reward.get("item_id", "")))
				if item == null or item.item_type != ItemData.ItemType.MATERIAL: return false
	return true

func _validate_effects(value: Variant) -> bool:
	if not value is Array: return false
	var seen: Dictionary = {}
	for entry in value:
		if not entry is Dictionary: return false
		var effect_id := String(entry.get("effect_id", ""))
		var remaining = entry.get("remaining", -1.0)
		if effect_id.is_empty() or seen.has(effect_id) or not _is_number(remaining) or float(remaining) <= 0.0:
			return false
		seen[effect_id] = true
	return true

func _is_known_quest(quest_id: String) -> bool:
	var directory := DirAccess.open("res://resources/quests")
	if directory == null: return false
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.ends_with(".tres"):
			var resource := load("res://resources/quests/" + filename)
			if resource is QuestData and resource.id == quest_id:
				directory.list_dir_end(); return true
		filename = directory.get_next()
	directory.list_dir_end()
	return false

func _is_integer(value: Variant) -> bool:
	if not value is int and not value is float: return false
	return is_finite(float(value)) and is_equal_approx(float(value), floorf(float(value)))

func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _invalid(reason: String) -> Dictionary:
	return {"success": false, "error": reason}
