
extends Node2D

@export var debug_settings: DebugSettings

# ==========================================
# REFERENCIAS
# ==========================================

@onready var player = $Player
@onready var wave_manager: WaveManager = $WaveManager
@onready var hud: GameHUD = $HUD
@onready var inventory: InventoryComponent = $Player/InventoryComponent
@onready var equipment: EquipmentComponent = $Player/EquipmentComponent
@onready var upgrades: UpgradeManager = $Player/UpgradeManager
@onready var game_manager: GameManager = $GameManager


# ==========================================
# INICIALIZACION
# ==========================================

func _ready() -> void:
	player.configure_debug(debug_settings)
	game_manager.setup(player.health, wave_manager)
	upgrades.setup(player.health, player.componente_ataque, player.costo_movimiento, player, game_manager)
	game_manager.game_over_reached.connect(_on_game_over_reached)
	hud.restart_requested.connect(_on_restart_requested)
	hud.set_inventory(inventory)
	hud.set_equipment(equipment)
	game_manager.start_game()

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

	# Conectar cambios de vida del jugador
	player.health.health_changed.connect(
		hud.update_health
	)

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


func _on_game_over_reached(wave: int, total_kills: int) -> void:
	hud.show_game_over(wave, total_kills)


func _on_restart_requested() -> void:
	if not game_manager.request_restart():
		return

	get_tree().reload_current_scene()


func is_game_over() -> bool:
	return game_manager.is_game_over()


func continue_after_upgrades() -> bool:
	return close_upgrade_shop()


func open_upgrade_shop() -> bool:
	if game_manager.is_game_over():
		return false
	if hud.inventory_ui.visible:
		hud.inventory_ui.close_inventory()
	if not game_manager.enter_upgrade_selection():
		return false
	hud.show_upgrade_shop(upgrades, player.health)
	return true


func close_upgrade_shop() -> bool:
	hud.close_upgrade_shop()
	return game_manager.continue_after_upgrades()
