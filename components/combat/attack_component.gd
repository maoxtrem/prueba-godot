
extends Node
class_name AttackComponent

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")

@export var dano: float = 10.0
@export var alcance: float = 150.0
@export var costo_vida: float = 3.0
@export var tiempo_recarga: float = 0.4

@export var health: HealthComponent

var tiempo_restante: float = 0.0

var dano_efectivo: float
var alcance_efectivo: float
var costo_vida_efectivo: float
var tiempo_recarga_efectivo: float
var multiplicador_dano_mejoras: float = 1.0
var multiplicador_alcance_mejoras: float = 1.0
var multiplicador_dano_consumible: float = 1.0
var multiplicador_dano_arma: float = 1.0
var estadisticas_arma: WeaponStats
var arma_instance: WeaponInstance
var ammo_manager: AmmoManager
var game_manager: GameManager

signal weapon_durability_changed(instance: WeaponInstance, current: float, maximum: float)
signal weapon_broken(instance: WeaponInstance)


func _ready() -> void:
	_recalcular_estadisticas()


func aplicar_estadisticas_arma(stats: WeaponStats) -> void:
	estadisticas_arma = stats
	arma_instance = null
	multiplicador_dano_arma = 1.0
	_recalcular_estadisticas()

func aplicar_instancia_arma(instance: WeaponInstance) -> void:
	if arma_instance != null and arma_instance.durability_changed.is_connected(_on_weapon_durability_changed):
		arma_instance.durability_changed.disconnect(_on_weapon_durability_changed)
	arma_instance = instance
	if arma_instance != null and not arma_instance.durability_changed.is_connected(_on_weapon_durability_changed):
		arma_instance.durability_changed.connect(_on_weapon_durability_changed)
	var stats: WeaponStats = null if instance == null else instance.item.weapon_stats
	estadisticas_arma = stats
	multiplicador_dano_arma = 1.0 if instance == null else instance.damage_multiplier()
	_recalcular_estadisticas()

func configure_ranged(ammo: AmmoManager, manager: GameManager = null) -> void:
	ammo_manager = ammo
	game_manager = manager

func is_ranged_weapon() -> bool:
	return estadisticas_arma != null and estadisticas_arma.is_valid() and estadisticas_arma.combat_type == WeaponStats.CombatType.RANGED and arma_instance != null


func aplicar_multiplicadores_mejoras(multiplicador_dano: float, multiplicador_alcance: float) -> void:
	multiplicador_dano_mejoras = maxf(multiplicador_dano, 0.0)
	multiplicador_alcance_mejoras = maxf(multiplicador_alcance, 0.0)
	_recalcular_estadisticas()


func aplicar_multiplicador_consumible(multiplicador: float) -> void:
	multiplicador_dano_consumible = maxf(multiplicador, 0.0)
	_recalcular_estadisticas()


func _recalcular_estadisticas() -> void:
	var dano_base := dano
	var alcance_base := alcance
	if estadisticas_arma != null and estadisticas_arma.is_valid():
		dano_base = estadisticas_arma.damage
		alcance_base = estadisticas_arma.attack_range
		costo_vida_efectivo = estadisticas_arma.get_health_cost()
		tiempo_recarga_efectivo = estadisticas_arma.cooldown
	else:
		costo_vida_efectivo = costo_vida
		tiempo_recarga_efectivo = tiempo_recarga
	dano_efectivo = dano_base * multiplicador_dano_arma * multiplicador_dano_mejoras * multiplicador_dano_consumible
	alcance_efectivo = alcance_base * multiplicador_alcance_mejoras


func _process(delta: float) -> void:
	tiempo_restante = maxf(
		tiempo_restante - delta,
		0.0
	)


func atacar(
	origen: Node2D,
	grupo_objetivo: StringName
) -> bool:
	if health == null or health.is_dead:
		return false
	if is_ranged_weapon():
		return false
	if arma_instance != null and arma_instance.is_broken():
		weapon_broken.emit(arma_instance)
		return false

	if tiempo_restante > 0.0:
		return false

	var objetivo: Node2D = null
	var distancia_minima: float = alcance_efectivo

	for nodo in get_tree().get_nodes_in_group(grupo_objetivo):
		if not nodo is Node2D:
			continue

		if not is_instance_valid(nodo):
			continue

		if nodo == origen:
			continue

		if not nodo.has_method("recibir_dano"):
			continue

		var distancia := origen.global_position.distance_to(
			nodo.global_position
		)

		if distancia <= distancia_minima:
			distancia_minima = distancia
			objetivo = nodo

	# La durabilidad solo se valida cuando existe un impacto real.
	if objetivo != null and arma_instance != null and not arma_instance.can_spend_durability():
		weapon_broken.emit(arma_instance)
		return false

	# Si el costo es cero, el ataque es gratuito.
	if costo_vida_efectivo > 0.0:
		if not health.spend_health(costo_vida_efectivo):
			return false

	tiempo_restante = tiempo_recarga_efectivo

	if objetivo != null:
		var atacante := get_parent()
		var es_ataque_de_enemigo := atacante != null and atacante.is_in_group("enemigos")
		if es_ataque_de_enemigo and objetivo.has_method("recibir_dano_de_enemigo"):
			objetivo.recibir_dano_de_enemigo(dano_efectivo)
		else:
			objetivo.recibir_dano(dano_efectivo)
		if arma_instance != null and not arma_instance.consume_durability():
			return false

	return true

func disparar(origen: Node2D, direccion: Vector2) -> bool:
	if health == null or health.is_dead or not is_ranged_weapon():
		return false
	if game_manager != null and not game_manager.is_playing():
		return false
	if tiempo_restante > 0.0 or arma_instance.is_broken():
		if arma_instance.is_broken():
			weapon_broken.emit(arma_instance)
		return false
	if direccion.length_squared() <= 0.000001:
		return false
	var stats := estadisticas_arma
	var ammo_id := stats.get_ammo_item_id()
	var ammo_cost := stats.get_ammo_per_attack()
	if ammo_manager == null or not stats.uses_ammo() or ammo_id.is_empty() or ammo_cost <= 0 or not ammo_manager.has_ammo(ammo_id, ammo_cost):
		return false
	if not _can_pay_health(costo_vida_efectivo):
		return false
	if not arma_instance.can_spend_durability():
		weapon_broken.emit(arma_instance)
		return false
	var projectile := PROJECTILE_SCENE.instantiate() as CombatProjectile
	if projectile == null or not projectile.setup(direccion, stats.projectile_speed, alcance_efectivo, dano_efectivo, origen, &"enemigos", arma_instance if arma_instance.has_durability() else null):
		return false
	var ammo_result := ammo_manager.consume_ammo(ammo_id, ammo_cost)
	if not ammo_result.success:
		projectile.queue_free()
		return false
	if costo_vida_efectivo > 0.0 and not health.spend_health(costo_vida_efectivo):
		ammo_manager.refund_ammo(ammo_id, ammo_cost)
		projectile.queue_free()
		return false
	var parent := get_tree().current_scene if get_tree().current_scene != null else get_parent()
	parent.add_child(projectile)
	projectile.global_position = origen.global_position
	tiempo_restante = tiempo_recarga_efectivo
	return true

func _can_pay_health(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if health.debug_player_context and health.debug_settings != null and health.debug_settings.has_infinite_health():
		return true
	return health.current_health > amount

func _on_weapon_durability_changed(instance: WeaponInstance, current: float, maximum: float) -> void:
	weapon_durability_changed.emit(instance, current, maximum)
	if is_zero_approx(current) and maximum > 0.0:
		weapon_broken.emit(instance)
