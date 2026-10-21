extends Control
class_name PauseUI

@onready var message_label: Label = $Panel/Margin/VBox/Message
@onready var save_button: Button = $Panel/Margin/VBox/SaveButton
@onready var resume_button: Button = $Panel/Margin/VBox/ResumeButton
@onready var menu_button: Button = $Panel/Margin/VBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("toggle_pause_menu"):
			scene.toggle_pause_menu()
		get_viewport().set_input_as_handled()

func show_pause() -> void:
	message_label.text = ""
	visible = true
	var scene := get_tree().current_scene
	save_button.disabled = scene == null or not scene.has_method("can_save_game") or not scene.can_save_game()
	resume_button.grab_focus()

func hide_pause() -> void:
	visible = false

func set_message(message: String) -> void:
	message_label.text = message

func _on_resume_pressed() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("close_pause_menu"): scene.close_pause_menu()

func _on_save_pressed() -> void:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("save_current_game"): return
	var result: Dictionary = scene.save_current_game()
	set_message("Partida guardada." if result.get("success", false) else "No se pudo guardar: " + String(result.get("error", "error")))

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
