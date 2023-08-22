extends Label3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()


func on_spot(_on_spot_tween_completed: Callable) -> void:
	self.show()
	var tween = get_tree().create_tween().set_parallel(true)
	(
		tween
		. tween_property(self, "position", Vector3(0, 2.4, 0), 2)
		. set_trans(Tween.TRANS_LINEAR)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(self, "scale", Vector3(2, 2, 2), 2).set_trans(Tween.TRANS_BOUNCE).set_ease(
		Tween.EASE_IN_OUT
	)
	tween.tween_callback(_on_spot_tween_completed).set_delay(0.5)
	tween.play()
