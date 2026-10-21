extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	set_current_scene(menu)
	await process_frame
	_check(menu.get_node_or_null("Main") == null, "F5 no instancia la partida antes de comenzar")
	_check(menu.menu_ui.visible, "mostrar el menú principal")

	var new_game: Button = menu.get_node("MenuUI/Center/MenuPanel/Margin/VBox/NewGameButton")
	_check(new_game.visible, "mostrar Nueva partida")
	_check(menu.get_node("MenuUI/Center/MenuPanel/Margin/VBox/ContinueButton").visible, "mostrar Continuar partida")
	_check(menu.get_node("MenuUI/Center/MenuPanel/Margin/VBox/QuitButton").visible, "mostrar Salir")
	new_game.emit_signal("pressed")
	await process_frame
	var game: Node = menu.get_node("Main")
	_check(game.game_manager.current_state == GameManager.GameState.PLAYING, "F5 inicia la partida desde Nueva partida")
	_check(game.wave_manager.current_wave == 1, "F5 inicia la primera oleada")
	_check(game.get_node("EnemyContainer").get_child_count() == 3, "F5 genera tres enemigos")

	# Simular volver al menú y crear una nueva instancia de partida.
	change_scene_to_file("res://scenes/main_menu.tscn")
	await process_frame
	await process_frame
	var returned_menu: Node = current_scene
	_check(returned_menu != null and returned_menu.scene_file_path == "res://scenes/main_menu.tscn", "volver al menú carga una instancia limpia")
	_check(not paused, "volver al menú deja el árbol sin pausa")

	var second_button: Button = returned_menu.get_node("MenuUI/Center/MenuPanel/Margin/VBox/NewGameButton")
	second_button.emit_signal("pressed")
	await process_frame
	var second_game: Node = returned_menu.get_node("Main")
	_check(second_game.game_manager.current_state == GameManager.GameState.PLAYING, "la segunda Nueva partida entra en PLAYING")
	_check(second_game.wave_manager.current_wave == 1, "la segunda partida reinicia la oleada")
	_check(second_game.get_node("EnemyContainer").get_child_count() == 3, "la segunda partida genera tres enemigos")
	_check(second_game.hud.wave_label.text == "Oleada: 1", "la segunda partida sincroniza el HUD")

	print("Main menu flow tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
