extends CharacterBody2D
class_name Enemy

signal enemy_died(enemy: Node2D)
signal ai_state_changed(previous: AIState, current: AIState, reason: String)

enum AIState { IDLE, CHASE, INVESTIGATE, SEARCH, RETURN }
const WORLD_BOUNDS = preload("res://systems/world/world_bounds.gd")

@export var velocidad: float = 100.0
@export var detection_radius: float = 180.0
@export var lose_target_radius: float = 320.0
@export var search_duration: float = 4.0
@export var investigate_duration: float = 4.0
@export var noise_arrival_distance: float = 25.0
@export var alert_radius: float = 220.0
@export_range(1, 16, 1) var max_alerted_companions: int = 2
@export var debug_ai: bool = false
@export var pixeles_por_paso: float = 20.0
@export var pasos_para_regenerar: int = 3
@export var vida_por_regeneracion: float = 2.0

@onready var health: HealthComponent = $HealthComponent
@onready var barra_vida: ProgressBar = $LifeBar
@onready var etiqueta_vida: Label = $HealthLabel
@onready var regeneracion: RegenerationComponent = $RegenerationComponent
@onready var recompensa: RewardComponent = $RewardComponent
@onready var ataque: AttackComponent = $AttackComponent

var jugador: CharacterBody2D
var distancia_acumulada: float = 0.0
var ai_state: AIState = AIState.IDLE
var activation_reason: String = "spawn"
var origin_position: Vector2
var last_known_player_position: Vector2
var search_elapsed: float = 0.0
var investigate_elapsed: float = 0.0
var investigation_position: Vector2
var alert_sent: bool = false
var wave_manager: WaveManager

func _ready() -> void:
	health.health_changed.connect(actualizar_barra)
	health.died.connect(morir)
	actualizar_barra(health.current_health, health.max_health)
	origin_position = global_position
	last_known_player_position = origin_position

func _physics_process(delta: float) -> void:
	if health.is_dead or not is_instance_valid(jugador): return
	if not _game_is_playing():
		velocity = Vector2.ZERO
		return
	var distance_to_player := global_position.distance_to(jugador.global_position)
	if distance_to_player <= detection_radius and ai_state != AIState.CHASE:
		_enter_chase("direct_detection")
	match ai_state:
		AIState.IDLE: velocity = Vector2.ZERO
		AIState.CHASE: _process_chase(distance_to_player)
		AIState.INVESTIGATE: _process_investigate(delta, distance_to_player)
		AIState.SEARCH: _process_search(delta, distance_to_player)
		AIState.RETURN: _process_return(distance_to_player)

func _process_chase(distance_to_player: float) -> void:
	if distance_to_player > lose_target_radius:
		_change_state(AIState.SEARCH, "lost_target")
		_process_search(0.0, distance_to_player)
		return
	last_known_player_position = jugador.global_position
	_move_or_attack(jugador.global_position)

func _process_search(delta: float, distance_to_player: float) -> void:
	if distance_to_player <= detection_radius:
		_enter_chase("direct_detection")
		_process_chase(distance_to_player)
		return
	search_elapsed += maxf(delta, 0.0)
	if search_elapsed >= search_duration or global_position.distance_to(last_known_player_position) <= 8.0:
		_change_state(AIState.RETURN, "search_finished")
		_process_return(distance_to_player)
		return
	_move_to(last_known_player_position)

func _process_investigate(delta: float, distance_to_player: float) -> void:
	if distance_to_player <= detection_radius:
		_enter_chase("direct_detection")
		_process_chase(distance_to_player)
		return
	investigate_elapsed += maxf(delta, 0.0)
	if investigate_elapsed >= investigate_duration or global_position.distance_to(investigation_position) <= noise_arrival_distance:
		_change_state(AIState.RETURN, "investigation_finished")
		_process_return(distance_to_player)
		return
	_move_to(investigation_position)

func _process_return(distance_to_player: float) -> void:
	if distance_to_player <= detection_radius:
		_enter_chase("direct_detection")
		_process_chase(distance_to_player)
		return
	if global_position.distance_to(origin_position) <= 8.0:
		velocity = Vector2.ZERO
		alert_sent = false
		_change_state(AIState.IDLE, "returned_home")
		return
	_move_to(origin_position)

func _move_or_attack(target: Vector2) -> void:
	if global_position.distance_to(target) <= ataque.alcance:
		velocity = Vector2.ZERO
		ataque.atacar(self, &"jugadores")
	else: _move_to(target)

func _move_to(target: Vector2) -> void:
	velocity = global_position.direction_to(target) * velocidad
	var previous := global_position
	move_and_slide()
	global_position = WORLD_BOUNDS.clamp_position(global_position)
	regeneracion.procesar_movimiento(global_position.distance_to(previous))

func recibir_dano(cantidad: float) -> void:
	health.take_damage(cantidad)
	if not health.is_dead: _enter_chase("damage_received")

func set_spawn_position(position: Vector2) -> void:
	origin_position = WORLD_BOUNDS.clamp_position(position)
	last_known_player_position = origin_position

func receive_alert(position: Vector2) -> void:
	if health.is_dead or ai_state == AIState.CHASE: return
	last_known_player_position = WORLD_BOUNDS.clamp_position(position)
	_enter_chase("companion_alert", false, false)

func hear_noise(event) -> bool:
	if event == null or health.is_dead or not _game_is_playing():
		return false
	if global_position.distance_to(event.origin) > event.radius:
		return false
	if ai_state == AIState.CHASE:
		return false
	# El primer ruido aceptado durante una investigación gana para evitar
	# oscilaciones entre destinos. SEARCH/RETURN pueden ser interrumpidos.
	if ai_state == AIState.INVESTIGATE:
		return false
	investigation_position = event.origin
	investigate_elapsed = 0.0
	_change_state(AIState.INVESTIGATE, "noise_%s" % event.cause)
	return true

func _enter_chase(reason: String, notify_companions: bool = true, update_last_known: bool = true) -> void:
	if health.is_dead or not _game_is_playing(): return
	if update_last_known and is_instance_valid(jugador):
		last_known_player_position = jugador.global_position
	_change_state(AIState.CHASE, reason)
	if notify_companions and not alert_sent and wave_manager != null:
		alert_sent = true
		wave_manager.alert_nearby(self, last_known_player_position)

func _change_state(next_state: AIState, reason: String) -> void:
	if ai_state == next_state and activation_reason == reason: return
	var previous := ai_state
	ai_state = next_state
	activation_reason = reason
	if next_state == AIState.SEARCH: search_elapsed = 0.0
	if next_state == AIState.INVESTIGATE: investigate_elapsed = 0.0
	ai_state_changed.emit(previous, next_state, reason)
	if debug_ai: print("Enemy AI: ", previous, " -> ", next_state, " (", reason, ")")

func _game_is_playing() -> bool:
	var manager := get_parent().get_parent().get_node_or_null("GameManager")
	return manager == null or manager.is_playing()

func actualizar_barra(actual: float, maxima: float) -> void:
	barra_vida.max_value = maxima
	barra_vida.value = actual
	etiqueta_vida.text = "%.0f / %.0f HP" % [actual, maxima]

func morir() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("is_game_over") or not current_scene.is_game_over(): recompensa.entregar_recompensa(jugador)
	enemy_died.emit(self)
	queue_free()

func detener() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
