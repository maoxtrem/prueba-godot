
extends Node
class_name WaveManager

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
@export var spawn_radius: float = 450.0


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


# ==========================================
# INICIALIZACIÓN
# ==========================================

func _ready() -> void:
	var token := deferred_start_token
	call_deferred("_start_deferred", token)


func _start_deferred(token: int) -> void:
	if token != deferred_start_token:
		return
	start_next_wave()


func stop_waves() -> void:
	wave_active = false
	waves_enabled = false
	deferred_start_token += 1


# ==========================================
# INICIAR OLEADA
# ==========================================

func start_next_wave() -> void:
	if not waves_enabled or wave_active:
		return

	var game_manager := get_parent().get_node_or_null("GameManager")
	if game_manager != null and not game_manager.can_process_waves():
		return

	if enemy_scene == null:
		push_error("WaveManager: falta asignar enemy_scene")
		return

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

	# Posicion aleatoria alrededor del jugador
	var angle := randf_range(0.0, TAU)

	var offset := (
		Vector2.RIGHT.rotated(angle) * spawn_radius
	)

	enemy.global_position = (
		player.global_position + offset
	)


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

	print(
		"Oleada ", current_wave,
        " completada"
	)
