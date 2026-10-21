extends Node
class_name AmmoManager

signal ammo_purchased(item: ItemData, quantity: int, health_cost: float)
signal purchase_failed(reason: String)

@export var packages: Dictionary = {
	"crossbow_bolt": {"quantity": 10, "health_cost": 5.0},
	"pistol_ammo": {"quantity": 20, "health_cost": 12.0},
	"special_ammo": {"quantity": 5, "health_cost": 15.0},
}
@export var ammo_items: Array[ItemData] = [
	preload("res://resources/items/crossbow_bolt.tres"),
	preload("res://resources/items/pistol_ammo.tres"),
	preload("res://resources/items/special_ammo.tres"),
]

var inventory: InventoryComponent
var health: HealthComponent
var game_manager: GameManager

func setup(inventory_component: InventoryComponent, health_component: HealthComponent, game_manager_node: GameManager = null) -> void:
	inventory = inventory_component
	health = health_component
	game_manager = game_manager_node

func get_available(item_id: String) -> int:
	return inventory.get_item_quantity(item_id) if inventory != null else 0

func has_ammo(item_id: String, quantity: int) -> bool:
	return quantity > 0 and get_available(item_id) >= quantity

func consume_ammo(item_id: String, quantity: int) -> Dictionary:
	if item_id.strip_edges().is_empty() or quantity <= 0:
		return {"success": false, "removed": 0, "reason": "invalid_ammo_request"}
	if not has_ammo(item_id, quantity):
		return {"success": false, "removed": 0, "reason": "insufficient_ammo"}
	var result := inventory.remove_item(item_id, quantity)
	if not result.success or int(result.removed) != quantity:
		return {"success": false, "removed": int(result.get("removed", 0)), "reason": "ammo_transaction_failed"}
	return {"success": true, "removed": quantity}

func refund_ammo(item_id: String, quantity: int) -> bool:
	var item := _find_ammo(item_id)
	return item != null and inventory != null and inventory.add_item(item, quantity).success

func get_package(item_id: String) -> Dictionary:
	var item := _find_ammo(item_id)
	var package: Dictionary = packages.get(item_id, {})
	if item == null or package.is_empty():
		return {"success": false, "reason": "unknown_ammo"}
	var quantity := int(package.get("quantity", 0))
	var cost := float(package.get("health_cost", -1.0))
	if quantity <= 0 or cost < 0.0 or item.item_type != ItemData.ItemType.AMMO:
		return {"success": false, "reason": "invalid_ammo_package"}
	return {"success": true, "item": item, "quantity": quantity, "health_cost": cost, "available": get_available(item_id), "space": inventory.get_available_space(item) if inventory != null else 0}

func can_buy(item_id: String) -> bool:
	var quote := get_package(item_id)
	return quote.success and not _blocked() and quote.space >= int(quote.quantity) and health != null and _can_pay(float(quote.health_cost))

func buy_ammo(item_id: String) -> Dictionary:
	if _blocked():
		return _failure("game_over")
	var quote := get_package(item_id)
	if not quote.success:
		return _failure(String(quote.reason))
	if inventory == null or health == null:
		return _failure("missing_dependency")
	if int(quote.space) < int(quote.quantity):
		return _failure("inventory_full")
	if not health.spend_health(float(quote.health_cost)):
		return _failure("insufficient_health")
	var added := inventory.add_item(quote.item, int(quote.quantity))
	if not added.success or int(added.added) != int(quote.quantity):
		# El espacio se valida antes; esta rama protege contra cambios inesperados.
		inventory.remove_item(quote.item.id, int(added.get("added", 0)))
		health.heal(float(quote.health_cost))
		return _failure("inventory_transaction_failed")
	ammo_purchased.emit(quote.item, int(quote.quantity), float(quote.health_cost))
	return {"success": true, "item": quote.item, "quantity": int(quote.quantity), "health_cost": float(quote.health_cost)}

func _find_ammo(item_id: String) -> ItemData:
	for item in ammo_items:
		if item != null and item.id == item_id:
			return item
	return null

func _blocked() -> bool:
	if game_manager != null and game_manager.is_game_over():
		return true
	return health != null and health.is_dead

func _can_pay(cost: float) -> bool:
	if health == null:
		return false
	if health.debug_player_context and health.debug_settings != null and health.debug_settings.has_infinite_health():
		return true
	return health.current_health > cost

func _failure(reason: String) -> Dictionary:
	purchase_failed.emit(reason)
	return {"success": false, "reason": reason}
