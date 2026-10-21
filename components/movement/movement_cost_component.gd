
extends Node
class_name MovementCostComponent

@export var costo_por_pixel: float = 0.01
@export var multiplicador_movimiento: float = 1.0

@export var health: HealthComponent

var distancia_total: float = 0.0
var multiplicador_movimiento_base: float
var multiplicador_movimiento_efectivo: float
var multiplicador_mejoras: float = 1.0
var multiplicador_consumible: float = 1.0
var multiplicador_armadura: float = 1.0


func _ready() -> void:
	multiplicador_movimiento_base = multiplicador_movimiento
	multiplicador_movimiento_efectivo = multiplicador_movimiento


func aplicar_multiplicador_efectivo(valor: float) -> void:
	multiplicador_mejoras = maxf(valor / multiplicador_movimiento_base, 0.0) if multiplicador_movimiento_base > 0.0 else 0.0
	_recalcular_multiplicador()


func aplicar_multiplicador_consumible(valor: float) -> void:
	multiplicador_consumible = maxf(valor, 0.0)
	_recalcular_multiplicador()

func aplicar_multiplicador_armadura(valor: float) -> void:
	multiplicador_armadura = maxf(valor, 0.0)
	_recalcular_multiplicador()


func _recalcular_multiplicador() -> void:
	multiplicador_movimiento_efectivo = maxf(multiplicador_movimiento_base * multiplicador_mejoras * multiplicador_consumible * multiplicador_armadura, 0.0)


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
