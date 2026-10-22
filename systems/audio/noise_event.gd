extends RefCounted
class_name NoiseEvent

var event_id: int
var origin: Vector2
var radius: float
var source_id: int
var cause: StringName

func _init(id: int, position: Vector2, propagation_radius: float, emitter_id: int, noise_cause: StringName) -> void:
	event_id = id
	origin = position
	radius = maxf(propagation_radius, 0.0)
	source_id = emitter_id
	cause = noise_cause
