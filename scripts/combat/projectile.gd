extends Area2D
class_name CombatProjectile

var direction := Vector2.RIGHT
var speed: float = 0.0
var max_range: float = 0.0
var damage: float = 0.0
var traveled: float = 0.0
var attacker: Node
var target_group: StringName = &"enemigos"
var durability_instance: WeaponInstance
var hit_targets: Dictionary = {}

func setup(
	start_direction: Vector2,
	projectile_speed: float,
	projectile_range: float,
	projectile_damage: float,
	projectile_attacker: Node,
	projectile_target_group: StringName,
	instance: WeaponInstance = null
) -> bool:
	if start_direction.length_squared() <= 0.000001 or projectile_speed <= 0.0 or projectile_range <= 0.0:
		return false
	direction = start_direction.normalized()
	speed = projectile_speed
	max_range = projectile_range
	damage = maxf(projectile_damage, 0.0)
	attacker = projectile_attacker
	target_group = projectile_target_group
	durability_instance = instance
	return true

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + step)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.exclude = [self, attacker]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var target = hit.get("collider")
		if target != null and target.is_in_group(target_group) and target.has_method("recibir_dano") and not hit_targets.has(target):
			hit_targets[target] = true
			target.recibir_dano(damage)
			if durability_instance != null:
				durability_instance.consume_durability()
			queue_free()
			return
	global_position += step
	traveled += step.length()
	if traveled >= max_range:
		queue_free()
