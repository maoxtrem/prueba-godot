extends Node
class_name NoiseManager

const NOISE_EVENT = preload("res://systems/audio/noise_event.gd")

signal noise_emitted(event)

var enemy_container: Node2D
var game_manager: GameManager
var debug_settings: DebugSettings
var _next_event_id: int = 1

func setup(enemies: Node2D, manager: GameManager, settings: DebugSettings = null) -> void:
	enemy_container = enemies
	game_manager = manager
	debug_settings = settings

func emit_noise(origin: Vector2, radius: float, source: Node = null, cause: StringName = &"unknown"):
	if radius <= 0.0 or not _can_process_noise():
		return null
	var source_id := source.get_instance_id() if is_instance_valid(source) else 0
	var event = NOISE_EVENT.new(_next_event_id, origin, radius, source_id, cause)
	_next_event_id += 1
	noise_emitted.emit(event)
	var affected := 0
	if is_instance_valid(enemy_container):
		for node in enemy_container.get_children():
			if not is_instance_valid(node) or not node.has_method("hear_noise"):
				continue
			if node.hear_noise(event):
				affected += 1
	if debug_settings != null and debug_settings.debug_enabled:
		print("[DEBUG NOISE] id=", event.event_id, " causa=", event.cause, " origen=", event.origin, " radio=", event.radius, " afectados=", affected)
	return event

func _can_process_noise() -> bool:
	return game_manager == null or game_manager.is_playing()
