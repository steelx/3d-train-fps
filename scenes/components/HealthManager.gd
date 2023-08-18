extends Node
class_name HealthManager

var blood_splash := preload("res://scenes/effects/BloodSplash.tscn")
var gibs := preload("res://scenes/effects/gibs.tscn")

# Events
signal e_health_changed(cur_health: int)
signal e_dead
signal e_hurt
signal e_healed
signal e_critical

@export var critical_at: int = 20
@export var max_health: int = 100
var current_health: int = 1


func _ready() -> void:
	self.init()


func init() -> void:
	current_health = max_health
	e_health_changed.emit(current_health)


func hurt(damage: int, dir: Vector3) -> void:
	spawn_blood(dir)
	if current_health <= 0:
		return
	current_health -= damage
	if current_health - damage <= 0:
		spawn_gibs()
	if current_health - damage <= critical_at:
		e_critical.emit()
	if current_health <= 0:
		e_dead.emit()
	else:
		e_hurt.emit()
	e_health_changed.emit(current_health)


func heal(amount: int):
	if current_health <= 0:
		return
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	e_healed.emit()
	e_health_changed.emit(current_health)


func spawn_blood(dir: Vector3) -> void:
	var effect = blood_splash.instantiate()
	var character = get_parent()
	effect.global_transform.origin = character.global_transform.origin + 1.5 * Vector3.UP
	get_tree().get_root().add_child(effect)
	if dir.angle_to(Vector3.UP) < 0.008:
		return
	# Rotate effect
	if dir.angle_to(Vector3.DOWN) < 0.008:
		# effect.rotate_object_local(Vector3.RIGHT, PI)
		effect.rotate(Vector3.RIGHT, PI)
		return
	var y: Vector3 = dir
	var x: Vector3 = y.cross(Vector3.UP)
	var z: Vector3 = x.cross(y)
	effect.global_transform.basis = Basis(x, y, z)


func spawn_gibs() -> void:
	var effect = gibs.instantiate()
	var character = get_parent()
	effect.global_transform.origin = character.global_transform.origin + 1.5 * Vector3.UP
	get_tree().get_root().add_child(effect)
	effect.enable_gibs()
