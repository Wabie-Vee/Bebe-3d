extends Node3D

@export var hold_point: Node3D
@export var camera: Camera3D
var held_object: Node3D = null
func smooth_grab(obj: Node3D):
	var duration := 0.3
	var timer := 0.0

	var start_transform := obj.global_transform
	var start_pos := start_transform.origin
	var start_quat := start_transform.basis.get_rotation_quaternion()

	var end_transform := hold_point.global_transform
	var end_pos := end_transform.origin
	var end_quat := end_transform.basis.get_rotation_quaternion()

	# Ensure shortest path rotation
	if start_quat.dot(end_quat) < 0.0:
		end_quat = -end_quat

	while timer < duration and is_instance_valid(obj):
		var t = clamp(timer / duration, 0.0, 1.0)
		var eased_t = t * t * (3.0 - 2.0 * t)

		var lerped_pos := start_pos.lerp(end_pos, eased_t)
		var lerped_quat := start_quat.slerp(end_quat, eased_t)
		var lerped_basis := Basis(lerped_quat)

		obj.global_transform = Transform3D(lerped_basis, lerped_pos)

		await get_tree().process_frame
		timer += get_process_delta_time()

	if not is_instance_valid(obj): return

	# Final snap into place: match hold point exactly
	obj.get_parent().remove_child(obj)
	hold_point.add_child(obj)
	obj.transform = Transform3D.IDENTITY  # zeroed-out in local space = stays in place relative to hold point

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
