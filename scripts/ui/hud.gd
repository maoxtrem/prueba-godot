
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
@onready var game_over_panel: Panel = $Interface/GameOverPanel
@onready var restart_button: Button = $Interface/GameOverPanel/RestartButton


# ==========================================
# ESTADISTICAS
# ==========================================

var kills: int = 0


# ==========================================
# INICIALIZACION
# ==========================================

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	game_over_panel.visible = false
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


func show_game_over() -> void:
	game_over_panel.visible = true
	restart_button.grab_focus()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
