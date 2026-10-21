extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const SWORD := preload("res://resources/items/test_weapon.tres")
const DAGGER := preload("res://resources/items/test_vital_dagger.tres")
const MATERIAL := preload("res://resources/items/test_material.tres")

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	var inventory: InventoryComponent = player.get_node("InventoryComponent")
	var equipment: EquipmentComponent = player.get_node("EquipmentComponent")
	var repairs := WeaponRepairManager.new()
	root.add_child(repairs)
	repairs.setup(inventory, equipment)

	inventory.add_item(SWORD, 1)
	inventory.add_item(MATERIAL, 2)
	var sword: WeaponInstance = inventory.get_slots()[0].weapon_instance
	sword.current_durability = 40.0
	var quote := repairs.get_quote(sword)
	_check(quote.success and is_equal_approx(quote.restored, 20.0) and quote.cost == 2, "calcular reparación parcial proporcional")
	_check(repairs.repair_weapon(sword.instance_id).success, "reparar parcialmente el arma almacenada")
	_check(is_equal_approx(sword.current_durability, 60.0) and inventory.get_item_quantity("blood_fragment") == 0, "aplicar reparación y descontar fragmentos exactos")
	_check(sword.instance_id.begins_with("weapon_"), "conservar instance_id")

	inventory.add_item(MATERIAL, 6)
	var full_quote := repairs.get_quote(sword)
	_check(full_quote.cost == 2 and is_equal_approx(full_quote.restored, 20.0), "calcular costo restante sin sobrecobro")
	_check(repairs.repair_weapon(sword.instance_id).success and is_equal_approx(sword.current_durability, 80.0), "completar reparación")
	_check(inventory.get_item_quantity("blood_fragment") == 4, "consumir solo el costo de reparación completa")
	_check(not repairs.can_repair(sword), "rechazar arma intacta")

	inventory.add_item(DAGGER, 1)
	inventory.add_item(MATERIAL, 10)
	var dagger: WeaponInstance = null
	for slot in inventory.get_slots():
		if slot.weapon_instance != null and slot.item.id == "vital_dagger":
			dagger = slot.weapon_instance
	_check(dagger != null, "encontrar instancia de daga")
	dagger.upgrade_level = 2
	dagger.current_durability = 0.0
	_check(repairs.repair_weapon(dagger.instance_id).success, "reparar arma rota")
	_check(is_equal_approx(dagger.current_durability, 100.0) and dagger.upgrade_level == 2, "restaurar capacidad y conservar nivel")

	_check(equipment.equip_item("rusty_sword", sword.instance_id).success, "equipar arma reparable")
	sword.current_durability = 20.0
	inventory.add_item(MATERIAL, 6)
	var equipped_before := sword.current_durability
	var equipped_result := repairs.repair_weapon(sword.instance_id)
	_check(equipped_result.success and sword.current_durability > equipped_before, "reparar arma equipada")

	var invalid := WeaponInstance.new(MATERIAL)
	_check(not repairs.repair_weapon(invalid.instance_id).success, "rechazar objeto sin durabilidad")

	var before_fail := sword.current_durability
	var material_before_fail := inventory.get_item_quantity("blood_fragment")
	sword.current_durability = 0.0
	inventory.remove_item("blood_fragment", material_before_fail)
	_check(not repairs.repair_weapon(sword.instance_id).success, "rechazar fragmentos insuficientes")
	_check(is_equal_approx(sword.current_durability, 0.0) and inventory.get_item_quantity("blood_fragment") == 0, "no alterar estado al fallar")

	var blocked_manager := GameManager.new()
	root.add_child(blocked_manager)
	blocked_manager.current_state = GameManager.GameState.GAME_OVER
	var blocked_instance := WeaponInstance.new(DAGGER)
	blocked_instance.current_durability = 0.0
	inventory.add_item(MATERIAL, 10)
	var blocked_material := inventory.get_item_quantity("blood_fragment")
	repairs.game_manager = blocked_manager
	_check(not repairs.repair_weapon(blocked_instance.instance_id).success, "bloquear reparación en GAME_OVER")
	_check(inventory.get_item_quantity("blood_fragment") == blocked_material, "no consumir materiales en GAME_OVER")

	print("Weapon repair tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
