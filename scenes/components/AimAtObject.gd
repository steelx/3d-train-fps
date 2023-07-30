extends Marker3D
class_name AimAtObject


func aim_at_position(pos: Vector3):
	self.rotation = Vector3.ZERO
	var offset := to_local(pos)
	offset.x = 0
	self.rotation.x = -atan2(offset.y, offset.z)
