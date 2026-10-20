
extends Node

class_name RegenerationComponent

@export var pixeles_por_paso: float = 20.0
@export var pasos_para_regenerar: int = 3
@export var vida_por_regeneracion: float = 2.0

@export var health: HealthComponent

var distancia_acumulada: float = 0.0


func procesar_movimiento(distancia: float) -> void:
	if health == null or health.is_dead:
		return

	if distancia <= 0.0:
		return

	if pixeles_por_paso <= 0.0:
		return

	if pasos_para_regenerar <= 0:
		return

	distancia_acumulada += distancia

	var distancia_necesaria: float = (
		pixeles_por_paso * pasos_para_regenerar
	)

	while distancia_acumulada >= distancia_necesaria:
		distancia_acumulada -= distancia_necesaria
		health.heal(vida_por_regeneracion)
