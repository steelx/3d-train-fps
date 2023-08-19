# EnemyV2 deals with movement and state changes
extends RigidBody3D
class_name Enemy

enum STATES {IDLE, ROAM, RETURN_TO_BASE, SPOT, FOLLOW, STAGGER, ATTACK, ATTACK_COOLDOWN, DIE, DEAD}
@export var state: STATES = STATES.IDLE

@onready var target: Player = get_tree().get_first_node_in_group("player")
var has_target: bool = false
var target_position: Vector3 = Vector3.ZERO

# Movement variables
var velocity: Vector3 = Vector3.ZERO
var MASS := 2.5
const FOLLOW_RANGE = 10.0
@export var MAX_FOLLOW_SPEED = 4.0
@onready var nav: NavigationAgent3D = $NavigationAgent3D

# Animations
@onready var bone_attachments := $Model/Armature/Skeleton3D
@onready var anim_player := $Model/AnimationPlayer
@onready var health_manager := $HealthManager

# Sight/View variables
@export var sight_angle: float = 45.0
@export var turn_speed: float = 360.0
@export var attack_range: float = 2.5
@export var attack_rate: float = 0.5
@export var attack_animation_speed: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not target:
		print_debug("target not found")
		return
	has_target = true
	target.e_position_changed.connect(self._on_target_position_changed)
	target.e_died.connect(self._on_target_died)
	change_state(STATES.IDLE)
	# Animations
	for bone in bone_attachments.get_children():
		for child in bone.get_children():
			if child is Hitbox:
				child.e_hurt.connect(self.hurt)

	health_manager.init()
	health_manager.e_dead.connect(self.set_state_dead)


func change_state(new_state: STATES) -> void:
	state = new_state


# follow: mutates velocity and return distance to target
func follow(desired_position: Vector3, max_speed: float) -> float:
	var dir: Vector3 = (desired_position - global_transform.origin).normalized()
	var desired_velocity: Vector3 = dir * max_speed
	var steering_force := (desired_velocity - velocity) / MASS
	velocity += steering_force
	return global_transform.origin.distance_to(desired_position)


func _physics_process(delta: float) -> void:
	match state:
		STATES.IDLE:
			anim_player.play("idle")
			var distance_to_target: float = global_transform.origin.distance_to(
				target.global_transform.origin
			)
			if distance_to_target < FOLLOW_RANGE:
				if not has_target:
					return
				change_state(STATES.FOLLOW)
		STATES.FOLLOW:
			var distance_to_target := follow(target.global_transform.origin, MAX_FOLLOW_SPEED)
			move_and_collide(velocity * delta)
			if distance_to_target > FOLLOW_RANGE:
				change_state(STATES.IDLE)
				return

			anim_player.play("walk", 0.4)
			var our_pos := global_transform.origin
			var player_pos := target.global_transform.origin
			face_to_direction(our_pos.direction_to(player_pos), delta)

			nav.target_position = player_pos
			var dir: Vector3 = nav.get_next_path_position() - our_pos
			dir = dir.normalized()
			dir.y = 0


func _on_target_position_changed(new_position: Vector3) -> void:
	target_position = new_position


func _on_target_died() -> void:
	target_position = Vector3.ZERO
	has_target = false
	change_state(STATES.RETURN_TO_BASE)


func hurt(_damage: int, dir: Vector3) -> void:
	if state == STATES.DEAD:
		return
	health_manager.hurt(_damage, dir)


func set_state_dead() -> void:
	state = STATES.DEAD
	anim_player.stop()
	anim_player.play("die")


func face_to_direction(dir: Vector3, delta: float) -> void:
	var angle_diff := global_transform.basis.z.angle_to(dir)
	var turn_right: int = sign(global_transform.basis.x.dot(dir))
	var turn_angle := deg_to_rad(turn_speed) * delta
	if abs(angle_diff) < turn_angle:
		rotation.y = atan2(dir.x, dir.z)
	else:
		rotation.y += turn_right * turn_angle


func can_see_player() -> bool:
	return has_line_of_sight_player() and is_player_within_angle()


func is_player_within_angle() -> bool:
	var dir_to_player := global_transform.origin.direction_to(target.global_transform.origin)
	var forward := global_transform.basis.z
	return rad_to_deg(forward.angle_to(dir_to_player)) <= sight_angle


func has_line_of_sight_player() -> bool:
	var from := global_transform.origin + Vector3.UP
	var to := target.global_transform.origin + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, to, self.collision_mask)
	var raycast := get_world_3d().direct_space_state.intersect_ray(query)
	return raycast.has("collider") and raycast.collider is Player
