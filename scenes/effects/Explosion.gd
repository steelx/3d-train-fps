extends Area3D

@export var damage: int = 70
@onready var partcle1 := $GPUParticles3D
@onready var partcle2 := $GPUParticles3D2
@onready var collisionShape := $CollisionShape3D


func explode() -> void:
	partcle1.emitting = true
	partcle2.emitting = true
	var query := PhysicsShapeQueryParameters3D.new()
	query.set_transform(global_transform)
	query.set_shape(collisionShape.shape)
	query.collision_mask = self.collision_mask
	var results := get_world_3d().direct_space_state.intersect_shape(query)
	for result in results:
		if result.collider.has_method("hurt"):
			result.collider.hurt(
				damage,
				global_transform.origin.direction_to(result.collider.global_transform.origin)
			)
