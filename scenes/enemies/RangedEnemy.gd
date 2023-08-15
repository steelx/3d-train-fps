extends CharacterBody3D

signal e_enemy_attack

enum STATES { IDLE, WALK, CHASE, ATTACK, HURT, DEAD }
var current_state := STATES.IDLE

# Animation / Movement variables
@onready var bone_attachments := $Model/Armature/Skeleton3D
@onready var anim_player := $Model/AnimationPlayer
@onready var health_manager := $HealthManager
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var character_mover: CharacterMover = $CharacterMover
@onready var nav: NavigationAgent3D = $NavigationAgent3D

# Sounds
@onready var dead_sound := $AudioEnemyKill

# Sight/View variables
@export var sight_angle: float = 45.0
@export var turn_speed: float = 300.0
@export var attack_range: float = 50.5
@export var attack_rate: float = 1.5
@export var attack_animation_speed: float = 1.5

# Attack variables
@export var damage: int = 25
@onready var attack_area := $AimAtObject/ProjectileSpawner
@onready var aimer := $AimAtObject
var can_attack := false
@onready var attack_timer := Timer.new()
var enemy_free_timer := Timer.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attack_area.set_damage(damage)
	attack_area.set_bodies_to_exclude([self])
	for bone in bone_attachments.get_children():
		for child in bone.get_children():
			if child is Hitbox:
				child.e_hurt.connect(self.hurt)

	health_manager.init()
	health_manager.e_dead.connect(self.set_state_dead)
	set_state_idle()
	attack_timer.set_wait_time(attack_rate)
	attack_timer.one_shot = true
	attack_timer.connect("timeout", self.finish_attack)
	self.add_child(attack_timer)


func hurt(damage: int, dir: Vector3) -> void:
	if current_state == STATES.DEAD:
		return
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


func set_state_walk() -> void:
	current_state = STATES.WALK
	anim_player.stop()
	anim_player.play("walk")


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
	can_attack = true


func process_state_idle(_delta: float) -> void:
	if can_see_player():
		set_state_chase()
		return
	character_mover.set_move_vec(Vector3.ZERO)


func process_state_walk(delta: float) -> void:
	if can_see_player():
		set_state_chase()
		return


func process_state_chase(delta: float) -> void:
	if is_player_in_attack_range() and has_line_of_sight_player():
		set_state_attack()
		return
	if not has_line_of_sight_player():
		set_state_idle()
		return

	var our_pos := global_transform.origin
	var player_pos := player.global_transform.origin
	face_to_direction(our_pos.direction_to(player_pos), delta)

	nav.target_position = player_pos
	var dir: Vector3 = nav.get_next_path_position() - our_pos
	dir = dir.normalized()
	dir.y = 0
	character_mover.set_move_vec(dir)


func process_state_attack(delta: float) -> void:
	character_mover.set_move_vec(Vector3.ZERO)
	var our_pos := global_transform.origin
	var player_pos := player.global_transform.origin
	face_to_direction(our_pos.direction_to(player_pos), delta)
	if can_attack:
		if !is_player_in_attack_range() and can_see_player():
			set_state_chase()
		else:
			start_attack()


func process_state_hurt(delta: float) -> void:
	pass


func process_state_dead(_delta: float) -> void:
	if enemy_free_timer.time_left > 0:
		return
	dead_sound.play()
	character_mover.freeze()
	enemy_free_timer.set_wait_time(5)
	enemy_free_timer.one_shot = true
	enemy_free_timer.connect("timeout", self.set_free)
	enemy_free_timer.start()
	self.add_child(enemy_free_timer)


func set_free() -> void:
	$CollisionShape3D.disabled = true
	self.queue_free()


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


func is_player_in_attack_range() -> bool:
	var our_pos := global_transform.origin
	var player_pos := player.global_transform.origin
	return our_pos.distance_to(player_pos) <= attack_range and can_see_player()


func start_attack() -> void:
	aimer.aim_at_position(player.global_transform.origin + Vector3.UP * 1.5)
	can_attack = false
	anim_player.stop()
	anim_player.play("attack", attack_animation_speed)
	attack_timer.start()


func finish_attack() -> void:
	can_attack = true
	attack_timer.stop()


func emit_enemy_attack_signal() -> void:
	e_enemy_attack.emit()
