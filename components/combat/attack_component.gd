
extends Node
class_name AttackComponent

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


func _ready() -> void:
	_recalcular_estadisticas(null)


func aplicar_estadisticas_arma(stats: WeaponStats) -> void:
	_recalcular_estadisticas(stats)


func _recalcular_estadisticas(stats: WeaponStats) -> void:
	if stats == null or not stats.is_valid():
		dano_efectivo = dano
		alcance_efectivo = alcance
		costo_vida_efectivo = costo_vida
		tiempo_recarga_efectivo = tiempo_recarga
		return

	dano_efectivo = stats.damage
	alcance_efectivo = stats.attack_range
	costo_vida_efectivo = stats.health_cost
	tiempo_recarga_efectivo = stats.cooldown


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

	# Si el costo es cero, el ataque es gratuito.
	if costo_vida_efectivo > 0.0:
		if not health.spend_health(costo_vida_efectivo):
			return false

	tiempo_restante = tiempo_recarga_efectivo

	if objetivo != null:
		objetivo.recibir_dano(dano_efectivo)

	return true
