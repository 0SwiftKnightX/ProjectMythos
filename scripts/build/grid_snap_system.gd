class_name GridSnapSystem
extends RefCounted

# Integer grid coordinates prevent floating point drift in saved construction data.
# 1 meter = 10 grid units, so 0.1 meter is the smallest build increment.
const SUBDIVISIONS_PER_METER := 10

static func snap_world_position(position: Vector3) -> Vector3:
	return Vector3(_snap_axis(position.x), _snap_axis(position.y), _snap_axis(position.z))

static func world_to_grid(position: Vector3) -> Vector3i:
	return Vector3i(roundi(position.x * SUBDIVISIONS_PER_METER), roundi(position.y * SUBDIVISIONS_PER_METER), roundi(position.z * SUBDIVISIONS_PER_METER))

static func grid_to_world(position: Vector3i) -> Vector3:
	return Vector3(position) / SUBDIVISIONS_PER_METER

static func _snap_axis(value: float) -> float:
	return roundi(value * SUBDIVISIONS_PER_METER) / float(SUBDIVISIONS_PER_METER)
