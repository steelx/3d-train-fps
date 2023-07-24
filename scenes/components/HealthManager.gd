extends Node
class_name HealthManager

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


func hurt(damage: int, _dir: Vector3) -> void:
	if current_health <= 0:
		return
	current_health -= damage
	if current_health - damage <= critical_at:
		#TODO make gibs spawner
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
