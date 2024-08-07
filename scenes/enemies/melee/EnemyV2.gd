# EnemyV2 deals with movement and state changes
extends CharacterBody3D
class_name Enemy

enum STATES { IDLE, ROAM, RETURN_TO_BASE, SPOT, FOLLOW, STAGGER, ATTACK, ATTACK_COOLDOWN, DIE, DEAD }
@export var state: STATES = STATES.IDLE

@onready var target: Player = get_tree().get_first_node_in_group("player")
var has_target: bool = false
var target_position: Vector3 = Vector3.ZERO

# Movement variables
@onready var spawn_position: Vector3 = global_position
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
# var velocity: Vector3 = Vector3.ZERO
const MASS := 2.0
@export var FOLLOW_RANGE := 15.0
@export var MAX_FOLLOW_SPEED := 7.0
@export var ARRIVE_DISTANCE := 2.0
@export var SLOW_RADIUS := 3.0
@export var MAX_ROAM_SPEED := 3.0
@export var ROAM_RADIUS := 15.0
var roam_target_position := Vector3.ZERO
var roam_slow_radius: float = 1.0

# Animations
@onready var bone_attachments := $Model/Armature/Skeleton3D
@onready var anim_player := $Model/AnimationPlayer
@onready var health_manager := $HealthManager
@onready var roamTimer: Timer = $RoamTimer

# Sight/View variables
@export var sight_angle: float = 45.0
@export var turn_speed: float = 360.0
const AVOID_MAX_DISTANCE: float = 2.0
const AVOID_FORCE: float = 200.0
@onready var navigationAgent: NavigationAgent3D = $NavigationAgent3D

# Attack variables
@export var attack_range: float = 2.0  #attack_range wrt aimer child Z position
@export var attack_rate: float = 0.5
@export var attack_animation_speed: float = 1.0
@export var damage: int = 30
@onready var attack_area := $AimAtObject/MeleeDamagePoint
@onready var aimer := $AimAtObject


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not target:
		print_debug("target not found")
		return
	has_target = true
	target.e_died.connect(self._on_target_died)
	change_state(STATES.IDLE)
	roamTimer.connect("timeout", self._on_roam_timer_timeout)
	# Animations
	for bone in bone_attachments.get_children():
		for child in bone.get_children():
			if child is Hitbox:
				child.e_hurt.connect(self.hurt)

	health_manager.init()
	health_manager.e_dead.connect(func(): self.change_state(STATES.DEAD))


func change_state(new_state: STATES) -> void:
	if state == STATES.IDLE:
		roamTimer.stop()

	anim_player.stop()

	match new_state:
		STATES.IDLE:
			anim_player.play("idle")
			randomize()
			var random_time := randf_range(0.5, 2.0)
			roamTimer.set_wait_time(random_time)
			# _on_roam_timer_timeout change state to roam
			roamTimer.start()

		STATES.ROAM:
			anim_player.play("walk")
			randomize()
			var random_angle := randf() * PI * 2.0
			var circle_offset := 0.5 * ROAM_RADIUS
			randomize()
			var random_radius := randf() * ROAM_RADIUS * 0.5 + circle_offset
			roam_target_position = (spawn_position + Vector3(cos(random_angle) * random_radius, 0.0, sin(random_angle) * random_radius))
			roam_slow_radius = spawn_position.distance_to(roam_target_position) * 0.5

		STATES.SPOT:
			$SpotIcon.on_spot(self._on_spot_tween_completed)

		STATES.ATTACK:
			aimer.aim_at_position(target.global_position + Vector3.UP * 1.5)
			anim_player.play("attack", attack_animation_speed)
			$AudioAttack.play()
			for child in aimer.get_children():
				if child.has_method("set_damage"):
					child.set_damage(damage)
				if child.has_method("fire"):
					child.fire()

		STATES.ATTACK_COOLDOWN:
			randomize()
			get_tree().create_timer(attack_rate).connect("timeout", func(): self.change_state(STATES.FOLLOW))

		STATES.RETURN_TO_BASE:
			anim_player.play("walk", 0.4)

		STATES.FOLLOW:
			anim_player.play("walk", 0.4)

		STATES.DEAD:
			anim_player.stop()
			anim_player.play("die")
			get_tree().create_timer(3).connect("timeout", func(): self.queue_free())

	state = new_state


