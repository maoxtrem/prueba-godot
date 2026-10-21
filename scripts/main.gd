
extends Node2D

@export var debug_settings: DebugSettings
@export var start_in_menu: bool = false
@export var safe_wave_checkpoints: bool = false

# ==========================================
# REFERENCIAS
# ==========================================

@onready var player = $Player
@onready var wave_manager: WaveManager = $WaveManager
@onready var hud: GameHUD = $HUD
@onready var inventory: InventoryComponent = $Player/InventoryComponent
@onready var equipment: EquipmentComponent = $Player/EquipmentComponent
@onready var upgrades: UpgradeManager = $Player/UpgradeManager
@onready var consumables: ConsumableComponent = $Player/ConsumableComponent
@onready var weapon_upgrades: WeaponUpgradeManager = $Player/WeaponUpgradeManager
@onready var game_manager: GameManager = $GameManager
@onready var quest_manager: QuestManager = $QuestManager
@onready var save_manager: SaveManager = $SaveManager


# ==========================================
# INICIALIZACION
# ==========================================

func _ready() -> void:
	# Centraliza las acciones de interfaz y sigue activo durante pausas modales.
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.configure_debug(debug_settings)
	game_manager.setup(player.health, wave_manager)
	upgrades.setup(player.health, player.componente_ataque, player.costo_movimiento, player, game_manager)
	weapon_upgrades.setup(inventory, equipment, game_manager)
	quest_manager.setup(inventory, player.health, game_manager)
	save_manager.setup(self)
	game_manager.game_over_reached.connect(_on_game_over_reached)
	hud.restart_requested.connect(_on_restart_requested)
	hud.set_inventory(inventory)
	hud.set_equipment(equipment)
	hud.set_consumables(consumables)
	hud.set_weapon_upgrades(weapon_upgrades)
	hud.set_quest_manager(quest_manager)

	# Conectar eventos de las oleadas
	wave_manager.wave_started.connect(
		hud.update_wave
	)

	# Conectar enemigos restantes
	wave_manager.enemy_count_changed.connect(
		hud.update_enemies
	)

	# Conectar eliminaciones totales
	wave_manager.enemy_killed.connect(
		hud.update_kills
	)
	wave_manager.enemy_killed.connect(quest_manager.register_enemy_kill)
	wave_manager.wave_completed.connect(quest_manager.register_wave_completed)
	wave_manager.wave_completed.connect(_on_wave_completed_checkpoint)
	player.get_node("PickupComponent").item_collected.connect(quest_manager.register_items_collected)

	# Conectar cambios de vida del jugador
	player.health.health_changed.connect(
		hud.update_health
	)

	# Todas las señales deben estar conectadas antes de permitir que empiece
	# la primera oleada. WaveManager inicia mediante call_deferred().
	if not start_in_menu:
		game_manager.start_game()

	# ======================================
	# SINCRONIZAR ESTADO INICIAL
	# ======================================

	hud.update_wave(
		wave_manager.current_wave,
		wave_manager.remaining_enemies
	)

	hud.update_enemies(
		wave_manager.remaining_enemies
	)

	hud.update_kills(
		wave_manager.total_kills
	)

	hud.update_health(
		player.health.current_health,
		player.health.max_health
	)


func _input(event: InputEvent) -> void:
	var is_inventory := event.is_action_pressed("toggle_inventory")
	var is_shop := event.is_action_pressed("toggle_upgrade_shop")
	var is_quests := event.is_action_pressed("toggle_quests")
	var is_cancel := event.is_action_pressed("ui_cancel")
	if not is_inventory and not is_shop and not is_quests and not is_cancel:
		return
	if event is InputEventKey and event.echo:
		return

	if is_inventory:
		_handle_inventory_input()
	elif is_shop:
		_handle_shop_input()
	elif is_quests:
		_handle_quests_input()
	else:
		_handle_cancel_input()
	get_viewport().set_input_as_handled()


func _handle_inventory_input() -> void:
	if hud.inventory_ui.visible:
		hud.inventory_ui.close_inventory()
		return
	if game_manager.current_state != GameManager.GameState.PLAYING or _has_open_modal():
		return
	hud.inventory_ui.open_inventory()


func _handle_shop_input() -> void:
	if hud.upgrade_shop.visible:
		close_upgrade_shop()
		return
	if game_manager.current_state != GameManager.GameState.PLAYING or _has_open_modal():
		return
	open_upgrade_shop()


