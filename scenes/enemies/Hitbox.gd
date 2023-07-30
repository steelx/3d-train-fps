extends Area3D
class_name Hitbox

signal e_hurt(damage: int, dir: Vector3)

@export var weak_spot := false
@export var critical_damage_multiplier := 2


func hurt(damage: int, dir: Vector3) -> void:
	var dmg = damage * critical_damage_multiplier if weak_spot else damage
	e_hurt.emit(dmg, dir)
