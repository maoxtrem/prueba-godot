
extends CharacterBody2D

@export var velocidad: float = 200.0
@export var costo_por_pixel: float = 0.01

@onready var health: HealthComponent = $HealthComponent
@onready var barra_vida: ProgressBar = $LifeBars
@onready var costo_movimiento: MovementCostComponent = $MovementCostComponent
@onready var componente_ataque: AttackComponent = $AttackComponent
@onready var equipamiento: EquipmentComponent = $EquipmentComponent
var velocidad_efectiva: float

func _ready() -> void:
	velocidad_efectiva = velocidad
	health.health_changed.connect(actualizar_barra_vida)
	health.died.connect(morir)
	equipamiento.equipment_changed.connect(_on_equipment_changed)
	componente_ataque.aplicar_estadisticas_arma(null)

	actualizar_barra_vida(
		health.current_health,
		health.max_health
	)


func _physics_process(_delta: float) -> void:
	if health.is_dead:
		velocity = Vector2.ZERO
		return

	var direccion := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
        "ui_down"
	)

	velocity = direccion * velocidad_efectiva

	var posicion_anterior := global_position
	move_and_slide()

	var distancia := global_position.distance_to(
		posicion_anterior
	)

	if distancia > 0.0:
		costo_movimiento.procesar_movimiento(distancia)


func _input(event: InputEvent) -> void:
	if health.is_dead:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_SPACE:
				atacar()


func atacar() -> void:
	componente_ataque.atacar(self, &"enemigos")


func aplicar_velocidad_efectiva(valor: float) -> void:
	velocidad_efectiva = maxf(valor, 0.0)


func recibir_dano(cantidad: float) -> void:
	health.take_damage(cantidad)


func recuperar_vida(cantidad: float) -> void:
	health.heal(cantidad)


func actualizar_barra_vida(
	actual: float,
	maxima: float
) -> void:
	barra_vida.max_value = maxima
	barra_vida.value = actual


func morir() -> void:
	velocity = Vector2.ZERO
	print("El jugador ha muerto")


func _on_equipment_changed(
	_slot: EquipmentComponent.EquipmentSlot,
	item: ItemData
) -> void:
	var stats: WeaponStats = null
	if item != null and item.weapon_stats != null:
		stats = item.weapon_stats

	componente_ataque.aplicar_estadisticas_arma(stats)
