extends Resource
class_name ItemData

enum ItemType {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	MATERIAL,
	SPECIAL,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export_range(1, 999999, 1) var max_stack: int = 1
@export var weapon_stats: WeaponStats
@export var consumable_data: ConsumableData
@export var armor_stats: ArmorStats
