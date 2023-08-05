extends RigidBody3D

const speed = 15
const impact_damage = 20
var exploded := false
var collided := false


func _ready() -> void:
	hide()


func _physics_process(delta: float) -> void:
	var direction := -global_transform.basis.z
	var motion_vector := direction * speed * delta
	var collision := move_and_collide(motion_vector)
	if collision:
		$SmokeParticle.emitting = true
		$Sprite3D.hide()
		self.freeze = true
		var collider = collision.get_collider()
		if collider.has_method("hurt") and !collided:
			collided = true
			collider.hurt(impact_damage, direction)


# gets called from DestroyAfterHitTimer
func explode() -> void:
	if exploded:
		return
	exploded = true
	queue_free()


func set_bodies_to_exclude(bodies: Array) -> void:
	for body in bodies:
		add_collision_exception_with(body)
