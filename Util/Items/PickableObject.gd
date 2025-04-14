extends RigidBody3D

var is_held = false

func _ready():
	contact_monitor = true
	max_contacts_reported = 1
	
