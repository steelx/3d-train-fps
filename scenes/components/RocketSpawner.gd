extends Node3D

var rocket := preload("res://scenes/components/weapons/Rocket.tscn")

var bodies_to_exclude := []
var damage := 1


func set_damage(dmg: int) -> void:
	damage = dmg


func set_bodies_to_exclude(bodies: Array) -> void:
	bodies_to_exclude = bodies


func fire() -> void:
	var rocket_instance := rocket.instantiate()
	rocket_instance.set_bodies_to_exclude(bodies_to_exclude)
	get_tree().get_root().add_child(rocket_instance)
	rocket_instance.global_transform = global_transform
