extends Area3D

var bodies_to_exclude := []
var damage := 30


func set_damage(dmg: int) -> void:
	damage = dmg


func set_bodies_to_exclude(bodies: Array) -> void:
	bodies_to_exclude = bodies


func fire() -> void:
	for body in get_overlapping_bodies():
		if body.has_method("hurt") and !bodies_to_exclude.has(body):
			body.hurt(damage)
