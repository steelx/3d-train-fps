extends Node
class_name CharacterMover

@export var body_to_move: CharacterBody3D

@export var move_accel = 4
@export var max_speed = 4
@export var jump_force = 12
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var ignore_rotation = false

var drag = 0.0
var pressed_jump = false
var move_vec: Vector3
var velocity: Vector3
var snap_vec: Vector3

signal movement_info(velocity: Vector3, grounded: bool)

var frozen = false


func _ready() -> void:
	drag = float(move_accel) / max_speed


func jump():
	pressed_jump = true


func set_move_vec(move: Vector3) -> void:
	move_vec = move.normalized()


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var cur_move_vec = move_vec
	if !ignore_rotation:
		cur_move_vec = cur_move_vec.rotated(Vector3.UP, body_to_move.rotation.y)

	body_to_move.velocity = body_to_move.velocity.lerp(cur_move_vec * max_speed, move_accel * delta)
	body_to_move.move_and_slide()

	# Add the gravity.
	var grounded = body_to_move.is_on_floor()
	if not grounded:
		body_to_move.velocity.y -= gravity * delta

	movement_info.emit(velocity, grounded)


func freeze() -> void:
	frozen = true


func unfreeze() -> void:
	frozen = false
