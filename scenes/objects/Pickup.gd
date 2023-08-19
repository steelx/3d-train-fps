extends Area3D
class_name Pickup

enum PickupType {
	HEALTH,
	MACHINE_GUN,
	MACHINE_GUN_AMMO,
	SHOTGUN,
	SHOTGUN_AMMO,
	ROCKET_LAUNCHER,
	ROCKET_LAUNCHER_AMMO,
	KEY,
	EXIT
}

@export var pickup_type: PickupType
@export var amount: int = 1
