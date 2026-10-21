
extends CanvasLayer
class_name GameHUD

signal restart_requested

# ==========================================
# REFERENCIAS DE LA INTERFAZ
# ==========================================

@onready var wave_label: Label = $Interface/StatusPanel/Margin/VBox/WaveLabel
@onready var enemies_label: Label = $Interface/StatusPanel/Margin/VBox/EnemiesLabel
@onready var kills_label: Label = $Interface/StatusPanel/Margin/VBox/KillsLabel
@onready var health_bar: ProgressBar = $Interface/StatusPanel/Margin/VBox/HealthBar
@onready var weapon_notice: Label = $Interface/StatusPanel/Margin/VBox/WeaponNotice
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var game_over_ui: GameOverUI = $GameOverUI
@onready var upgrade_shop: UpgradeShop = $UpgradeShop
@onready var quest_ui: QuestUI = $QuestUI
@onready var pause_ui: PauseUI = $PauseUI
@onready var between_waves_ui: BetweenWavesUI = $BetweenWavesUI


# ==========================================
# ESTADISTICAS
# ==========================================

var kills: int = 0
var ammo_manager: AmmoManager


# ==========================================
# INICIALIZACION
# ==========================================

func _ready() -> void:
	game_over_ui.restart_requested.connect(_on_restart_requested)
	update_wave(0, 0)
	update_enemies(0)
	update_kills(0)
	update_health(100.0, 100.0)


# ==========================================
# ACTUALIZAR OLEADA
# ==========================================

func update_wave(wave: int, _total: int) -> void:
	wave_label.text = "Oleada: %d" % wave


# ==========================================
# ACTUALIZAR ENEMIGOS RESTANTES
# ==========================================

func update_enemies(remaining: int) -> void:
	enemies_label.text = "Enemigos: %d" % remaining


# ==========================================
# ACTUALIZAR VIDA DEL JUGADOR
# ==========================================

func update_health(
	current: float,
	maximum: float
) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


# ==========================================
# ACTUALIZAR ELIMINACIONES
# ==========================================

func update_kills(total: int) -> void:
	kills = total
	kills_label.text = "Eliminaciones: %d" % kills

func show_weapon_broken(instance: WeaponInstance) -> void:
	if instance == null or instance.item == null:
		return
	weapon_notice.text = "Arma rota: %s" % instance.item.display_name
	weapon_notice.visible = true


# ==========================================
# REGISTRAR ELIMINACION MANUAL
# ==========================================

func register_kill() -> void:
	update_kills(kills + 1)


func show_game_over(wave: int, total_kills: int) -> void:
	inventory_ui.close_inventory()
	upgrade_shop.visible = false
	quest_ui.hide_quests()
	pause_ui.hide_pause()
	between_waves_ui.hide_rest()
	game_over_ui.show_game_over(wave, total_kills)


func show_upgrade_shop(upgrades: UpgradeManager, health: HealthComponent) -> void:
	if game_over_ui.visible:
		return
	inventory_ui.close_inventory()
	upgrade_shop.set_sources(upgrades, health, ammo_manager)
	upgrade_shop.show_shop()


func close_upgrade_shop() -> void:
	upgrade_shop.hide_shop()

func show_between_waves(wave: int, kills: int, current_health: float, maximum_health: float) -> void:
	inventory_ui.close_inventory()
	upgrade_shop.visible = false
	quest_ui.hide_quests()
	pause_ui.hide_pause()
	between_waves_ui.show_rest(wave, kills, current_health, maximum_health)

func hide_between_waves() -> void:
	between_waves_ui.hide_rest()


func _on_restart_requested() -> void:
	restart_requested.emit()


func set_inventory(inventory: InventoryComponent) -> void:
	inventory_ui.set_inventory(inventory)


func set_equipment(equipment: EquipmentComponent) -> void:
	inventory_ui.set_equipment(equipment)

func set_consumables(consumables: ConsumableComponent) -> void:
	inventory_ui.set_consumables(consumables)

func set_weapon_upgrades(upgrades: WeaponUpgradeManager) -> void:
	inventory_ui.set_weapon_upgrades(upgrades)

func set_weapon_repairs(repairs: WeaponRepairManager) -> void:
	inventory_ui.set_weapon_repairs(repairs)

func set_ammo_manager(manager: AmmoManager) -> void:
	ammo_manager = manager

func set_quest_manager(quests: QuestManager) -> void:
	quest_ui.set_manager(quests)
