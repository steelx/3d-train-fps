extends RigidBody3D

var explosion := preload("res://scenes/effects/Explosion.tscn")

const speed = 15
const impact_damage = 20
var exploded := false


func _ready() -> void:
	hide()


func _physics_process(delta: float) -> void:
	var direction := -global_transform.basis.z
	var motion_vector := direction * speed * delta
	var collision := move_and_collide(motion_vector)
	if collision:
		if collision.has_method("hurt"):
			collision.hurt(impact_damage, direction)
		explode()


func explode() -> void:
	if exploded:
		return
	exploded = true
	var explosion_instance = explosion.instantiate()
	explosion_instance.global_transform = global_transform
	get_tree().get_root().add_child(explosion_instance)
	explosion_instance.explode()
	queue_free()


func set_bodies_to_exclude(bodies: Array) -> void:
	for body in bodies:
		add_collision_exception_with(body)
