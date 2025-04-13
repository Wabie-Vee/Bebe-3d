extends Node3D

@export var hold_point: Node3D
@export var camera: Camera3D
var held_object: Node3D = null
func smooth_grab(obj: Node3D):
	var duration := 0.2
	var timer := 0.0

	var start_transform := obj.global_transform
	var start_origin := start_transform.origin
	var start_basis := start_transform.basis

	
	var direction = (camera.global_transform.origin - start_origin).normalized()

	# Make the front (+Z) of the object face the player
	var final_basis = Basis().looking_at(direction, Vector3.UP).rotated(Vector3.UP, PI)
	var final_quat = final_basis.get_rotation_quaternion()
	var start_quat = start_basis.get_rotation_quaternion()

	# 🔥 Fix for spinning too far: force shortest path
	

	while timer < duration and is_instance_valid(obj):
		var target_pos := hold_point.global_transform.origin
		var t = clamp(timer / duration, 0.0, 1.0)
		var eased_t = t * t * (3.0 - 2.0 * t)  # smoothstep easing

		# Lerp position
		var lerped_origin = start_origin.lerp(target_pos, eased_t)

		# Slerp rotation with corrected quaternions
		var lerped_quat = start_quat.slerp(final_quat, eased_t)
		var lerped_basis = Basis(lerped_quat)

		obj.global_transform = Transform3D(lerped_basis, lerped_origin)

		await get_tree().process_frame
		timer += get_process_delta_time()

	if not is_instance_valid(obj): return

	# Reparent without snap
	var target_pos := hold_point.global_transform.origin
	var final_transform = Transform3D(final_quat, target_pos)
	var local_transform = hold_point.global_transform.affine_inverse() * final_transform

	obj.get_parent().remove_child(obj)
	hold_point.add_child(obj)
	obj.transform = local_transform

func try_pickup(player: Node3D) -> Node3D:
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -2
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]

	var result = space_state.intersect_ray(query)
	if result and result.collider.is_in_group("pickable"):
		var obj = result.collider
		held_object = obj
		obj.is_held = true
		obj.sleeping = true
		obj.freeze = true
		obj.set_deferred("collision_layer", 0)
		obj.set_deferred("collision_mask", 0)
		return obj  # ✅ return it

	return null  # ❗ if nothing picked

		
		
func drop_object():
	if held_object:
		# Store current global transform before reparenting
		var held_transform = held_object.global_transform

		# Remove and reparent to world
		held_object.get_parent().remove_child(held_object)
		get_tree().get_root().add_child(held_object)

		# Restore exact position and rotation it had while being held
		held_object.global_transform = held_transform

		# Re-enable physics
		held_object.sleeping = false
		held_object.freeze = false
		held_object.set_deferred("collision_layer", 1)
		held_object.set_deferred("collision_mask", 1)
		held_object.is_held = false
		held_object = null
