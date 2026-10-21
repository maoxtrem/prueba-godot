extends Control
class_name BetweenWavesUI

@onready var wave_label: Label = $Panel/Margin/VBox/WaveLabel
@onready var kills_label: Label = $Panel/Margin/VBox/KillsLabel
@onready var health_label: Label = $Panel/Margin/VBox/HealthLabel
@onready var message_label: Label = $Panel/Margin/VBox/Message
@onready var save_button: Button = $Panel/Margin/VBox/SaveButton
@onready var next_button: Button = $Panel/Margin/VBox/NextButton
@onready var menu_button: Button = $Panel/Margin/VBox/MenuButton

var suppress_space_until_release := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	save_button.pressed.connect(_on_save_pressed)
	next_button.pressed.connect(_on_next_pressed)
	next_button.gui_input.connect(_on_next_gui_input)
	menu_button.pressed.connect(_on_menu_pressed)
	visible = false

func show_rest(wave: int, kills: int, current_health: float, maximum_health: float) -> void:
	wave_label.text = "Oleada completada: %d" % wave
	kills_label.text = "Enemigos eliminados: %d" % kills
	health_label.text = "Vida: %.0f / %.0f" % [current_health, maximum_health]
	message_label.text = ""
	visible = true
	save_button.disabled = false
	# No heredar el foco del ataque que pudo matar al último enemigo.
	# El botón sigue siendo accesible mediante Tab + Enter/Espacio de forma
	# intencional, pero no se enfoca automáticamente.
	suppress_space_until_release = true
	get_viewport().gui_release_focus()

func hide_rest() -> void:
	visible = false
	suppress_space_until_release = false

func _input(event: InputEvent) -> void:
	if not visible or not suppress_space_until_release:
		return
	if event is InputEventKey and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		if not event.pressed:
			suppress_space_until_release = false

func _on_save_pressed() -> void:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("save_current_game"):
		return
	var result: Dictionary = scene.save_current_game()
	message_label.text = "Partida guardada." if result.get("success", false) else "No se pudo guardar: %s" % String(result.get("error", "error"))

func _on_next_pressed() -> void:
	if not visible:
		return
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("continue_between_waves"):
		scene.continue_between_waves()

func _on_next_gui_input(event: InputEvent) -> void:
	if not suppress_space_until_release:
		return
	if event is InputEventKey and event.keycode == KEY_SPACE:
		next_button.accept_event()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