func _physics_process(delta: float) -> void:
	var current_state := state
	# print_state(current_state)
	match current_state:
		STATES.IDLE:
			add_gravity(delta)
			var distance_to_target: float = global_position.distance_to(target.global_position)
			if distance_to_target < FOLLOW_RANGE and has_target:
				change_state(STATES.SPOT)

		STATES.ROAM:
			face_to_direction(roam_target_position, delta)
			var distance_to_target := arrive_to(roam_target_position, roam_slow_radius, MAX_ROAM_SPEED)
			add_gravity(delta)
			move_and_slide()
			if distance_to_target <= ARRIVE_DISTANCE or hit_the_wall(velocity) != Vector3.ZERO:
				change_state(STATES.IDLE)
				return
			if global_position.distance_to(target.global_position) < FOLLOW_RANGE and has_target:
				change_state(STATES.SPOT)
				return

		STATES.RETURN_TO_BASE:
			face_to_direction(spawn_position, delta)
			var distance_to_target := follow(spawn_position, MAX_ROAM_SPEED, delta)
			add_gravity(delta)
			move_and_slide()
			if distance_to_target < ARRIVE_DISTANCE:
				change_state(STATES.IDLE)
				return
			if global_position.distance_to(target.global_position) < FOLLOW_RANGE and has_target:
				change_state(STATES.SPOT)
				return

		STATES.FOLLOW:
			anim_player.play("walk", 0.4)
			face_to_direction(target.global_position, delta)
			if is_player_in_attack_range():
				change_state(STATES.ATTACK)
				return
			var distance_to_target := follow(target.global_position, MAX_FOLLOW_SPEED, delta)
			add_gravity(delta)
			move_and_slide()

			if distance_to_target > FOLLOW_RANGE:
				change_state(STATES.RETURN_TO_BASE)
				return


# follow: mutates velocity and return distance to target
func follow(desired_position: Vector3, max_speed: float, delta: float) -> float:
	var direction: Vector3 = Vector3.ZERO
	navigationAgent.target_position = desired_position
	direction = navigationAgent.get_next_path_position() - global_position
	direction = direction.normalized()
	velocity = velocity.lerp(direction * max_speed, delta)
	return global_position.distance_to(desired_position)


func arrive_to(desired_position: Vector3, slow_radius: float, max_speed: float) -> float:
	var dir: Vector3 = (desired_position - global_position).normalized()
	var desired_velocity: Vector3 = dir * max_speed
	var distance_to_target: float = global_position.distance_to(desired_position)
	if distance_to_target < slow_radius:
		desired_velocity *= ((distance_to_target / slow_radius) * 0.75) + 0.25
	var steering_force := (desired_velocity - velocity) / MASS
	velocity += steering_force
	return distance_to_target


func add_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func _on_target_died() -> void:
	target_position = Vector3.ZERO
	has_target = false
	change_state(STATES.RETURN_TO_BASE)


func hurt(_damage: int, dir: Vector3) -> void:
	if state == STATES.DEAD:
		return
	if state != STATES.DEAD and state != STATES.FOLLOW:
		#TODO: set state in alert
		pass
	health_manager.hurt(_damage, dir)


func face_to_direction(desired_position: Vector3, delta: float) -> void:
	var dir := global_position.direction_to(desired_position)
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


func is_player_in_attack_range() -> bool:
	var our_pos := global_transform.origin
	var player_pos := target.global_position
	return our_pos.distance_to(player_pos) <= attack_range and can_see_player()


func hit_the_wall(desired_velocity: Vector3) -> Vector3:
	# check if obstacle is in front of the enemy and return reflect vector
	var from := global_transform.origin
	var to := global_transform.origin + global_transform.basis.z * AVOID_MAX_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to, self.collision_mask)
	var raycast := get_world_3d().direct_space_state.intersect_ray(query)
	if raycast.has("collider"):
		if raycast.collider is StaticBody3D:
			var normal = raycast.normal
			var reflect: Vector3 = desired_velocity - 2 * desired_velocity.dot(normal) * normal
			return reflect
	return Vector3.ZERO


# call this func from AnimationPlayer
func _on_attack_anim_end() -> void:
	change_state(STATES.ATTACK_COOLDOWN)


func _on_roam_timer_timeout() -> void:
	change_state(STATES.ROAM)


func _on_spot_tween_completed() -> void:
	$SpotIcon.hide()
	change_state(STATES.FOLLOW)


func print_state(state: STATES) -> void:
	match state:
		STATES.IDLE:
			print_debug("IDLE")
		STATES.ROAM:
			print_debug("ROAM")
		STATES.RETURN_TO_BASE:
			print_debug("RETURN_TO_BASE")
		STATES.SPOT:
			print_debug("SPOT")
		STATES.FOLLOW:
			print_debug("FOLLOW")
		STATES.STAGGER:
			print_debug("STAGGER")
		STATES.ATTACK:
			print_debug("ATTACK")
		STATES.ATTACK_COOLDOWN:
			print_debug("ATTACK_COOLDOWN")
		STATES.DIE:
			print_debug("DIE")
		STATES.DEAD:
			print_debug("DEAD")
