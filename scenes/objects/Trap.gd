extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.hurt(30, Vector3.ZERO)
