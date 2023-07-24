extends CharacterBody3D

enum STATES { IDLE, WALK, CHASE, ATTACK, HURT, DEAD }
var current_state := STATES.IDLE

@onready var bone_attachments := $Model/Armature/Skeleton3D
@onready var anim_player := $Model/AnimationPlayer
@onready var health_manager := $HealthManager
@onready var player: Player = get_tree().get_first_node_in_group("player")

@export var sight_angle: float = 45.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for bone in bone_attachments.get_children():
		for child in bone.get_children():
			if child is Hitbox:
				child.e_hurt.connect(self.hurt)
	set_state_idle()
	health_manager.init()
	health_manager.e_dead.connect(self.set_state_dead)


func hurt(damage: int, dir: Vector3, critical: bool) -> void:
	if current_state == STATES.IDLE:
		set_state_chase()
	health_manager.hurt(damage, dir)


func _process(delta: float) -> void:
	# print_debug(can_see_player())
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
	anim_player.play("idle")


func set_state_dead() -> void:
	current_state = STATES.DEAD
	anim_player.play("die")


func set_state_chase():
	current_state = STATES.CHASE
	anim_player.play("walk")


func set_state_attack():
	current_state = STATES.ATTACK
	anim_player.play("attack")


func process_state_idle(delta: float) -> void:
	pass


func process_state_walk(delta: float) -> void:
	pass


func process_state_chase(delta: float) -> void:
	pass


func process_state_attack(delta: float) -> void:
	pass


func process_state_hurt(delta: float) -> void:
	pass


func process_state_dead(delta: float) -> void:
	pass


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


func alert(player_pos: Vector3, has_los: bool = true) -> void:
	if current_state != STATES.IDLE or current_state == STATES.DEAD:
		# that means enemy is already alerted
		return
	if has_los and !has_line_of_sight_player():
		# that means enemy is alerted but player is not in sight
		return
	set_state_chase()
	print_debug("alerted")
