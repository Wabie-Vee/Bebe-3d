extends RigidBody3D

var is_held = false

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	add_to_group("pickable")  # Ensure it's properly detected by player raycast

func _on_picked_up():
	is_held = true
	sleeping = true
	freeze = true
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	# Optional: play pickup sound or animation
	# $PickupSound.play()

func _on_dropped():
	is_held = false
	sleeping = false
	freeze = false
	set_deferred("collision_layer", 1)
	set_deferred("collision_mask", 1)
	# Optional: play drop sound or bounce animation
	# $DropSound.play()
