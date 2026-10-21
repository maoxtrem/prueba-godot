extends SceneTree

var checks := 0
const SWORD := preload("res://resources/items/test_weapon.tres")
const ARMOR := preload("res://resources/items/reinforced_cloth.tres")
const MATERIAL := preload("res://resources/items/test_material.tres")
const AMMO := preload("res://resources/items/crossbow_bolt.tres")
const CROSSBOW := preload("res://resources/items/weapon_crossbow.tres")
const FURY := preload("res://resources/consumables/fury_elixir.tres")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_instance = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_instance)
	set_current_scene(main_instance)
	await process_frame
	main_instance.player.configure_debug(null)
	var save_manager: SaveManager = main_instance.get_node("SaveManager")
	var test_repository := JsonSaveRepository.new()
	test_repository.save_directory = "/tmp/ultimo_refugio_save_tests"
	save_manager.repository = test_repository
	var inventory: InventoryComponent = main_instance.get_node("Player/InventoryComponent")
	var equipment: EquipmentComponent = main_instance.get_node("Player/EquipmentComponent")
	var upgrades: UpgradeManager = main_instance.get_node("Player/UpgradeManager")
	var quests: QuestManager = main_instance.get_node("QuestManager")
	var waves: WaveManager = main_instance.get_node("WaveManager")
	var effects: StatusEffectComponent = main_instance.get_node("Player/StatusEffectComponent")
	inventory.clear_items()

	inventory.add_item(SWORD, 2)
	inventory.add_item(ARMOR, 1)
	inventory.add_item(MATERIAL, 12)
	var slots := inventory.get_slots()
	slots[0].weapon_instance.upgrade_level = 1
	slots[1].weapon_instance.upgrade_level = 2
	slots[0].weapon_instance.current_durability = 37.0
	_check(slots[0].weapon_instance.instance_id != slots[1].weapon_instance.instance_id, "mantener IDs de armas independientes")
	_check(equipment.equip_item("rusty_sword", slots[0].weapon_instance.instance_id).success, "preparar arma equipada")
	_check(equipment.equip_item("reinforced_cloth").success, "preparar armadura equipada")
	inventory.add_item(AMMO, 10)
	inventory.add_item(CROSSBOW, 1)
	upgrades.upgrade_levels["light_legs"] = 1
	quests.register_enemy_kill(5)
	effects.apply_effect(FURY)
	var serialized := save_manager.serializer.serialize_game(main_instance, "phase12_test")
	_check(serialized.schema_version == 1 and serialized.save_id == "phase12_test", "serializar versión e identificador")
	_check(save_manager.serializer.validate(serialized).success, "validar partida serializada")
	var legacy_serialized := serialized.duplicate(true)
	for legacy_slot in legacy_serialized.game.inventory.slots:
		if legacy_slot.has("weapon_instance"):
			legacy_slot.weapon_instance.erase("current_durability")
	legacy_serialized.game.equipment.weapon.erase("current_durability")
	_check(save_manager.serializer.validate(legacy_serialized).success, "aceptar guardado anterior sin durabilidad")
	var invalid_durability := serialized.duplicate(true)
	invalid_durability.game.equipment.weapon.current_durability = -1.0
	_check(not save_manager.serializer.validate(invalid_durability).success, "rechazar durabilidad fuera de rango")
	var saved := save_manager.save_game("phase12_test")
	_check(saved.success, "guardar JSON local")
	_check(save_manager.has_save("phase12_test"), "detectar guardado válido")
	var loaded := save_manager.load_game("phase12_test")
	_check(loaded.success, "cargar JSON local")
	if not loaded.success:
		quit()
		return
	var loaded_game: Dictionary = loaded.data.game
	_check(loaded_game.inventory.slots.size() == 4 and loaded_game.inventory.slots[0].weapon_instance.upgrade_level == 2 and loaded_game.inventory.slots[2].item_id == "crossbow_bolt" and loaded_game.inventory.slots[2].quantity == 10 and loaded_game.inventory.slots[3].item_id == "weapon_crossbow", "conservar inventario, arma ranged, nivel y munición")
	_check(loaded_game.equipment.weapon.instance_id == slots[0].weapon_instance.instance_id and loaded_game.equipment.armor_item_id == "reinforced_cloth", "conservar equipo")
	_check(is_equal_approx(float(loaded_game.equipment.weapon.current_durability), 37.0), "serializar durabilidad equipada")
	_check(int(loaded_game.upgrades.light_legs) == 1, "conservar mejoras del personaje")
	_check(int(loaded_game.quests.progress.first_kills) == 5 and loaded_game.wave.kills == waves.total_kills, "conservar misiones y estadísticas de oleada")
	_check(loaded_game.temporary_effects.size() == 1, "reservar efectos temporales")

	var restored_main = load("res://scenes/main.tscn").instantiate()
	restored_main.start_in_menu = true
	root.add_child(restored_main)
	set_current_scene(restored_main)
	await process_frame
	restored_main.player.configure_debug(null)
	restored_main.save_manager.repository = test_repository
	restored_main.save_manager.default_slot = "phase12_test"
	var continued: Dictionary = restored_main.continue_saved_game()
	_check(continued.success, "continuar partida desde el menú")
	_check(restored_main.player.health.current_health == main_instance.player.health.current_health, "restaurar vida sin consumirla")
	_check(restored_main.inventory.get_item_quantity("test_material") == inventory.get_item_quantity("test_material"), "restaurar cantidades del inventario")
	_check(restored_main.inventory.get_item_quantity("crossbow_bolt") == 10, "restaurar munición")
	_check(restored_main.inventory.get_item_quantity("weapon_crossbow") == 1, "restaurar arma ranged")
	var restored_weapon: WeaponInstance = restored_main.equipment.get_equipped_weapon_instance()
	_check(restored_weapon != null and restored_weapon.instance_id == slots[0].weapon_instance.instance_id, "restaurar arma equipada")
	_check(restored_weapon != null and is_equal_approx(restored_weapon.current_durability, 37.0), "restaurar durabilidad equipada")
	_check(restored_main.upgrades.upgrade_levels.get("light_legs", 0) == 1, "restaurar mejora comprada")
	_check(restored_main.quest_manager.progress.get("first_kills", 0) == 5, "restaurar progreso de misiones")
	_check(restored_main.player.get_node("StatusEffectComponent").has_effect("fury_elixir"), "restaurar efecto temporal")
	restored_main.queue_free()

	var missing := save_manager.load_game("slot_that_does_not_exist")
	_check(not missing.success and missing.error == "file_not_found", "manejar archivo inexistente")
	var corrupt_file := FileAccess.open("/tmp/ultimo_refugio_save_tests/save_corrupt_test.json", FileAccess.WRITE)
	corrupt_file.store_string("{not valid json")
	corrupt_file.close()
	var corrupt_repository := JsonSaveRepository.new()
	corrupt_repository.save_directory = "/tmp/ultimo_refugio_save_tests"
	var corrupt := corrupt_repository.load_data("corrupt_test")
	_check(not corrupt.success and corrupt.error == "invalid_json", "rechazar JSON corrupto")

	var wrong_version := serialized.duplicate(true)
	wrong_version.schema_version = 99
	_check(not save_manager.serializer.validate(wrong_version).success, "rechazar versión incompatible")
	var unknown_item := serialized.duplicate(true)
	unknown_item.game.inventory.slots[0].item_id = "unknown_item_id"
	_check(not save_manager.serializer.validate(unknown_item).success, "rechazar ID desconocido")
	var duplicate_instance := serialized.duplicate(true)
	var duplicate_entry: Dictionary = duplicate_instance.game.inventory.slots[0].duplicate(true)
	duplicate_instance.game.inventory.slots.append(duplicate_entry)
	_check(not save_manager.serializer.validate(duplicate_instance).success, "rechazar instancia duplicada")
	_check(not JsonSaveRepository.new().save_data("../unsafe", serialized).success, "rechazar slot inseguro")
	_check(save_manager.delete_save("phase12_test").success and not save_manager.has_save("phase12_test"), "eliminar guardado explícitamente")

	print("Save tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
