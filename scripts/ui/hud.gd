
extends CanvasLayer
class_name GameHUD

signal restart_requested

# ==========================================
# REFERENCIAS DE LA INTERFAZ
# ==========================================

@onready var wave_label: Label = $Interface/WaveLabel
@onready var enemies_label: Label = $Interface/EnemiesLabel
@onready var kills_label: Label = $Interface/KillsLabel
@onready var health_bar: ProgressBar = $Interface/HealthBar
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var game_over_ui: GameOverUI = $GameOverUI
@onready var upgrade_shop: UpgradeShop = $UpgradeShop


# ==========================================
# ESTADISTICAS
# ==========================================

var kills: int = 0


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


# ==========================================
# REGISTRAR ELIMINACION MANUAL
# ==========================================

func register_kill() -> void:
	update_kills(kills + 1)


func show_game_over(wave: int, total_kills: int) -> void:
	inventory_ui.close_inventory()
	upgrade_shop.visible = false
	game_over_ui.show_game_over(wave, total_kills)


func show_upgrade_shop(upgrades: UpgradeManager, health: HealthComponent) -> void:
	if game_over_ui.visible:
		return
	inventory_ui.close_inventory()
	upgrade_shop.set_sources(upgrades, health)
	upgrade_shop.show_shop()


func close_upgrade_shop() -> void:
	upgrade_shop.hide_shop()


func _on_restart_requested() -> void:
	restart_requested.emit()


func set_inventory(inventory: InventoryComponent) -> void:
	inventory_ui.set_inventory(inventory)


func set_equipment(equipment: EquipmentComponent) -> void:
	inventory_ui.set_equipment(equipment)
