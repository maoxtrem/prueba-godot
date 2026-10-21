extends Control
class_name MainMenu

const GAME_SCENE := preload("res://scenes/main.tscn")

@onready var menu_ui: Control = $MenuUI
@onready var continue_button: Button = $MenuUI/Center/MenuPanel/Margin/VBox/ContinueButton
@onready var message_label: Label = $MenuUI/Center/MenuPanel/Margin/VBox/Message

var game: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# No instanciar Main aquí: F5 debe mostrar únicamente el menú.
	continue_button.disabled = not _has_save()

func _on_new_game_pressed() -> void:
	var started := _create_game_and_start()
	if started:
		menu_ui.visible = false
	else:
		message_label.text = "No se pudo iniciar una partida nueva."

func _on_continue_pressed() -> void:
	var result := _create_game_and_continue()
	if result.get("success", false):
		menu_ui.visible = false
	else:
		message_label.text = "No se pudo continuar: %s" % String(result.get("error", "error"))

func _on_quit_pressed() -> void:
	get_tree().quit()

func toggle_pause_menu() -> bool:
	return game != null and game.toggle_pause_menu()

func close_pause_menu() -> bool:
	return game != null and game.close_pause_menu()

func save_current_game() -> Dictionary:
	if game == null: return {"success": false, "error": "no_active_game"}
	return game.save_current_game()

func can_save_game() -> bool:
	return game != null and game.can_save_game()

func continue_between_waves() -> bool:
	return game != null and game.continue_between_waves()

func _has_save() -> bool:
	var repository := JsonSaveRepository.new()
	var serializer := SaveSerializer.new()
	var slot := "slot1"
	if not repository.has_data(slot):
		return false
	var loaded := repository.load_data(slot)
	return loaded.success and serializer.validate(loaded.data).success

func _create_game() -> Node:
	if game != null and is_instance_valid(game):
		return game
	game = GAME_SCENE.instantiate()
	game.start_in_menu = true
	add_child(game)
	return game

func _create_game_and_start() -> bool:
	var created_game := _create_game()
	return created_game.start_new_game()

func _create_game_and_continue() -> Dictionary:
	var created_game := _create_game()
	return created_game.continue_saved_game()