func _handle_quests_input() -> void:
	if hud.quest_ui.visible:
		close_quests()
		return
	if game_manager.current_state != GameManager.GameState.PLAYING or _has_open_modal():
		return
	open_quests()


func _handle_cancel_input() -> void:
	if hud.between_waves_ui.visible or game_manager.current_state == GameManager.GameState.GAME_OVER:
		return
	if hud.inventory_ui.visible:
		hud.inventory_ui.close_inventory()
	elif hud.upgrade_shop.visible:
		close_upgrade_shop()
	elif hud.quest_ui.visible:
		close_quests()
	elif hud.pause_ui.visible:
		close_pause_menu()
	else:
		toggle_pause_menu()


func _has_open_modal() -> bool:
	return hud.inventory_ui.visible \
		or hud.upgrade_shop.visible \
		or hud.quest_ui.visible \
		or hud.pause_ui.visible \
		or hud.between_waves_ui.visible \
		or hud.game_over_ui.visible


func _on_game_over_reached(wave: int, total_kills: int) -> void:
	hud.show_game_over(wave, total_kills)


func _on_restart_requested() -> void:
	if not game_manager.request_restart():
		return

	get_tree().reload_current_scene()

func start_new_game() -> bool:
	if game_manager.current_state != GameManager.GameState.READY:
		return false
	if not game_manager.start_game():
		return false
	wave_manager.resume_pending_wave()
	return true

func continue_saved_game() -> Dictionary:
	if game_manager.current_state != GameManager.GameState.READY:
		return {"success": false, "error": "game_already_started"}
	var result := save_manager.load_game("", true)
	if not result.success:
		return result
	if game_manager.current_state == GameManager.GameState.BETWEEN_WAVES:
		hud.show_between_waves(wave_manager.current_wave, wave_manager.total_kills, player.health.current_health, player.health.max_health)
		return {"success": true}
	if not game_manager.start_game():
		return {"success": false, "error": "could_not_start_game"}
	wave_manager.resume_pending_wave()
	return {"success": true}

func restore_from_save(data: Dictionary) -> Dictionary:
	var serializer := SaveSerializer.new()
	var validation := serializer.validate(data)
	if not validation.success:
		return validation
	var game: Dictionary = data.game
	var player_node = player
	var inventory_data: Dictionary = game.inventory
	var restored_slots: Array[InventorySlot] = []
	var seen_instances: Dictionary = {}
	for entry in inventory_data.slots:
		var item: ItemData = serializer.resolve_item(String(entry.item_id))
		if item == null: return {"success": false, "error": "unknown_item"}
		if item.item_type == ItemData.ItemType.WEAPON:
			var weapon_data: Dictionary = entry.weapon_instance
			var instance := WeaponInstance.new(item, String(weapon_data.instance_id))
			instance.upgrade_level = int(weapon_data.upgrade_level)
			if seen_instances.has(instance.instance_id): return {"success": false, "error": "duplicate_weapon_instance"}
			seen_instances[instance.instance_id] = true
			restored_slots.append(InventorySlot.new(item, 1, instance))
		else:
			var slot := InventorySlot.new(item, int(entry.quantity))
			restored_slots.append(slot)
	var equipment_data: Dictionary = game.equipment
	var weapon_instance: WeaponInstance
	if not equipment_data.weapon.is_empty():
		var weapon_item := serializer.resolve_item(String(equipment_data.weapon.item_id))
		if weapon_item == null: return {"success": false, "error": "unknown_equipped_weapon"}
		weapon_instance = WeaponInstance.new(weapon_item, String(equipment_data.weapon.instance_id))
		weapon_instance.upgrade_level = int(equipment_data.weapon.upgrade_level)
		if seen_instances.has(weapon_instance.instance_id): return {"success": false, "error": "duplicate_weapon_instance"}
		seen_instances[weapon_instance.instance_id] = true
	var armor: ItemData = null
	if not String(equipment_data.armor_item_id).is_empty():
		armor = serializer.resolve_item(String(equipment_data.armor_item_id))
		if armor == null: return {"success": false, "error": "unknown_equipped_armor"}
	# Aplicar solo después de validar y preparar todas las referencias.
	equipment.restore_equipment(null, null)
	if not inventory.replace_slots(restored_slots, int(inventory_data.capacity)):
		return {"success": false, "error": "inventory_restore_failed"}
	equipment.restore_equipment(weapon_instance, armor)
	if not upgrades.restore_levels(game.upgrades): return {"success": false, "error": "upgrade_restore_failed"}
	if not quest_manager.restore_state(game.quests): return {"success": false, "error": "quest_restore_failed"}
	var health_data: Dictionary = game.health
	player_node.health.max_health = float(health_data.maximum)
	player_node.health.current_health = float(health_data.current)
	player_node.health.is_dead = false
	player_node.health.health_changed.emit(player_node.health.current_health, player_node.health.max_health)
	if not effects_restore(game.temporary_effects): return {"success": false, "error": "effect_restore_failed"}
	if not wave_manager.restore_statistics(int(game.wave.current), int(game.wave.kills)):
		return {"success": false, "error": "wave_restore_failed"}
	if not game_manager.restore_state_for_load(int(game.get("game_state", GameManager.GameState.READY))):
		return {"success": false, "error": "game_state_restore_failed"}
	_sync_hud()
	return {"success": true}

