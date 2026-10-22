
extends Node
class_name WaveManager

const WORLD_BOUNDS = preload("res://systems/world/world_bounds.gd")

# ==========================================
# SEÑALES
# ==========================================

signal wave_started(wave: int, enemies: int)
signal wave_completed(wave: int)
signal enemy_count_changed(remaining: int)
signal enemy_killed(total_kills: int)


# ==========================================
# CONFIGURACIÓN
# ==========================================

@export var enemy_scene: PackedScene
@export var initial_enemies: int = 3
@export var enemies_per_wave: int = 2
@export var spawn_radius: float = 650.0
@export var minimum_spawn_distance: float = 250.0
@export var maximum_spawn_distance: float = 650.0
@export_range(1, 128, 1) var spawn_attempts: int = 32
@export var debug_settings: DebugSettings


# ==========================================
# REFERENCIAS
# ==========================================

@onready var player: Node2D = $"../Player"
@onready var enemy_container: Node2D = $"../EnemyContainer"


# ==========================================
# ESTADO DE LAS OLEADAS
# ==========================================

var current_wave: int = 0
var remaining_enemies: int = 0
var total_kills: int = 0
var wave_active: bool = false
var waves_enabled: bool = true
var deferred_start_token: int = 0
var next_wave_pending: bool = false


# ==========================================
# INICIALIZACIÓN
# ==========================================

func _ready() -> void:
	var token := deferred_start_token
	call_deferred("_start_deferred", token)


func configure_debug(settings: DebugSettings) -> void:
	debug_settings = settings


func _start_deferred(token: int) -> void:
	if token != deferred_start_token:
		return
	start_next_wave()


func stop_waves() -> void:
	wave_active = false
	waves_enabled = false
	next_wave_pending = false
	deferred_start_token += 1


# ==========================================
# INICIAR OLEADA
# ==========================================

func start_next_wave() -> void:
	if not waves_enabled or wave_active:
		return
	if current_wave > 0 and not next_wave_pending:
		return

	var game_manager := get_parent().get_node_or_null("GameManager")
	if game_manager != null and not game_manager.can_process_waves():
		next_wave_pending = true
		return

	if enemy_scene == null:
		push_error("WaveManager: falta asignar enemy_scene")
		return

	next_wave_pending = false

	current_wave += 1
	wave_active = true

	var amount: int = (
		initial_enemies
		+ (current_wave - 1) * enemies_per_wave
	)

	remaining_enemies = amount

	wave_started.emit(current_wave, amount)
	enemy_count_changed.emit(remaining_enemies)

	print(
		"Oleada ", current_wave,
		": ", amount, " enemigos"
	)

	for i in range(amount):
		spawn_enemy()
	_debug_spawn_summary()


# ==========================================
# GENERAR ENEMIGO
# ==========================================

func spawn_enemy() -> void:
	if not waves_enabled:
		return

	var game_manager := get_parent().get_node_or_null("GameManager")
	if game_manager != null and not game_manager.can_process_waves():
		return

	var enemy := enemy_scene.instantiate() as Enemy

	if enemy == null:
		push_error(
            "La escena debe tener Enemy como nodo raiz"
		)
		return

	enemy.enemy_died.connect(on_enemy_died)

	enemy_container.add_child(enemy)
	enemy.jugador = player
	enemy.wave_manager = self
	var spawn_position := _find_spawn_position()
	enemy.global_position = spawn_position
	enemy.set_spawn_position(spawn_position)


