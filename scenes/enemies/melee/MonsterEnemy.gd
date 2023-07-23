extends CharacterBody3D

@onready var bone_attachments := $Model/Armature/Skeleton3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for bone in bone_attachments.get_children():
		for child in bone.get_children():
			if child is Hitbox:
				child.e_hurt.connect(self._on_Hitbox_hurt)


func _on_Hitbox_hurt(damage: int, dir: Vector3, critical: bool) -> void:
	print_debug("monster got hit: ", damage)
