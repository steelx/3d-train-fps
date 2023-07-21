extends Node3D

@export var flash_time := 0.05
var timer: Timer


func _ready() -> void:
	timer = Timer.new()
	timer.set_wait_time(flash_time)
	timer.set_one_shot(true)
	add_child(timer)
	timer.connect("timeout", self.on_flash_timeout)
	hide()


func flash() -> void:
	timer.start()
	rotation.z = randf_range(0, 2 * PI)
	show()


func on_flash_timeout() -> void:
	hide()


func _on_machine_gun_e_fired(_bullet_emitter: Node3D) -> void:
	self.flash()
