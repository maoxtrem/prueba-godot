
extends Node
class_name MovementCostComponent

@export var costo_por_pixel: float = 0.01
@export var multiplicador_movimiento: float = 1.0

@export var health: HealthComponent

var distancia_total: float = 0.0
var multiplicador_movimiento_base: float
var multiplicador_movimiento_efectivo: float


func _ready() -> void:
	multiplicador_movimiento_base = multiplicador_movimiento
	multiplicador_movimiento_efectivo = multiplicador_movimiento


func aplicar_multiplicador_efectivo(valor: float) -> void:
	multiplicador_movimiento_efectivo = maxf(valor, 0.0)


func procesar_movimiento(distancia: float) -> void:
	if health == null or health.is_dead:
		return

	if distancia <= 0.0:
		return

	distancia_total += distancia

	var costo: float = (
		distancia
		* costo_por_pixel
		* multiplicador_movimiento_efectivo
	)

	health.drain_health(costo)
