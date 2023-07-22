extends Node3D
class_name Weapon

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var bullet_emitters_marker: Marker3D = $BulletEmitters
@onready var bullet_emitters: Array = $BulletEmitters.get_children()
@onready var crosshair := $Crosshair

@export var automatic := false
@export var damage := 10
@export var ammo := 30
@export var attack_rate := 0.2
var attack_timer: Timer

signal e_fired(bullet_emitter: Node3D)
signal e_out_of_ammo

var can_attack := true
var fire_point: Node3D
var bodies_to_exclude: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attack_timer = Timer.new()
	attack_timer.set_wait_time(attack_rate)
	attack_timer.set_one_shot(true)
	attack_timer.connect("timeout", self._on_attack_timer_timeout)
	add_child(attack_timer)


# to be initialized from the WeaponManager
func setup(_fire_point: Node3D, _bodies_to_exclude: Array) -> void:
	self.fire_point = _fire_point
	self.bodies_to_exclude = _bodies_to_exclude
	# bullet_emitter is a Typeof HitScanBullterEmitter
	for bullet_emitter in bullet_emitters:
		bullet_emitter.set_bodies_to_exclude(_bodies_to_exclude)
		bullet_emitter.set_damage(self.damage)


# to be called from the WeaponManager
func attack(attack_input_just_pressed: bool, attack_input_held: bool) -> void:
	if !attack_input_just_pressed and !attack_input_held:
		if automatic:
			anim_player.stop()
		return
	if fire_point == null:
		print_debug("Weapon: fire_point is null")
		return
	if !can_attack:
		return
	if automatic and !attack_input_held:
		return
	elif !automatic and !attack_input_just_pressed:
		return
	if ammo == 0:
		e_out_of_ammo.emit()
		return

	if ammo > 0:
		ammo -= 1

	var marker_transform := bullet_emitters_marker.global_transform
	bullet_emitters_marker.global_transform = fire_point.global_transform
	# bullet_emitter is a Typeof HitScanBullterEmitter
	for bullet_emitter in bullet_emitters:
		bullet_emitter.fire()
	bullet_emitters_marker.global_transform = marker_transform
	anim_player.stop()
	anim_player.play("attack")
	e_fired.emit(fire_point)
	can_attack = false
	attack_timer.start()


# Finish attack
func _on_attack_timer_timeout() -> void:
	can_attack = true


func set_active() -> void:
	self.show()
	crosshair.show()


func set_inactive() -> void:
	set_to_attack_idle()
	self.hide()
	crosshair.hide()


func set_to_attack_idle() -> void:
	anim_player.stop()
	anim_player.play("idle")