func _find_spawn_position() -> Vector2:
	var area := WORLD_BOUNDS.playable_rect()
	var minimum_distance := maxf(minimum_spawn_distance, 0.0)
	var maximum_distance := maxf(maximum_spawn_distance, minimum_distance)
	var existing := enemy_container.get_children()
	for _attempt in range(maxi(spawn_attempts, 1)):
		var distance := randf_range(minimum_distance, maximum_distance)
		var candidate := player.global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * distance
		if not area.has_point(candidate):
			continue
		if _overlaps_existing(candidate, existing):
			continue
		return candidate

	# Alternativa determinista para bordes o escenarios muy ocupados. Se prueban
	# direcciones y distancias válidas antes de aceptar una posición recortada.
	for distance_value in [maximum_distance, (minimum_distance + maximum_distance) * 0.5, minimum_distance]:
		var distance: float = float(distance_value)
		for index in range(16):
			var candidate: Vector2 = player.global_position + Vector2.RIGHT.rotated(TAU * float(index) / 16.0) * distance
			if area.has_point(candidate) and not _overlaps_existing(candidate, existing):
				return candidate

	# El mapa actual siempre permite el anillo configurado, pero conservar una
	# alternativa segura para configuraciones futuras o escenarios saturados.
	var fallback := WORLD_BOUNDS.clamp_position(player.global_position + Vector2.RIGHT * minimum_distance)
	return fallback if not _overlaps_existing(fallback, existing) else WORLD_BOUNDS.clamp_position(player.global_position + Vector2.DOWN * minimum_distance)


func _debug_spawn_summary() -> void:
	if debug_settings == null or not debug_settings.debug_enabled:
		return
	var nearest_distance := INF
	var alive := 0
	for node in enemy_container.get_children():
		if not is_instance_valid(node) or not node is Enemy:
			continue
		var enemy := node as Enemy
		if enemy.health.is_dead:
			continue
		alive += 1
		nearest_distance = minf(nearest_distance, player.global_position.distance_to(enemy.global_position))
		print("[DEBUG SPAWN] enemigo=", enemy.global_position, " distancia=", snappedf(player.global_position.distance_to(enemy.global_position), 0.01))
	print("[DEBUG SPAWN] vivos=", alive, " mas_cercano=", snappedf(nearest_distance, 0.01))


func _overlaps_existing(candidate: Vector2, existing: Array[Node]) -> bool:
	for node in existing:
		if is_instance_valid(node) and node is Node2D and candidate.distance_to(node.global_position) < 96.0:
			return true
	return false


func alert_nearby(source: Enemy, last_known_position: Vector2) -> void:
	var game_manager := get_parent().get_node_or_null("GameManager")
	if source == null or (game_manager != null and not game_manager.can_process_waves()):
		return
	var candidates: Array[Dictionary] = []
	for node in enemy_container.get_children():
		if node == source or not is_instance_valid(node) or not node is Enemy:
			continue
		var enemy := node as Enemy
		if enemy.health.is_dead or enemy.ai_state == Enemy.AIState.CHASE:
			continue
		var distance := source.global_position.distance_to(enemy.global_position)
		if distance <= source.alert_radius:
			candidates.append({"enemy": enemy, "distance": distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return a.distance < b.distance)
	for index in range(mini(source.max_alerted_companions, candidates.size())):
		(candidates[index]["enemy"] as Enemy).receive_alert(last_known_position)


func resume_pending_wave() -> void:
	start_pending_wave()

func start_pending_wave() -> bool:
	if not next_wave_pending:
		return false
	var previous_wave := current_wave
	start_next_wave()
	return wave_active and current_wave == previous_wave + 1

func restore_statistics(wave: int, kills: int) -> bool:
	if wave < 0 or kills < 0: return false
	current_wave = wave
	total_kills = kills
	remaining_enemies = 0
	wave_active = false
	next_wave_pending = wave > 0
	return true


# ==========================================
# ENEMIGO ELIMINADO
# ==========================================

func on_enemy_died(_enemy: Node2D) -> void:
	var game_manager := get_parent().get_node_or_null("GameManager")
	if not wave_active or not waves_enabled:
		return
	if game_manager != null and not game_manager.can_process_waves():
		return

	# Incrementar eliminaciones totales
	total_kills += 1

	# Notificar al HUD
	enemy_killed.emit(total_kills)

	# Reducir enemigos restantes
	remaining_enemies = maxi(
		remaining_enemies - 1,
		0
	)

	enemy_count_changed.emit(remaining_enemies)

	print(
		"Enemigo eliminado. Total: ",
		total_kills
	)

	# Comprobar si la oleada termino
	if remaining_enemies == 0:
		complete_wave()


# ==========================================
# COMPLETAR OLEADA
# ==========================================

func complete_wave() -> void:
	if not wave_active or not waves_enabled:
		return

	wave_active = false

	wave_completed.emit(current_wave)
	next_wave_pending = true

	print(
		"Oleada ", current_wave,
        " completada"
	)
