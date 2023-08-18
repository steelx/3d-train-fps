extends RigidBody3D

@export var start_move_speed := 30.0
@export var gravity := 35.0
@export var drag := 0.01
@export var velocity_retained_on_bounce := 0.8

var velocity := Vector3.ZERO
var initialized := false


func init() -> void:
	initialized = true
	velocity = -global_transform.basis.y * start_move_speed


func _physics_process(delta) -> void:
	if !initialized:
		return

	velocity += -velocity * drag + Vector3.DOWN * gravity * delta
	var collision = move_and_collide(velocity * delta)
	if collision:
		# dir is direction of movement, n is normal of collision you hit
		# r is the bounce reflection
		var dir = velocity
		var n = collision.get_normal()
		var r = dir - 2 * dir.dot(n) * n
		velocity = r * velocity_retained_on_bounce
