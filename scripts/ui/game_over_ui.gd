extends Control
class_name GameOverUI

signal restart_requested

@onready var wave_label: Label = $Panel/Margin/VBox/WaveLabel
@onready var kills_label: Label = $Panel/Margin/VBox/KillsLabel
@onready var restart_button: Button = $Panel/Margin/VBox/RestartButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	restart_button.pressed.connect(_on_restart_pressed)
	visible = false


func show_game_over(wave: int, total_kills: int) -> void:
	wave_label.text = "Oleada alcanzada: %d" % wave
	kills_label.text = "Enemigos eliminados: %d" % total_kills
	visible = true
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	restart_requested.emit()
