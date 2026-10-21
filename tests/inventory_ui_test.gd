extends SceneTree

var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame

	var inventory_ui = main_instance.get_node("HUD/InventoryUI")
	var inventory = main_instance.get_node("Player/InventoryComponent")
	var grid = inventory_ui.get_node("InventoryWindow/Margin/VBox/SlotGrid")
	var occupied_label = inventory_ui.get_node("InventoryWindow/Margin/VBox/Header/OccupiedLabel")
	var description_name = inventory_ui.get_node("InventoryWindow/Margin/VBox/Description/DescriptionMargin/DescriptionVBox/Name")

	_check(InputMap.has_action("toggle_inventory"), "registrar acción toggle_inventory")
	_check(inventory_ui.process_mode == Node.PROCESS_MODE_WHEN_PAUSED, "procesar UI durante pausa")
	_check(grid.get_child_count() == 20, "mostrar exactamente 20 espacios")
	_check(not inventory_ui.visible, "iniciar con inventario cerrado")

	var toggle_event := InputEventKey.new()
	toggle_event.keycode = KEY_I
	toggle_event.physical_keycode = KEY_I
	toggle_event.pressed = true
	inventory_ui._input(toggle_event)
	_check(inventory_ui.visible and paused, "abrir inventario con I y pausar")

	var material = load("res://resources/items/test_material.tres")
	inventory.add_item(material, 3)
	_check(occupied_label.text == "Espacios: 1 / 20", "actualizar contador con inventory_changed")

	var first_slot = grid.get_child(0)
	first_slot._on_pressed()
	_check(description_name.text == "Fragmento de sangre x3", "mostrar datos del objeto seleccionado")

	var close_event := InputEventKey.new()
	close_event.keycode = KEY_I
	close_event.physical_keycode = KEY_I
	close_event.pressed = true
	inventory_ui._input(close_event)
	_check(not inventory_ui.visible and not paused, "cerrar inventario con I y reanudar")

	inventory_ui.open_inventory()
	_check(inventory_ui.visible and paused, "abrir de nuevo")
	inventory_ui.close_button.emit_signal("pressed")
	_check(not inventory_ui.visible and not paused, "cerrar mediante X")

	inventory_ui.open_inventory()
	main_instance.get_node("GameManager").current_state = GameManager.GameState.GAME_OVER
	inventory_ui.close_inventory()
	_check(not inventory_ui.visible and paused, "no reanudar después de GAME_OVER")
	paused = false

	print("Inventory UI tests: ", checks, " comprobaciones correctas")
	quit()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
