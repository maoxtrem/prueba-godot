
extends Node
class_name RewardComponent

signal recompensa_entregada(cantidad: float)

@export var recompensa_vida: float = 20.0

var recompensa_procesada: bool = false


func entregar_recompensa(jugador: Node) -> void:
	if recompensa_procesada:
		return

	if not is_instance_valid(jugador):
		return

	if not jugador.has_method("recuperar_vida"):
		return

	recompensa_procesada = true

	jugador.recuperar_vida(recompensa_vida)
	recompensa_entregada.emit(recompensa_vida)
