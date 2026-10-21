extends Node2D
class_name MainMenu

@onready var game: Node = $Main
@onready var menu_ui: Control = $MenuUI
@onready var continue_button: Button = $MenuUI/Panel/Margin/VBox/ContinueButton
@onready var message_label: Label = $MenuUI/Panel/Margin/VBox/Message

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.disabled = not game.save_manager.has_save()

func _on_new_game_pressed() -> void:
	var started: bool = game.start_new_game()
	if started:
		menu_ui.visible = false
	else:
		message_label.text = "No se pudo iniciar una partida nueva."

func _on_continue_pressed() -> void:
	var result: Dictionary = game.continue_saved_game()
	if result.get("success", false):
		menu_ui.visible = false
	else:
		message_label.text = "No se pudo continuar: %s" % String(result.get("error", "error"))

func _on_quit_pressed() -> void:
	get_tree().quit()

func toggle_pause_menu() -> bool:
	return game.toggle_pause_menu()

func close_pause_menu() -> bool:
	return game.close_pause_menu()

func save_current_game() -> Dictionary:
	return game.save_current_game()

func can_save_game() -> bool:
	return game.can_save_game()
