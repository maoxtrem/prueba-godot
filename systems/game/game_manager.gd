extends Node
class_name GameManager

enum GameState {
	READY,
	PLAYING,
	PAUSED,
	UPGRADE_SELECTION,
	GAME_OVER,
}

signal state_changed(previous_state: GameState, new_state: GameState)
signal game_over_reached(wave: int, total_kills: int)
signal upgrade_selection_started(wave: int)
signal restart_requested

var current_state: GameState = GameState.READY
var player_health: HealthComponent
var wave_manager: WaveManager


func setup(health: HealthComponent, waves: WaveManager) -> void:
	player_health = health
	wave_manager = waves
	if player_health != null and not player_health.died.is_connected(_on_player_died):
		player_health.died.connect(_on_player_died)


func start_game() -> bool:
	if current_state != GameState.READY:
		return false

	_change_state(GameState.PLAYING)
	return true


func pause_game() -> bool:
	if current_state != GameState.PLAYING:
		return false

	_change_state(GameState.PAUSED)
	get_tree().paused = true
	return true


func resume_game() -> bool:
	if current_state != GameState.PAUSED:
		return false

	_change_state(GameState.PLAYING)
	get_tree().paused = false
	return true


func enter_upgrade_selection() -> bool:
	if current_state != GameState.PLAYING:
		return false

	_change_state(GameState.UPGRADE_SELECTION)
	get_tree().paused = true
	upgrade_selection_started.emit(wave_manager.current_wave if wave_manager != null else 0)
	return true


func continue_after_upgrades() -> bool:
	if current_state != GameState.UPGRADE_SELECTION:
		return false

	_change_state(GameState.PLAYING)
	get_tree().paused = false
	if wave_manager != null:
		wave_manager.resume_pending_wave()
	return true


func enter_game_over() -> bool:
	if current_state == GameState.GAME_OVER:
		return false

	_change_state(GameState.GAME_OVER)
	if wave_manager != null:
		wave_manager.stop_waves()
	get_tree().call_group(&"enemigos", &"detener")

	var wave := 0
	var kills := 0
	if wave_manager != null:
		wave = wave_manager.current_wave
		kills = wave_manager.total_kills

	game_over_reached.emit(wave, kills)
	get_tree().paused = true
	return true


func request_restart() -> bool:
	if current_state != GameState.GAME_OVER:
		return false

	get_tree().paused = false
	restart_requested.emit()
	return true


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER


func can_process_waves() -> bool:
	return current_state == GameState.PLAYING


func can_receive_rewards() -> bool:
	return current_state == GameState.PLAYING


func _on_player_died() -> void:
	enter_game_over()


func _change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	var previous_state := current_state
	current_state = new_state
	state_changed.emit(previous_state, new_state)
