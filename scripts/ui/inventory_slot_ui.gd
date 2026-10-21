extends Button
class_name InventorySlotUI

signal slot_selected(slot_ui: InventorySlotUI)

@onready var item_texture: TextureRect = $ItemTexture
@onready var item_marker: Label = $ItemMarker
@onready var quantity_label: Label = $Quantity

var inventory_slot: InventorySlot
var slot_index: int = -1


func _ready() -> void:
	pressed.connect(_on_pressed)
	focus_mode = Control.FOCUS_ALL
	set_empty()


func set_slot(slot: InventorySlot, index: int) -> void:
	inventory_slot = slot
	slot_index = index

	if slot == null or slot.item == null or slot.quantity <= 0:
		set_empty()
		return

	item_texture.texture = slot.item.icon
	item_texture.visible = slot.item.icon != null
	item_marker.visible = slot.item.icon == null
	item_marker.text = "◆"
	quantity_label.text = str(slot.quantity) if slot.quantity > 1 else ""


func set_empty() -> void:
	inventory_slot = null
	item_texture.texture = null
	item_texture.visible = false
	item_marker.visible = false
	quantity_label.text = ""


func set_selected(selected: bool) -> void:
	if selected:
		modulate = Color(1.0, 1.0, 0.65, 1.0)
	else:
		modulate = Color.WHITE


func _on_pressed() -> void:
	slot_selected.emit(self)
