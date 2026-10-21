extends Control
class_name UpgradeShop

signal close_requested

@onready var health_label: Label = $Panel/Margin/VBox/Header/HealthLabel
@onready var message_label: Label = $Panel/Margin/VBox/Message
@onready var close_button: Button = $Panel/Margin/VBox/Footer/CloseButton

var upgrade_manager: UpgradeManager
var health: HealthComponent
var cards: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(_on_close_pressed)
	for index in range(4):
		var card := $Panel/Margin/VBox/Upgrades/CardList.get_child(index)
		cards.append({
			"panel": card,
			"name": card.get_node("Margin/Content/Name"),
			"description": card.get_node("Margin/Content/Description"),
			"level": card.get_node("Margin/Content/Level"),
			"cost": card.get_node("Margin/Content/Cost"),
			"button": card.get_node("Margin/Content/BuyButton"),
		})
		cards[index].button.pressed.connect(_on_buy_pressed.bind(index))
	visible = false

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_upgrade_shop"):
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	if visible and current_scene.has_method("close_upgrade_shop"):
		current_scene.close_upgrade_shop()
	elif not visible and current_scene.has_method("open_upgrade_shop"):
		current_scene.open_upgrade_shop()
	get_viewport().set_input_as_handled()

func set_sources(manager: UpgradeManager, health_component: HealthComponent) -> void:
	if upgrade_manager != null:
		if upgrade_manager.upgrades_changed.is_connected(_refresh):
			upgrade_manager.upgrades_changed.disconnect(_refresh)
	if health != null and health.health_changed.is_connected(_on_health_changed):
		health.health_changed.disconnect(_on_health_changed)
	upgrade_manager = manager
	health = health_component
	if upgrade_manager != null:
		upgrade_manager.upgrades_changed.connect(_refresh)
	if health != null:
		health.health_changed.connect(_on_health_changed)
	_refresh()

func show_shop() -> void:
	if upgrade_manager == null or health == null or health.is_dead:
		return
	_refresh()
	visible = true
	close_button.grab_focus()

func hide_shop() -> void:
	visible = false

func _refresh() -> void:
	if health != null:
		health_label.text = "Vida disponible: %.1f / %.1f HP" % [health.current_health, health.max_health]
	for index in range(cards.size()):
		var data: UpgradeData = null
		if upgrade_manager != null and index < upgrade_manager.available_upgrades.size():
			data = upgrade_manager.available_upgrades[index]
		var card: Dictionary = cards[index]
		card.panel.visible = data != null
		if data == null:
			continue
		var level := upgrade_manager.get_upgrade_level(data.id)
		card.name.text = data.display_name
		card.description.text = data.description
		card.level.text = "Nivel: %d / %d" % [level, data.max_level]
		card.cost.text = "Costo: %.1f HP" % data.health_cost
		var can_buy := not health.is_dead and level < data.max_level and health.current_health > data.health_cost
		card.button.disabled = not can_buy
		card.button.text = "Comprar" if can_buy else ("Máximo" if level >= data.max_level else "No disponible")

func _on_health_changed(_current: float, _maximum: float) -> void:
	_refresh()

func _on_buy_pressed(index: int) -> void:
	if upgrade_manager == null or index >= upgrade_manager.available_upgrades.size():
		return
	var data: UpgradeData = upgrade_manager.available_upgrades[index]
	if not upgrade_manager.purchase_upgrade(data.id):
		message_label.text = "No se puede comprar: vida insuficiente o nivel máximo."
		return
	message_label.text = "Mejora adquirida: %s" % data.display_name
	_refresh()

func _on_close_pressed() -> void:
	close_requested.emit()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("close_upgrade_shop"):
		current_scene.close_upgrade_shop()
