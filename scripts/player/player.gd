
extends CharacterBody2D

const WORLD_BOUNDS = preload("res://systems/world/world_bounds.gd")

@export var velocidad: float = 200.0
@export var costo_por_pixel: float = 0.01
@export var world_bounds: Rect2 = WORLD_BOUNDS.RECT

@onready var health: HealthComponent = $HealthComponent
@onready var barra_vida: ProgressBar = $LifeBars
@onready var costo_movimiento: MovementCostComponent = $MovementCostComponent
@onready var componente_ataque: AttackComponent = $AttackComponent
@onready var equipamiento: EquipmentComponent = $EquipmentComponent
@onready var inventario: InventoryComponent = $InventoryComponent
@onready var municion: AmmoManager = $AmmoManager
var velocidad_efectiva: float
var debug_settings: DebugSettings
var multiplicador_velocidad_mejoras: float = 1.0
var debug_ranged_granted: bool = false
var debug_capacity_potions_granted: bool = false

func _ready() -> void:
	velocidad_efectiva = velocidad
	health.health_changed.connect(actualizar_barra_vida)
	health.died.connect(morir)
	equipamiento.equipment_changed.connect(_on_equipment_changed)
	equipamiento.weapon_instance_changed.connect(_on_weapon_instance_changed)
	componente_ataque.aplicar_estadisticas_arma(null)
	componente_ataque.configure_ranged(municion, get_node_or_null("../GameManager") as GameManager)

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
	global_position = WORLD_BOUNDS.clamp_position(global_position)

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
			if event.keycode == KEY_SPACE and not componente_ataque.is_ranged_weapon():
				atacar()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if componente_ataque.is_ranged_weapon():
			disparar_hacia(get_global_mouse_position())


func atacar() -> void:
	componente_ataque.atacar(self, &"enemigos")

func disparar_hacia(posicion_mundo: Vector2) -> void:
	componente_ataque.disparar(self, global_position.direction_to(posicion_mundo))


func aplicar_velocidad_efectiva(valor: float) -> void:
	multiplicador_velocidad_mejoras = maxf(valor / velocidad, 0.0) if velocidad > 0.0 else 0.0
	_recalcular_velocidad()


func configure_debug(settings: DebugSettings) -> void:
	debug_settings = settings
	health.configure_debug(settings, true)
	if settings != null and settings.debug_enabled and settings.grant_test_ranged_weapons and not debug_ranged_granted:
		var crossbow: ItemData = load("res://resources/items/weapon_crossbow.tres")
		var pistol: ItemData = load("res://resources/items/weapon_pistol.tres")
		var bolts: ItemData = load("res://resources/items/crossbow_bolt.tres")
		var bullets: ItemData = load("res://resources/items/pistol_ammo.tres")
		inventario.add_item(crossbow, 1)
		inventario.add_item(pistol, 1)
		inventario.add_item(bolts, 20)
		inventario.add_item(bullets, 20)
		debug_ranged_granted = true
	if settings != null and settings.debug_enabled and settings.grant_test_capacity_potions and not debug_capacity_potions_granted:
		var capacity_potion: ItemData = load("res://resources/items/vital_capacity_potion.tres")
		inventario.add_item(capacity_potion, 10)
		debug_capacity_potions_granted = true


func recibir_dano(cantidad: float) -> void:
	health.take_damage(cantidad)


func recibir_dano_de_enemigo(cantidad: float) -> void:
	var multiplicador := 1.0
	if debug_settings != null:
		multiplicador = debug_settings.get_enemy_damage_multiplier()
	multiplicador *= equipamiento.get_enemy_damage_multiplier()
	health.take_damage(cantidad * multiplicador)


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

	if _slot == EquipmentComponent.EquipmentSlot.WEAPON:
		componente_ataque.aplicar_instancia_arma(equipamiento.get_equipped_weapon_instance())
	costo_movimiento.aplicar_multiplicador_armadura(equipamiento.get_armor_movement_cost_multiplier())
	_recalcular_velocidad()

func _recalcular_velocidad() -> void:
	velocidad_efectiva = maxf(velocidad * multiplicador_velocidad_mejoras * equipamiento.get_armor_speed_multiplier(), 0.0)

func _on_weapon_instance_changed(instance: WeaponInstance) -> void:
	componente_ataque.aplicar_instancia_arma(instance)
