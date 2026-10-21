extends SceneTree

var checks := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var health := WeaponCostConfig.new()
	health.health_cost = 1.0
	_check(health.validate()["success"] and health.uses_health(), "aceptar costo de HP")

	var durability := WeaponCostConfig.new()
	durability.durability_cost = 2.0
	durability.uses_durability = true
	_check(durability.validate()["success"], "aceptar costo de durabilidad activado")

	var ammo := WeaponCostConfig.new()
	ammo.ammo_item_id = "blood_fragment"
	ammo.ammo_per_attack = 1
	ammo.uses_ammo = true
	_check(ammo.validate()["success"], "aceptar munición configurable")

	var combined := WeaponCostConfig.new()
	combined.health_cost = 2.0
	combined.durability_cost = 1.0
	combined.uses_durability = true
	combined.ammo_item_id = "arrow"
	combined.ammo_per_attack = 1
	combined.uses_ammo = true
	_check(combined.is_valid(), "aceptar costos combinados")

	var negative := WeaponCostConfig.new()
	negative.health_cost = -1.0
	_check(not negative.is_valid() and negative.validate()["error"] == "negative_health_cost", "rechazar HP negativo")

	var missing_durability := WeaponCostConfig.new()
	missing_durability.uses_durability = true
	_check(not missing_durability.is_valid() and missing_durability.validate()["error"] == "durability_cost_required", "exigir costo de durabilidad")

	var orphan_durability := WeaponCostConfig.new()
	orphan_durability.durability_cost = 1.0
	_check(not orphan_durability.is_valid() and orphan_durability.validate()["error"] == "durability_flag_required", "rechazar durabilidad sin flag")

	var missing_ammo := WeaponCostConfig.new()
	missing_ammo.uses_ammo = true
	_check(not missing_ammo.is_valid() and missing_ammo.validate()["error"] == "ammo_id_required", "exigir ID de munición")

	var orphan_ammo := WeaponCostConfig.new()
	orphan_ammo.ammo_per_attack = 1
	_check(not orphan_ammo.is_valid() and orphan_ammo.validate()["error"] == "ammo_flag_required", "rechazar munición sin flag")

	var unsafe_ammo := WeaponCostConfig.new()
	unsafe_ammo.ammo_item_id = "arrows/large"
	unsafe_ammo.ammo_per_attack = 1
	unsafe_ammo.uses_ammo = true
	_check(not unsafe_ammo.is_valid() and unsafe_ammo.validate()["error"] == "invalid_ammo_id", "rechazar ID de munición con ruta")

	print("Weapon cost config tests: ", checks, " comprobaciones correctas")
	quit()

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		push_error("Fallo: " + description)
