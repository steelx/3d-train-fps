extends RigidBody3D
class_name Player

const FIRE = "fire"
const RELOAD = "reload"
const JUMP = "jump"
const MOVE_FORWARD = "move_forward"
const MOVE_BACKWARD = "move_backward"
const MOVE_LEFT = "move_left"
const MOVE_RIGHT = "move_right"
const CANCEL = "ui_cancel"
const SPEED = 12.0
const JUMP_FORCE = 8.0

const hotkeys := {
	KEY_0: 0,
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2,
	KEY_4: 3,
}

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
@onready var health_label := $CanvasLayer/Label

@onready var weapon_manager: WeaponManager = $TwistPivot/PitchPivot/Camera3D/Hand/WeaponManager
@onready var health_manager: HealthManager = $HealthManager
var is_dead := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_manager.init()
	health_manager.e_dead.connect(self.kill)
	health_manager.e_critical.connect(self.at_critical)
	health_manager.e_health_changed.connect(self.health_changed)
	var fire_point = $TwistPivot/PitchPivot/Camera3D/FirePoint
	weapon_manager.init(fire_point, [self])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead:
		return
	var input := Vector3.ZERO
	input.x = Input.get_axis(MOVE_LEFT, MOVE_RIGHT)
	input.z = Input.get_axis(MOVE_FORWARD, MOVE_BACKWARD)
	handle_movement(input, delta)
	handle_character_rotation(input, delta)
	handle_animation(input, delta)
	handle_camera_rotation()
	weapon_manager.update_animation(linear_velocity, is_on_ground())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity

	if Input.is_action_just_pressed(CANCEL):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	weapon_manager.attack(Input.is_action_just_pressed(FIRE), Input.is_action_pressed(FIRE))

	if event.is_action_pressed(JUMP):
		if is_on_ground():
			apply_central_impulse(Vector3.UP * JUMP_FORCE)
			handle_jump_animation()
	if event is InputEventKey and event.is_pressed():
		if event.keycode in hotkeys:
			weapon_manager.switch_to_weapon_slot(hotkeys[event.keycode])
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			weapon_manager.switch_to_next_weapon()


func handle_camera_rotation() -> void:
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30))
	twist_input = 0.0
	pitch_input = 0.0


func handle_movement(input: Vector3, delta: float) -> void:
	var move_direction: Vector3 = twist_pivot.basis * input
	apply_central_force(move_direction * SPEED * delta * 100)


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


func hurt(dmg: int, dir: Vector3) -> void:
	health_manager.hurt(dmg, dir)


func heal(amt: int) -> void:
	health_manager.heal(amt)


func kill() -> void:
	is_dead = true
	self.freeze = true


func at_critical() -> void:
	print_debug("Player at critical health")


func health_changed(health: int) -> void:
	health_label.text = "Health: " + str(health)


func is_on_ground() -> bool:
	return raycast.is_colliding()
