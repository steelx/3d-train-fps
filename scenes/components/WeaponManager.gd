extends Node3D
class_name WeaponManager

enum WeaponSlots { MACHETE, MACHINE_GUN, SHOTGUN, ROCKET_LAUNCHER }
@export var slots_available := {
	WeaponSlots.MACHETE: true,
	WeaponSlots.MACHINE_GUN: true,
	WeaponSlots.SHOTGUN: true,
	WeaponSlots.ROCKET_LAUNCHER: true
}
@export var is_player: bool = true

@onready var alert_area_los: Area3D = $AlertAreaLos
@onready var alert_area_sound: Area3D = $AlertAreaHearing
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var weapons = $Weapons.get_children()

signal e_current_weapon(name: String, ammo: int)

var current_weapon: Node3D = null:
	set(value):
		current_weapon = value
		if current_weapon != null:
			e_current_weapon.emit(current_weapon.name, current_weapon.ammo)
			if current_weapon.has_method("set_active"):
				current_weapon.set_active()
			else:
				current_weapon.show()

var current_slot := WeaponSlots.MACHETE
var fire_point: Node3D
var bodies_to_exclude: Array = []


func init(_fire_point: Node3D, _bodies_to_exclude: Array) -> void:
	self.fire_point = _fire_point
	self.bodies_to_exclude = _bodies_to_exclude
	for weapon in weapons:
		if weapon.has_method("init"):
			weapon.init(_fire_point, _bodies_to_exclude)
			weapon.e_weapon_info.connect(self.update_weapon_info)
	switch_to_weapon_slot(WeaponSlots.MACHETE)
	print_debug("WeaponManager: setup complete")


func update_weapon_info(weapon_name: String, ammo: int) -> void:
	e_current_weapon.emit(weapon_name, ammo)


func attack(attack_input_just_pressed: bool, attack_input_held: bool) -> void:
	if current_weapon == null:
		return
	if !current_weapon.has_method("attack"):
		print_debug("WeaponManager: current_weapon does not have Weapon class linked")
		return
	# Call the attack method of the current weapon
	current_weapon.attack(attack_input_just_pressed, attack_input_held)


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
		slot_index < WeaponSlots.MACHETE
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


func update_animation(velocity: Vector3, is_on_ground: bool) -> void:
	if current_weapon == null:
		return
	if current_weapon and !current_weapon.has_method("is_idle"):
		return
	if is_on_ground and velocity.length() > 0.5 and current_weapon.is_idle():
		animationPlayer.play("moving")


# Connecting from Weapon e_fired signal
# called when weapon is fired
func alert_nearby_enemies() -> void:
	if !is_player:
		return
	var enemies_los := alert_area_los.get_overlapping_bodies()
	for enemy in enemies_los:
		if enemy.has_method("alert"):
			enemy.alert()
	var enemies_hearing := alert_area_sound.get_overlapping_bodies()
	for enemy in enemies_hearing:
		if enemy.has_method("alert"):
			enemy.alert(false)
