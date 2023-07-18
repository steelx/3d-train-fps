extends RigidBody3D
class_name Player

const JUMP = "jump"
const MOVE_FORWARD = "move_forward"
const MOVE_BACKWARD = "move_backward"
const MOVE_LEFT = "move_left"
const MOVE_RIGHT = "move_right"
const CANCEL = "ui_cancel"
const SPEED = 900

const mouse_sensitivity := 0.0025
var twist_input := 0.0
var pitch_input := 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis(MOVE_LEFT, MOVE_RIGHT)
	input.z = Input.get_axis(MOVE_FORWARD, MOVE_BACKWARD)
	handle_movement(input, delta)
	handle_camera_rotation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity

	if Input.is_action_just_pressed(CANCEL):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func handle_camera_rotation() -> void:
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	twist_input = 0.0
	pitch_input = 0.0


func handle_movement(input: Vector3, delta: float) -> void:
	apply_central_force(twist_pivot.basis * input * SPEED * delta)
