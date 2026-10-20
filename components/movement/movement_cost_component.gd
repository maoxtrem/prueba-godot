
extends Node
class_name MovementCostComponent

@export var costo_por_pixel: float = 0.01
@export var multiplicador_movimiento: float = 1.0

@export var health: HealthComponent

var distancia_total: float = 0.0


func procesar_movimiento(distancia: float) -> void:
	if health == null or health.is_dead:
		return

	if distancia <= 0.0:
		return

	distancia_total += distancia

	var costo: float = (
		distancia
		* costo_por_pixel
		* maxf(multiplicador_movimiento, 0.0)
	)

	health.drain_health(costo)
