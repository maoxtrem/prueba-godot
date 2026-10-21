extends Control
class_name InventoryUI

@onready var inventory_window: PanelContainer = $InventoryWindow
@onready var grid: GridContainer = $InventoryWindow/Margin/VBox/Body/LeftPanel/LeftMargin/LeftVBox/SlotGrid
@onready var occupied_label: Label = $InventoryWindow/Margin/VBox/Header/OccupiedLabel
@onready var close_button: Button = $InventoryWindow/Margin/VBox/Header/CloseButton
@onready var weapon_icon: TextureRect = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/EquipmentPanel/EquipmentMargin/EquipmentVBox/WeaponRow/WeaponIcon
@onready var weapon_marker: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/EquipmentPanel/EquipmentMargin/EquipmentVBox/WeaponRow/WeaponMarker
@onready var weapon_name: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/EquipmentPanel/EquipmentMargin/EquipmentVBox/WeaponRow/WeaponName
@onready var equip_button: Button = $InventoryWindow/Margin/VBox/ActionBar/EquipButton
@onready var unequip_button: Button = $InventoryWindow/Margin/VBox/ActionBar/UnequipButton
@onready var upgrade_equipped_button: Button = $InventoryWindow/Margin/VBox/ActionBar/UpgradeWeaponButton
@onready var armor_icon: TextureRect = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/ArmorPanel/ArmorMargin/ArmorRow/ArmorIcon
@onready var armor_marker: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/ArmorPanel/ArmorMargin/ArmorRow/ArmorMarker
@onready var armor_name: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/ArmorPanel/ArmorMargin/ArmorRow/ArmorName
@onready var equip_armor_button: Button = $InventoryWindow/Margin/VBox/ActionBar/EquipArmorButton
@onready var unequip_armor_button: Button = $InventoryWindow/Margin/VBox/ActionBar/UnequipArmorButton
@onready var selected_name: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/Description/DescriptionMargin/DescriptionVBox/Name
@onready var selected_description: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/Description/DescriptionMargin/DescriptionVBox/Details
@onready var use_button: Button = $InventoryWindow/Margin/VBox/ActionBar/UseButton
@onready var use_message: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/Description/DescriptionMargin/DescriptionVBox/UseMessage
@onready var upgrade_info: Label = $InventoryWindow/Margin/VBox/Body/RightPanel/Scroll/RightMargin/RightVBox/Description/DescriptionMargin/DescriptionVBox/UpgradeInfo
@onready var upgrade_button: Button = $InventoryWindow/Margin/VBox/ActionBar/UpgradeButton

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot_ui.tscn")
const SLOT_COUNT: int = 20

var inventory: InventoryComponent
var equipment: EquipmentComponent
var consumables: ConsumableComponent
var weapon_upgrades: WeaponUpgradeManager
var slot_buttons: Array[InventorySlotUI] = []
var visible_slots: Array[InventorySlot] = []
var selected_index: int = -1
var was_paused_before_open: bool = false


