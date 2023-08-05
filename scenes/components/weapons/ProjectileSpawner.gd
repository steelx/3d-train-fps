extends Node3D

const default_projectile: PackedScene = preload(
	"res://scenes/components/weapons/FireballProjectile.tscn"
)
@export var projectile: PackedScene = null

var bodies_to_exclude := []
var damage := 1


func _ready() -> void:
	if projectile == null:
		projectile = default_projectile


func set_damage(dmg: int) -> void:
	damage = dmg


func set_bodies_to_exclude(bodies: Array) -> void:
	bodies_to_exclude = bodies


func fire() -> void:
	var projectile_instance := projectile.instantiate()
	projectile_instance.set_bodies_to_exclude(bodies_to_exclude)
	get_tree().get_root().add_child(projectile_instance)
	projectile_instance.global_transform = global_transform
