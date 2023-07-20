extends Node3D
class_name WeaponManager

signal e_machete_body_entered(body: Node3D)

enum WeaponSlots { MACHETE, MACHINE_GUN, SHOTGUN, ROCKET_LAUNCHER }
@export var slots_available := {
	WeaponSlots.MACHETE: true,
	WeaponSlots.MACHINE_GUN: true,
	WeaponSlots.SHOTGUN: true,
	WeaponSlots.ROCKET_LAUNCHER: true
}

@onready var weapons = $Weapons.get_children()
var current_weapon: Node3D = null:
	set(value):
		current_weapon = value
		if current_weapon != null:
			if current_weapon.has_method("set_active"):
				current_weapon.set_active()
			else:
				current_weapon.show()

var current_slot := WeaponSlots.MACHETE


func _ready() -> void:
	# Set the machete as the current weapon
	current_weapon = $Weapons/Machete


func switch_to_next_weapon() -> void:
	# Get the next weapon slot
	var next_slot := current_slot + 1
	if next_slot > WeaponSlots.ROCKET_LAUNCHER:
		next_slot = WeaponSlots.MACHETE

	# If the next slot is available, switch to it
	if slots_available[next_slot]:
		switch_to_weapon_slot(next_slot)


func switch_to_weapon_slot(slot_index: WeaponSlots) -> void:
	if (
		slot_index == current_slot
		or slot_index < WeaponSlots.MACHETE
		or slot_index > WeaponSlots.ROCKET_LAUNCHER
		or not slots_available[slot_index]
	):
		return
	# Hide the current weapon
	disable_all_weapons()

	# Show the new weapon
	current_slot = slot_index
	current_weapon = weapons[slot_index]


func disable_all_weapons() -> void:
	for weapon in weapons:
		if weapon.has_method("set_inactive"):
			weapon.set_inactive()
		else:
			weapon.hide()


func get_direction() -> Vector3:
	# returns direction from camera
	var viewport := get_viewport()
	var camera := viewport.get_camera_3d()
	var center: Vector2 = viewport.size / 2
	var from: Vector3 = camera.project_ray_origin(center)
	var to: Vector3 = from + camera.project_ray_normal(center) * 1000
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var collision = get_world_3d().direct_space_state.intersect_ray(query)
	if collision:
		return global_position.direction_to(collision.position)
	else:
		return global_position.direction_to(to)


func _on_machete_body_entered(body: Node3D) -> void:
	e_machete_body_entered.emit(body)
