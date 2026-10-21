extends Control
class_name UpgradeShop

signal close_requested

@onready var health_label: Label = $Panel/Margin/VBox/Header/HealthLabel
@onready var message_label: Label = $Panel/Margin/VBox/Message
@onready var close_button: Button = $Panel/Margin/VBox/Footer/CloseButton

var upgrade_manager: UpgradeManager
var ammo_manager: AmmoManager
var health: HealthComponent
var cards: Array[Dictionary] = []
var ammo_cards: Array[Dictionary] = []

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
	for index in range(3):
		var ammo_card := $Panel/Margin/VBox/Upgrades/CardList/AmmoList.get_child(index)
		ammo_cards.append({
			"panel": ammo_card,
			"name": ammo_card.get_node("Name"),
			"info": ammo_card.get_node("Info"),
			"button": ammo_card.get_node("BuyButton"),
		})
		ammo_cards[index].button.pressed.connect(_on_ammo_buy_pressed.bind(index))
	visible = false

func set_sources(manager: UpgradeManager, health_component: HealthComponent, ammo_component: AmmoManager = null) -> void:
	if upgrade_manager != null:
		if upgrade_manager.upgrades_changed.is_connected(_refresh):
			upgrade_manager.upgrades_changed.disconnect(_refresh)
	if health != null and health.health_changed.is_connected(_on_health_changed):
		health.health_changed.disconnect(_on_health_changed)
	if ammo_manager != null and ammo_manager.ammo_purchased.is_connected(_on_ammo_purchased):
		ammo_manager.ammo_purchased.disconnect(_on_ammo_purchased)
	upgrade_manager = manager
	ammo_manager = ammo_component
	health = health_component
	if upgrade_manager != null:
		upgrade_manager.upgrades_changed.connect(_refresh)
	if health != null:
		health.health_changed.connect(_on_health_changed)
	if ammo_manager != null:
		ammo_manager.ammo_purchased.connect(_on_ammo_purchased)
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
	_refresh_ammo()

func _refresh_ammo() -> void:
	var ids := ["crossbow_bolt", "pistol_ammo", "special_ammo"]
	for index in range(ammo_cards.size()):
		var card: Dictionary = ammo_cards[index]
		var quote := ammo_manager.get_package(ids[index]) if ammo_manager != null else {"success": false}
		card.panel.visible = quote.get("success", false)
		if not quote.get("success", false):
			continue
		var can_buy := ammo_manager.can_buy(ids[index])
		card.name.text = quote.item.display_name
		card.info.text = "%d unidades | %.1f HP | Disponibles: %d" % [int(quote.quantity), float(quote.health_cost), int(quote.available)]
		card.button.disabled = not can_buy
		card.button.text = "Comprar" if can_buy else ("Inventario lleno" if int(quote.space) < int(quote.quantity) else "No disponible")

func _on_health_changed(_current: float, _maximum: float) -> void:
	_refresh()

func _on_ammo_purchased(_item: ItemData, _quantity: int, _health_cost: float) -> void:
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

func _on_ammo_buy_pressed(index: int) -> void:
	if ammo_manager == null or index < 0 or index >= 3:
		return
	var ids := ["crossbow_bolt", "pistol_ammo", "special_ammo"]
	var result := ammo_manager.buy_ammo(ids[index])
	if not result.success:
		message_label.text = "No se puede comprar munición: %s" % _reason_text(result.reason)
		return
	message_label.text = "Munición adquirida: %d unidades." % int(result.quantity)
	_refresh()

func _reason_text(reason: String) -> String:
	var labels := {
		"insufficient_health": "vida insuficiente",
		"inventory_full": "espacio insuficiente",
		"game_over": "partida terminada",
	}
	return labels.get(reason, reason)

func _on_close_pressed() -> void:
	close_requested.emit()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("close_upgrade_shop"):
		current_scene.close_upgrade_shop()
