extends CharacterBody3D

enum STATES { IDLE, WALK, CHASE, ATTACK, HURT, DEAD }
var current_state := STATES.IDLE

@onready var bone_attachments := $Model/Armature/Skeleton3D
@onready var anim_player := $Model/AnimationPlayer
@onready var health_manager := $HealthManager
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var character_mover: CharacterMover = $CharacterMover
@onready var nav: NavigationAgent3D = $NavigationAgent3D

@export var sight_angle: float = 45.0
@export var turn_speed: float = 360.0
var goal_angle: float = 0.0
var path := []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for bone in bone_attachments.get_children():
		for child in bone.get_children():
			if child is Hitbox:
				child.e_hurt.connect(self.hurt)

	health_manager.init()
	health_manager.e_dead.connect(self.set_state_dead)
	set_state_idle()


func hurt(damage: int, dir: Vector3, critical: bool = false) -> void:
	if current_state == STATES.IDLE:
		set_state_chase()
	health_manager.hurt(damage, dir)


func _process(delta: float) -> void:
	match current_state:
		STATES.IDLE:
			process_state_idle(delta)
		STATES.WALK:
			process_state_walk(delta)
		STATES.CHASE:
			process_state_chase(delta)
		STATES.ATTACK:
			process_state_attack(delta)
		STATES.HURT:
			process_state_hurt(delta)
		STATES.DEAD:
			process_state_dead(delta)


func set_state_idle() -> void:
	current_state = STATES.IDLE
	anim_player.stop()
	anim_player.play("idle")


func set_state_dead() -> void:
	current_state = STATES.DEAD
	anim_player.stop()
	anim_player.play("die")


func set_state_chase():
	current_state = STATES.CHASE
	anim_player.stop()
	anim_player.play("walk", 0.4)


func set_state_attack():
	current_state = STATES.ATTACK
	anim_player.stop()
	anim_player.play("attack")


func process_state_idle(delta: float) -> void:
	if can_see_player():
		set_state_chase()


func process_state_walk(delta: float) -> void:
	pass


func process_state_chase(delta: float) -> void:
	if not can_see_player():
		set_state_idle()
	var our_pos := global_transform.origin
	var player_pos := player.global_transform.origin

	var dir_to_player := our_pos.direction_to(player_pos)
	face_to_direction(dir_to_player, delta)

	nav.target_position = player_pos
	var dir: Vector3 = nav.get_next_path_position() - our_pos
	dir = dir.normalized()
	dir.y = 0
	character_mover.set_move_vec(dir)


func process_state_attack(delta: float) -> void:
	pass


func process_state_hurt(delta: float) -> void:
	pass


func process_state_dead(delta: float) -> void:
	$CollisionShape3D.disabled = true


func can_see_player() -> bool:
	var dir_to_player := global_transform.origin.direction_to(player.global_transform.origin)
	var forward := global_transform.basis.z
	return has_line_of_sight_player() and rad_to_deg(forward.angle_to(dir_to_player)) <= sight_angle


func has_line_of_sight_player() -> bool:
	var from := global_transform.origin + Vector3.UP
	var to := player.global_transform.origin + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, to, self.collision_mask)
	var raycast := get_world_3d().direct_space_state.intersect_ray(query)
	return raycast.has("collider") and raycast.collider is Player


func alert(check_los: bool = true) -> void:
	if current_state != STATES.IDLE or current_state == STATES.DEAD:
		# that means enemy is already alerted
		return
	if check_los and !has_line_of_sight_player():
		# that means enemy is alerted but player is not in sight
		return
	set_state_chase()


func face_to_direction(dir: Vector3, delta: float) -> void:
	var angle_diff := global_transform.basis.z.angle_to(dir)
	var turn_right: int = sign(global_transform.basis.x.dot(dir))
	var turn_angle := deg_to_rad(turn_speed) * delta
	if abs(angle_diff) < turn_angle:
		rotation.y = atan2(dir.x, dir.z)
	else:
		rotation.y += turn_right * turn_angle
