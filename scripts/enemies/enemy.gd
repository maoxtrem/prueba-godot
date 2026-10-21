
extends CharacterBody2D
class_name Enemy
signal enemy_died(enemy: Node2D)
@export var velocidad: float = 100.0


# Regeneracion por desplazamiento
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


func _ready() -> void:
	health.health_changed.connect(actualizar_barra)
	health.died.connect(morir)

	actualizar_barra(
		health.current_health,
		health.max_health
	)


func _physics_process(delta: float) -> void:
	if health.is_dead or not is_instance_valid(jugador):
		return



	var distancia_jugador := global_position.distance_to(
		jugador.global_position
	)

	if distancia_jugador <= ataque.alcance:
		velocity = Vector2.ZERO
		ataque.atacar(self, &"jugadores")
	else:
		var direccion := global_position.direction_to(
			jugador.global_position
		)

		velocity = direccion * velocidad

	var posicion_anterior := global_position

	move_and_slide()

	var distancia_recorrida := global_position.distance_to(
		posicion_anterior
	)

	regeneracion.procesar_movimiento(distancia_recorrida)



func recibir_dano(cantidad: float) -> void:
	health.take_damage(cantidad)


func actualizar_barra(actual: float, maxima: float) -> void:
	barra_vida.max_value = maxima
	barra_vida.value = actual
	etiqueta_vida.text = "%.0f / %.0f HP" % [actual, maxima]


func morir() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("is_game_over") or not current_scene.is_game_over():
		recompensa.entregar_recompensa(jugador)
	enemy_died.emit(self)
	queue_free()


func detener() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
