class_name BuildPlacementValidator
extends RefCounted

const DEFAULT_COLLISION_MASK := 1 << 2

static func is_position_valid(
	part: ConstructionPart,
	proposed_position: Vector3,
	proposed_rotation: Basis,
	space_state: PhysicsDirectSpaceState3D,
	collision_mask: int = DEFAULT_COLLISION_MASK
) -> bool:
	if part == null or space_state == null:
		return false

	var collision_shapes := _get_collision_shapes(part)
	if collision_shapes.is_empty():
		return true

	var excluded_rids := _get_excluded_rids(part)
	for collision_shape in collision_shapes:
		if collision_shape.shape == null:
			continue

		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collision_shape.shape
		query.transform = Transform3D(proposed_rotation, proposed_position) * collision_shape.transform
		query.collision_mask = collision_mask
		query.collide_with_bodies = true
		query.collide_with_areas = true
		query.exclude = excluded_rids

		if not space_state.intersect_shape(query, 1).is_empty():
			return false

	return true

static func _get_collision_shapes(part: ConstructionPart) -> Array[CollisionShape3D]:
	var result: Array[CollisionShape3D] = []
	for node in part.find_children("*", "CollisionShape3D", true, false):
		var collision_shape := node as CollisionShape3D
		if collision_shape != null and collision_shape.disabled == false:
			result.append(collision_shape)
	return result

static func _get_excluded_rids(part: ConstructionPart) -> Array[RID]:
	var result: Array[RID] = []
	for node in part.find_children("*", "CollisionObject3D", true, false):
		var collision_object := node as CollisionObject3D
		if collision_object != null:
			result.append(collision_object.get_rid())
	return result
