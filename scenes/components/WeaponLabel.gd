extends Label


func _on_weapon_manager_e_current_weapon(weapon_name: String, ammo: int) -> void:
	set_text(str(weapon_name) + " " + str(ammo))
