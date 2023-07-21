extends Node3D

# display any one MuzzleFlash model from $muzzleflash1 to $muzzleflash3
@onready var muzzle1 := $muzzleflash1
@onready var muzzle2 := $muzzleflash2
@onready var muzzle3 := $muzzleflash3

var MUZZLE_VARIANTS: Array

@export var muzzle_variant: int = 1:
	set(val):
		if val > 3 or val < 1:
			muzzle_variant = 1

@export var flash_time := 0.05
var timer: Timer


func _ready() -> void:
	MUZZLE_VARIANTS = [muzzle1, muzzle2, muzzle3]
	timer = Timer.new()
	timer.set_wait_time(flash_time)
	timer.set_one_shot(true)
	add_child(timer)
	timer.connect("timeout", self.on_flash_timeout)
	hide()


func toggle_muzzle_variant() -> void:
	muzzle_variant = (muzzle_variant % 3) - 1
	var muzzle: Node3D = MUZZLE_VARIANTS[muzzle_variant]
	muzzle1.hide()
	muzzle2.hide()
	muzzle3.hide()
	muzzle.show()


func flash() -> void:
	timer.start()
	rotation.z = randf_range(0, 2 * PI)
	show()
	toggle_muzzle_variant()


func on_flash_timeout() -> void:
	hide()


func _on_machine_gun_e_fired(_bullet_emitter: Node3D) -> void:
	self.flash()


func _on_shotgun_e_fired(_bullet_emitter: Node3D) -> void:
	self.flash()


func _on_rocket_launcher_e_fired(_bullet_emitter: Node3D) -> void:
	self.flash()