func _ready() -> void:
	# Debe recibir I durante PLAYING y también mientras el inventario pausa el árbol.
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close_inventory)
	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	upgrade_equipped_button.pressed.connect(_on_upgrade_equipped_pressed)
	equip_armor_button.pressed.connect(_on_equip_armor_pressed)
	unequip_armor_button.pressed.connect(_on_unequip_armor_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	use_button.pressed.connect(_on_use_pressed)
	visible = false

	for index in range(SLOT_COUNT):
		var slot_ui := SLOT_SCENE.instantiate() as InventorySlotUI
		slot_ui.slot_index = index
		slot_ui.slot_selected.connect(_on_slot_selected)
		grid.add_child(slot_ui)
		slot_buttons.append(slot_ui)

	_clear_description()
	_update_equipment_visual()


func set_inventory(target_inventory: InventoryComponent) -> void:
	if inventory != null and inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.disconnect(_on_inventory_changed)

	inventory = target_inventory
	if inventory != null:
		inventory.inventory_changed.connect(_on_inventory_changed)

	_refresh_inventory()


func set_equipment(target_equipment: EquipmentComponent) -> void:
	if equipment != null and equipment.equipment_changed.is_connected(_on_equipment_changed):
		equipment.equipment_changed.disconnect(_on_equipment_changed)

	equipment = target_equipment
	if equipment != null:
		equipment.equipment_changed.connect(_on_equipment_changed)

	_update_equipment_visual()

func set_consumables(target_consumables: ConsumableComponent) -> void:
	if consumables != null and consumables.consumable_used.is_connected(_on_consumable_used):
		consumables.consumable_used.disconnect(_on_consumable_used)
	if consumables != null and consumables.consumable_use_failed.is_connected(_on_consumable_failed):
		consumables.consumable_use_failed.disconnect(_on_consumable_failed)
	consumables = target_consumables
	if consumables != null:
		consumables.consumable_used.connect(_on_consumable_used)
		consumables.consumable_use_failed.connect(_on_consumable_failed)
	_update_equipment_buttons()

func set_weapon_upgrades(target_upgrades: WeaponUpgradeManager) -> void:
	if weapon_upgrades != null and weapon_upgrades.weapon_upgraded.is_connected(_on_weapon_upgraded):
		weapon_upgrades.weapon_upgraded.disconnect(_on_weapon_upgraded)
	weapon_upgrades = target_upgrades
	if weapon_upgrades != null:
		weapon_upgrades.weapon_upgraded.connect(_on_weapon_upgraded)
	_update_equipment_buttons()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if visible:
			close_inventory()
		else:
			open_inventory()
		get_viewport().set_input_as_handled()


func open_inventory() -> void:
	if _is_game_over() or inventory == null:
		return

	was_paused_before_open = get_tree().paused
	var game_manager := _get_game_manager()
	if game_manager != null:
		if not game_manager.pause_game():
			return
	else:
		get_tree().paused = true
	_refresh_inventory()
	visible = true
	if slot_buttons.size() > 0:
		slot_buttons[0].grab_focus()


func close_inventory() -> void:
	if not visible:
		return

	visible = false
	var game_manager := _get_game_manager()
	if game_manager != null:
		game_manager.resume_game()
	elif not _is_game_over():
		get_tree().paused = was_paused_before_open


func _on_inventory_changed(_slots: Array[InventorySlot]) -> void:
	_refresh_inventory()


func _on_equipment_changed(_slot: EquipmentComponent.EquipmentSlot, _item: ItemData) -> void:
	_update_equipment_visual()
	_refresh_inventory()


func _refresh_inventory() -> void:
	visible_slots.clear()
	if inventory != null:
		visible_slots = inventory.get_slots()
		occupied_label.text = "Espacios: %d / %d" % [
			visible_slots.size(),
			inventory.capacity,
		]
	else:
		occupied_label.text = "Espacios: 0 / %d" % SLOT_COUNT

	for index in range(slot_buttons.size()):
		var slot := visible_slots[index] if index < visible_slots.size() else null
		slot_buttons[index].set_slot(slot, index)
		slot_buttons[index].set_selected(index == selected_index)

	if selected_index < 0 or selected_index >= visible_slots.size():
		selected_index = -1
		_clear_description()
	else:
		_show_description(visible_slots[selected_index])
	_update_equipment_buttons()


func _on_slot_selected(slot_ui: InventorySlotUI) -> void:
	if slot_ui.inventory_slot == null:
		return

	selected_index = slot_ui.slot_index
	for button in slot_buttons:
		button.set_selected(button == slot_ui)
	_show_description(slot_ui.inventory_slot)
	_update_equipment_buttons()


func _show_description(slot: InventorySlot) -> void:
	if slot == null or slot.item == null:
		_clear_description()
		return

	selected_name.text = "%s x%d" % [slot.item.display_name, slot.quantity]
	selected_description.text = "%s\nTipo: %s\nRareza: %s\n%s" % [
		slot.item.description,
		_item_type_name(slot.item.item_type),
		_rarity_name(slot.item.rarity),
		_weapon_stats_text(slot.item),
	]
	if slot.weapon_instance != null:
		selected_description.text += "\nNivel de arma: +%d\n%s" % [slot.weapon_instance.upgrade_level, _weapon_upgrade_text(slot.weapon_instance)]
	if slot.item.consumable_data != null:
		selected_description.text += "\nEfecto configurable de consumible"
	if slot.item.armor_stats != null:
		selected_description.text += "\n%s" % _armor_stats_text(slot.item)


func _clear_description() -> void:
	selected_name.text = "Selecciona un objeto"
	selected_description.text = "Aquí aparecerán sus detalles."
	use_message.text = ""
	upgrade_info.text = ""
	_update_equipment_buttons()


func _on_equip_pressed() -> void:
	if equipment == null or selected_index < 0 or selected_index >= visible_slots.size():
		return

	var selected_slot := visible_slots[selected_index]
	if selected_slot == null or selected_slot.item == null:
		return

	var result := equipment.equip_item(selected_slot.item.id)
	if result.get("success", false):
		selected_index = -1
		_clear_description()
		_refresh_inventory()


func _on_unequip_pressed() -> void:
	if equipment == null:
		return

	var result := equipment.unequip_weapon()
	if result.get("success", false):
		selected_index = -1
		_clear_description()
		_refresh_inventory()

func _on_equip_armor_pressed() -> void:
	if equipment == null or selected_index < 0 or selected_index >= visible_slots.size():
		return
	var slot := visible_slots[selected_index]
	if slot == null or slot.item == null:
		return
	var result := equipment.equip_item(slot.item.id)
	if result.get("success", false):
		selected_index = -1
		_clear_description()
		_refresh_inventory()

func _on_unequip_armor_pressed() -> void:
	if equipment == null:
		return
	var result := equipment.unequip_armor()
	if result.get("success", false):
		selected_index = -1
		_clear_description()
		_refresh_inventory()

func _on_upgrade_pressed() -> void:
	var instance := _selected_weapon_instance()
	if weapon_upgrades == null or instance == null:
		return
	var result := weapon_upgrades.upgrade_weapon(instance.instance_id)
	if result.get("success", false):
		use_message.text = "Arma mejorada a +%d." % instance.upgrade_level
	else:
		use_message.text = "No se puede mejorar: %s" % result.get("reason", "error")
	_refresh_inventory()

func _on_upgrade_equipped_pressed() -> void:
	if weapon_upgrades == null or equipment == null or equipment.get_equipped_weapon_instance() == null:
		return
	var instance := equipment.get_equipped_weapon_instance()
	var result := weapon_upgrades.upgrade_weapon(instance.instance_id)
	if result.get("success", false):
		use_message.text = "Arma mejorada a +%d." % instance.upgrade_level
	else:
		use_message.text = "No se puede mejorar: %s" % result.get("reason", "error")
	_update_equipment_visual()

func _on_weapon_upgraded(_instance: WeaponInstance, _level: int) -> void:
	_refresh_inventory()
	_update_equipment_visual()

func _selected_weapon_instance() -> WeaponInstance:
	if selected_index < 0 or selected_index >= visible_slots.size():
		return null
	return visible_slots[selected_index].weapon_instance

func _on_use_pressed() -> void:
	if consumables == null or selected_index < 0 or selected_index >= visible_slots.size():
		return
	var slot := visible_slots[selected_index]
	if slot == null or slot.item == null:
		return
	var result := consumables.use_item(slot.item.id)
	if result.get("success", false):
		use_message.text = "Consumible usado."
	else:
		use_message.text = "No se puede usar: %s" % _reason_text(result.get("reason", "error"))
	_refresh_inventory()

func _on_consumable_used(_item: ItemData, _data: ConsumableData) -> void:
	use_message.text = "Consumible usado."

func _on_consumable_failed(_item_id: String, reason: String) -> void:
	use_message.text = "No se puede usar: %s" % _reason_text(reason)


func _update_equipment_visual() -> void:
	if equipment == null:
		weapon_icon.texture = null
		weapon_icon.visible = false
		weapon_marker.visible = false
		weapon_name.text = "Arma: ninguna"
		_update_equipment_buttons()
		return

	var equipped := equipment.get_equipped_item(EquipmentComponent.EquipmentSlot.WEAPON)
	if equipped == null:
		weapon_icon.texture = null
		weapon_icon.visible = false
		weapon_marker.visible = false
		weapon_name.text = "Arma: ninguna"
	else:
		weapon_icon.texture = equipped.icon
		weapon_icon.visible = equipped.icon != null
		weapon_marker.visible = equipped.icon == null
		weapon_marker.text = "◆"
		weapon_name.text = "Arma: %s\n%s" % [
			equipped.display_name,
			_weapon_stats_text(equipped) + ("\nNivel +%d" % equipment.get_equipped_weapon_instance().upgrade_level if equipment.get_equipped_weapon_instance() != null else ""),
		]
	var armor := equipment.get_equipped_item(EquipmentComponent.EquipmentSlot.ARMOR)
	if armor == null:
		armor_icon.texture = null
		armor_icon.visible = false
		armor_marker.visible = true
		armor_marker.text = "◇"
		armor_name.text = "Armadura: ninguna"
	else:
		armor_icon.texture = armor.icon
		armor_icon.visible = armor.icon != null
		armor_marker.visible = armor.icon == null
		armor_marker.text = "◇"
		armor_name.text = "Armadura: %s\n%s" % [armor.display_name, _armor_stats_text(armor)]

	_update_equipment_buttons()


func _update_equipment_buttons() -> void:
	var selected_is_weapon := (
		selected_index >= 0
		and selected_index < visible_slots.size()
		and visible_slots[selected_index] != null
		and visible_slots[selected_index].item != null
		and visible_slots[selected_index].item.item_type == ItemData.ItemType.WEAPON
	)
	equip_button.disabled = equipment == null or not selected_is_weapon
	unequip_button.disabled = equipment == null or equipment.get_equipped_item(EquipmentComponent.EquipmentSlot.WEAPON) == null
	upgrade_equipped_button.disabled = equipment == null or weapon_upgrades == null or equipment.get_equipped_weapon_instance() == null or not weapon_upgrades.can_upgrade(equipment.get_equipped_weapon_instance())
	var selected_is_consumable := selected_index >= 0 and selected_index < visible_slots.size() and visible_slots[selected_index] != null and visible_slots[selected_index].item != null and visible_slots[selected_index].item.item_type == ItemData.ItemType.CONSUMABLE
	use_button.disabled = consumables == null or not selected_is_consumable
	if not use_button.disabled:
		use_button.disabled = not consumables.can_use_item(visible_slots[selected_index].item.id).get("success", false)
	var selected_instance := _selected_weapon_instance()
	upgrade_button.disabled = weapon_upgrades == null or selected_instance == null or not weapon_upgrades.can_upgrade(selected_instance)
	upgrade_button.visible = selected_instance != null
	if selected_instance != null and weapon_upgrades != null:
		upgrade_info.text = _weapon_upgrade_text(selected_instance)
	var selected_is_armor := selected_index >= 0 and selected_index < visible_slots.size() and visible_slots[selected_index] != null and visible_slots[selected_index].item != null and visible_slots[selected_index].item.item_type == ItemData.ItemType.ARMOR
	equip_armor_button.disabled = equipment == null or not selected_is_armor
	unequip_armor_button.disabled = equipment == null or equipment.get_equipped_item(EquipmentComponent.EquipmentSlot.ARMOR) == null

	# La barra inferior solo muestra acciones aplicables al contexto actual.
	equip_button.visible = selected_is_weapon
	upgrade_button.visible = selected_instance != null
	use_button.visible = selected_is_consumable
	equip_armor_button.visible = selected_is_armor
	unequip_button.visible = equipment != null and equipment.get_equipped_item(EquipmentComponent.EquipmentSlot.WEAPON) != null
	upgrade_equipped_button.visible = equipment != null and equipment.get_equipped_weapon_instance() != null
	unequip_armor_button.visible = equipment != null and equipment.get_equipped_item(EquipmentComponent.EquipmentSlot.ARMOR) != null

func _reason_text(reason: String) -> String:
	var labels := {"health_full": "vida al máximo", "player_dead": "jugador muerto", "game_over": "partida terminada", "not_in_inventory": "no está en el inventario"}
	return labels.get(reason, reason)


func _item_type_name(item_type: ItemData.ItemType) -> String:
	return ItemData.ItemType.keys()[item_type].capitalize()


func _rarity_name(rarity: ItemData.Rarity) -> String:
	return ItemData.Rarity.keys()[rarity].capitalize()


func _weapon_stats_text(item: ItemData) -> String:
	if item == null or item.item_type != ItemData.ItemType.WEAPON:
		return "Estadísticas de arma: no aplican"

	if item.weapon_stats == null or not item.weapon_stats.is_valid():
		return "Estadísticas de arma: base"

	var stats := item.weapon_stats
	return "Daño: %.1f | Vida: %.1f | Alcance: %.1f | Recarga: %.2f" % [
		stats.damage,
		stats.health_cost,
		stats.attack_range,
		stats.cooldown,
	]

func _weapon_upgrade_text(instance: WeaponInstance) -> String:
	if instance == null or instance.item == null or instance.item.weapon_stats == null:
		return "Mejora no disponible"
	var current := instance.item.weapon_stats.damage * instance.damage_multiplier()
	var next := current
	var cost := 0
	if weapon_upgrades != null:
		cost = weapon_upgrades.get_next_cost(instance)
		if instance.upgrade_level < weapon_upgrades.max_level:
			next = instance.item.weapon_stats.damage * (1.0 + 0.1 * (instance.upgrade_level + 1))
	return "Daño actual: %.1f | Siguiente: %.1f | Costo: %d fragmentos" % [current, next, cost]

func _armor_stats_text(item: ItemData) -> String:
	if item == null or item.armor_stats == null:
		return "Defensa: base"
	var stats := item.armor_stats
	return "Defensa: %.0f%% | Velocidad: %+.0f%% | Costo movimiento: %+.0f%%" % [
		stats.damage_reduction * 100.0,
		stats.movement_speed_modifier * 100.0,
		stats.movement_cost_modifier * 100.0,
	]


func _is_game_over() -> bool:
	var current_scene := get_tree().current_scene
	return (
		current_scene != null
		and current_scene.has_method("is_game_over")
		and current_scene.is_game_over()
	)


func _get_game_manager() -> GameManager:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	return current_scene.get_node_or_null("GameManager") as GameManager
