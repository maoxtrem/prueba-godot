
extends Node2D

enum GameState {
	PLAYING,
	GAME_OVER,
	RESTART,
}

var game_state: GameState = GameState.PLAYING

# ==========================================
# REFERENCIAS
# ==========================================

@onready var player = $Player
@onready var wave_manager: WaveManager = $WaveManager
@onready var hud: GameHUD = $HUD


# ==========================================
# INICIALIZACION
# ==========================================

func _ready() -> void:
	player.health.died.connect(_on_player_died)
	hud.restart_requested.connect(_on_restart_requested)

	# Conectar eventos de las oleadas
	wave_manager.wave_started.connect(
		hud.update_wave
	)

	# Conectar enemigos restantes
	wave_manager.enemy_count_changed.connect(
		hud.update_enemies
	)

	# Conectar eliminaciones totales
	wave_manager.enemy_killed.connect(
		hud.update_kills
	)

	# Conectar cambios de vida del jugador
	player.health.health_changed.connect(
		hud.update_health
	)

	# ======================================
	# SINCRONIZAR ESTADO INICIAL
	# ======================================

	hud.update_wave(
		wave_manager.current_wave,
		wave_manager.remaining_enemies
	)

	hud.update_enemies(
		wave_manager.remaining_enemies
	)

	hud.update_kills(
		wave_manager.total_kills
	)

	hud.update_health(
		player.health.current_health,
		player.health.max_health
	)


func _on_player_died() -> void:
	if game_state != GameState.PLAYING:
		return

	game_state = GameState.GAME_OVER
	wave_manager.stop_waves()
	get_tree().call_group(&"enemigos", &"detener")
	hud.show_game_over()


func _on_restart_requested() -> void:
	if game_state != GameState.GAME_OVER:
		return

	game_state = GameState.RESTART
	get_tree().reload_current_scene()
