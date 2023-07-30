extends Area3D

var bodies_to_exclude := []
var damage := 30


func set_damage(dmg: int) -> void:
	damage = dmg


func set_bodies_to_exclude(bodies: Array) -> void:
	bodies_to_exclude = bodies


func fire() -> void:
	var bodies := get_overlapping_bodies()
	var hitboxes := get_overlapping_areas()
	for body in bodies:
		if body.has_method("hurt") and !bodies_to_exclude.has(body):
			body.hurt(
				damage, self.global_transform.origin.direction_to(body.global_transform.origin)
			)
	for hitbox in hitboxes:
		if hitbox.has_method("hurt") and !bodies_to_exclude.has(hitbox):
			hitbox.hurt(
				damage, self.global_transform.origin.direction_to(hitbox.global_transform.origin)
			)
