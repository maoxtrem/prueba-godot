extends Control
class_name InventoryUI

@onready var inventory_window: PanelContainer = $InventoryWindow
@onready var grid: GridContainer = $InventoryWindow/Margin/VBox/SlotGrid
@onready var occupied_label: Label = $InventoryWindow/Margin/VBox/Header/OccupiedLabel
@onready var close_button: Button = $InventoryWindow/Margin/VBox/Header/CloseButton
@onready var weapon_icon: TextureRect = $InventoryWindow/Margin/VBox/EquipmentPanel/EquipmentMargin/EquipmentRow/WeaponIcon
@onready var weapon_marker: Label = $InventoryWindow/Margin/VBox/EquipmentPanel/EquipmentMargin/EquipmentRow/WeaponMarker
@onready var weapon_name: Label = $InventoryWindow/Margin/VBox/EquipmentPanel/EquipmentMargin/EquipmentRow/WeaponName
@onready var equip_button: Button = $InventoryWindow/Margin/VBox/EquipmentPanel/EquipmentMargin/EquipmentRow/EquipButton
@onready var unequip_button: Button = $InventoryWindow/Margin/VBox/EquipmentPanel/EquipmentMargin/EquipmentRow/UnequipButton
@onready var selected_name: Label = $InventoryWindow/Margin/VBox/Description/DescriptionMargin/DescriptionVBox/Name
@onready var selected_description: Label = $InventoryWindow/Margin/VBox/Description/DescriptionMargin/DescriptionVBox/Details

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/inventory_slot_ui.tscn")
const SLOT_COUNT: int = 20

var inventory: InventoryComponent
var equipment: EquipmentComponent
var slot_buttons: Array[InventorySlotUI] = []
var visible_slots: Array[InventorySlot] = []
var selected_index: int = -1
var was_paused_before_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	close_button.pressed.connect(close_inventory)
	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
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


func _clear_description() -> void:
	selected_name.text = "Selecciona un objeto"
	selected_description.text = "Aquí aparecerán sus detalles."
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
			_weapon_stats_text(equipped),
		]

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
