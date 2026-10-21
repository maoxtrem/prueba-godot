extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var sword: ItemData = load("res://resources/items/test_weapon.tres")
	var dagger: ItemData = load("res://resources/items/test_vital_dagger.tres")
	var spear: ItemData = load("res://resources/items/test_crimson_spear.tres")
	_check(sword.weapon_stats.combat_type == WeaponStats.CombatType.MELEE_SHORT, "clasificar espada como cuerpo a cuerpo corto")
	_check(dagger.weapon_stats.combat_type == WeaponStats.CombatType.MELEE_SHORT, "clasificar daga como cuerpo a cuerpo corto")
	_check(spear.weapon_stats.combat_type == WeaponStats.CombatType.MELEE_LONG, "clasificar lanza como cuerpo a cuerpo largo")

	var ranged := WeaponStats.new()
	ranged.combat_type = WeaponStats.CombatType.RANGED
	ranged.damage = 10.0
	ranged.attack_range = 300.0
	_check(ranged.combat_type == WeaponStats.CombatType.RANGED, "admitir tipo a distancia configurable")

	var health_only := WeaponCostConfig.new()
	health_only.health_cost = 3.0
	var health_stats := _stats_with_cost(health_only, 0.0)
	_check(health_stats.is_valid() and is_equal_approx(health_stats.get_health_cost(), 3.0), "configurar costo únicamente de HP")

	var durability_only := WeaponCostConfig.new()
	durability_only.durability_cost = 1.0
	durability_only.uses_durability = true
	var durability_stats := _stats_with_cost(durability_only, 20.0)
	_check(durability_stats.is_valid() and durability_stats.uses_durability(), "configurar costo únicamente de durabilidad")

	var ammo_only := WeaponCostConfig.new()
	ammo_only.ammo_item_id = "crossbow_bolt"
	ammo_only.ammo_per_attack = 1
	ammo_only.uses_ammo = true
	var ammo_stats := _stats_with_cost(ammo_only, 0.0)
	_check(ammo_stats.is_valid() and ammo_stats.get_ammo_item_id() == "crossbow_bolt", "configurar costo únicamente de munición")

	var combined := WeaponCostConfig.new()
	combined.health_cost = 2.0
	combined.durability_cost = 1.0
	combined.uses_durability = true
	combined.ammo_item_id = "special_ammo"
	combined.ammo_per_attack = 2
	combined.uses_ammo = true
	var combined_stats := _stats_with_cost(combined, 30.0)
	_check(combined_stats.is_valid() and is_equal_approx(combined_stats.get_health_cost(), 2.0), "combinar HP, durabilidad y munición")

	var free_config := WeaponCostConfig.new()
	var free_stats := _stats_with_cost(free_config, 0.0)
	_check(free_stats.is_valid() and is_equal_approx(free_stats.get_health_cost(), 0.0), "admitir arma sin costos")

	var negative := WeaponCostConfig.new()
	negative.health_cost = -1.0
	_check(not negative.is_valid(), "rechazar costo de HP negativo")
	negative.health_cost = 0.0
	negative.durability_cost = -1.0
	_check(not negative.is_valid(), "rechazar costo de durabilidad negativo")

	var missing_ammo := WeaponCostConfig.new()
	missing_ammo.uses_ammo = true
	_check(not missing_ammo.is_valid(), "rechazar munición sin ID ni cantidad")
	var contradictory_ammo := WeaponCostConfig.new()
	contradictory_ammo.ammo_item_id = "crossbow_bolt"
	_check(not contradictory_ammo.is_valid(), "rechazar ID de munición sin activar munición")

	var contradictory_durability := WeaponCostConfig.new()
	contradictory_durability.durability_cost = 1.0
	_check(not contradictory_durability.is_valid(), "rechazar durabilidad con flag desactivado")
	var invalid_durability := WeaponCostConfig.new()
	invalid_durability.durability_cost = 1.0
	invalid_durability.uses_durability = true
	_check(not _stats_with_cost(invalid_durability, 0.0).is_valid(), "rechazar durabilidad sin máximo")

	var legacy_conflict := WeaponCostConfig.new()
	legacy_conflict.health_cost = 2.0
	var conflict_stats := _stats_with_cost(legacy_conflict, 5.0)
	conflict_stats.health_cost = 1.0
	_check(not conflict_stats.is_valid(), "rechazar dos fuentes de costo de HP")

	_check(sword.weapon_stats.damage == 18.0 and sword.weapon_stats.attack_range == 100.0 and sword.weapon_stats.cooldown == 0.6, "conservar estadísticas de espada")
	_check(dagger.weapon_stats.damage == 8.0 and dagger.weapon_stats.attack_range == 75.0 and dagger.weapon_stats.cooldown == 0.25, "conservar estadísticas de daga")
	_check(spear.weapon_stats.damage == 25.0 and spear.weapon_stats.attack_range == 180.0 and spear.weapon_stats.cooldown == 0.9, "conservar estadísticas de lanza")

	var instance := WeaponInstance.new(sword)
	instance.upgrade_level = 2
	_check(instance.current_durability == -1.0 and instance.instance_id.begins_with("weapon_"), "preparar durabilidad sin desgaste funcional")
	var serialized_instance := {"instance_id": instance.instance_id, "upgrade_level": instance.upgrade_level}
	_check(serialized_instance.size() == 2 and serialized_instance.upgrade_level == 2, "mantener contrato de guardado de instancia")
	_check(sword.weapon_stats.get_health_cost() == sword.weapon_stats.health_cost, "mantener costo HP legacy sin configuración")

	print("Weapon config tests: ", checks, " comprobaciones correctas")
	quit()

func _stats_with_cost(config: WeaponCostConfig, max_durability: float) -> WeaponStats:
	var stats := WeaponStats.new()
	stats.damage = 10.0
	stats.attack_range = 100.0
	stats.cooldown = 0.5
	stats.max_durability = max_durability
	stats.cost_config = config
	return stats

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