func effects_restore(restored: Array) -> bool:
	var serializer := SaveSerializer.new()
	return player.get_node("StatusEffectComponent").restore_effects(restored, Callable(serializer, "resolve_consumable_effect"))

func can_save_game() -> bool:
	return game_manager.current_state == GameManager.GameState.BETWEEN_WAVES and not game_manager.is_game_over() and not wave_manager.wave_active and not _has_active_enemies()

func _has_active_enemies() -> bool:
	for enemy in $EnemyContainer.get_children():
		if not enemy.is_queued_for_deletion():
			return true
	return false

func save_current_game() -> Dictionary:
	if not can_save_game():
		return {"success": false, "error": "unsafe_checkpoint"}
	return save_manager.save_game()

func toggle_pause_menu() -> bool:
	if hud.pause_ui.visible:
		return close_pause_menu()
	if game_manager.current_state != GameManager.GameState.PLAYING:
		return false
	if hud.inventory_ui.visible or hud.upgrade_shop.visible or hud.quest_ui.visible:
		return false
	if not game_manager.pause_game():
		return false
	hud.pause_ui.show_pause()
	return true

func close_pause_menu() -> bool:
	if not hud.pause_ui.visible:
		return false
	hud.pause_ui.hide_pause()
	if not game_manager.resume_game():
		return false
	return true

func _on_wave_completed_checkpoint(_wave: int) -> void:
	if game_manager.is_game_over():
		return
	if game_manager.enter_between_waves():
		hud.show_between_waves(wave_manager.current_wave, wave_manager.total_kills, player.health.current_health, player.health.max_health)

func continue_between_waves() -> bool:
	if game_manager.is_game_over():
		return false
	var continued := game_manager.continue_after_between_waves()
	if continued:
		hud.hide_between_waves()
	return continued

func _sync_hud() -> void:
	hud.update_wave(wave_manager.current_wave, wave_manager.remaining_enemies)
	hud.update_enemies(wave_manager.remaining_enemies)
	hud.update_kills(wave_manager.total_kills)
	hud.update_health(player.health.current_health, player.health.max_health)

func open_quests() -> bool:
	if game_manager.is_game_over():
		return false
	if hud.inventory_ui.visible:
		hud.inventory_ui.close_inventory()
	if hud.upgrade_shop.visible:
		close_upgrade_shop()
	if not game_manager.pause_game():
		return false
	hud.quest_ui.show_quests()
	return true

func close_quests() -> bool:
	if not hud.quest_ui.visible:
		return false
	hud.quest_ui.hide_quests()
	return game_manager.resume_game()


func is_game_over() -> bool:
	return game_manager.is_game_over()


func continue_after_upgrades() -> bool:
	return close_upgrade_shop()


func open_upgrade_shop() -> bool:
	if game_manager.is_game_over():
		return false
	if hud.quest_ui.visible:
		close_quests()
	if hud.inventory_ui.visible:
		hud.inventory_ui.close_inventory()
	if not game_manager.enter_upgrade_selection():
		return false
	hud.show_upgrade_shop(upgrades, player.health)
	return true


func close_upgrade_shop() -> bool:
	hud.close_upgrade_shop()
	return game_manager.continue_after_upgrades()
