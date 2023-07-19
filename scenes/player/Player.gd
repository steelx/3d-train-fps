extends RigidBody3D
class_name Player

const JUMP = "jump"
const MOVE_FORWARD = "move_forward"
const MOVE_BACKWARD = "move_backward"
const MOVE_LEFT = "move_left"
const MOVE_RIGHT = "move_right"
const CANCEL = "ui_cancel"
const SPEED = 1200.0
const JUMP_FORCE = 8.0

const mouse_sensitivity := 0.0025
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var raycast := $RayCast3D
@onready var character := $Character
@onready var animator := $AnimationTree
@onready var playback = animator["parameters/playback"]
var blend_path := "parameters/Run/blend_position"


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis(MOVE_LEFT, MOVE_RIGHT)
	input.z = Input.get_axis(MOVE_FORWARD, MOVE_BACKWARD)
	handle_movement(input, delta)
	handle_character_rotation(input, delta)
	handle_animation(input, delta)
	handle_camera_rotation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity

	if Input.is_action_just_pressed(CANCEL):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed(JUMP):
		if raycast.is_colliding():
			apply_central_impulse(Vector3.UP * JUMP_FORCE)
			handle_jump_animation()


func handle_camera_rotation() -> void:
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	twist_input = 0.0
	pitch_input = 0.0


func handle_movement(input: Vector3, delta: float) -> void:
	var move_direction: Vector3 = twist_pivot.basis * input
	apply_central_force(move_direction * SPEED * delta)


func handle_character_rotation(input: Vector3, delta: float) -> void:
	if not input.is_zero_approx():
		var move_direction: Vector3 = twist_pivot.basis * input
		var align = character.transform.looking_at(character.transform.origin - move_direction)
		character.transform = character.transform.interpolate_with(align, delta * 20.0)


func handle_animation(direction: Vector3, delta: float) -> void:
	# Idle, Run blend
	animator[blend_path] = lerp(animator[blend_path], direction.length(), delta * 5.0)


func handle_jump_animation() -> void:
	playback.start("Jump")
