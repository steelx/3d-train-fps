extends Node3D

var hit_effect := preload("res://scenes/effects/bullet_hit_effect.tscn")

@export var distance := 10000

var bodies_to_exclude := []
var damage := 1


func set_damage(dmg: int) -> void:
	damage = dmg


func set_bodies_to_exclude(bodies: Array) -> void:
	bodies_to_exclude = bodies


func fire() -> void:
	var from := global_transform.origin
	var to := from - global_transform.basis.z * distance
	# Player is on Layer value 2 & 4 & 1 value for WorldEnvironment
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 + 2 + 4, bodies_to_exclude)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.collider.has_method("hurt"):
		result.collider.hurt(damage, result.normal)
	elif result:
		var effect = hit_effect.instantiate()
		effect.global_transform.origin = result.position
		get_tree().get_root().add_child(effect)
		if result.normal.angle_to(Vector3.UP) < 0.008:
			return
		# Rotate effect
		if result.normal.angle_to(Vector3.DOWN) < 0.008:
			# effect.rotate_object_local(Vector3.RIGHT, PI)
			effect.rotate(Vector3.RIGHT, PI)
			return
		print_debug("fire: " + str(result.normal))
		var y: Vector3 = result.normal
		var x: Vector3 = y.cross(Vector3.UP)
		var z: Vector3 = x.cross(y)
		effect.global_transform.basis = Basis(x, y, z)
