class_name ConstructionPart
extends XRToolsPickable

@export var part_id := "block_1m"
@export var construction_id := ""
@export var dimensions := Vector3.ONE
@export var attachment_points: Array[Dictionary] = []
@export var component_properties: Dictionary = {}

func configure(id: String, properties: Dictionary = {}) -> void:
	part_id = id
	construction_id = str(properties.get("construction_id", "%s_%s" % [id, randi()]))
	component_properties.merge(properties, true)

func to_record(order: int) -> Dictionary:
	return {
		"order": order,
		"part_id": part_id,
		"construction_id": construction_id,
		"position": [GridSnapSystem.world_to_grid(position).x, GridSnapSystem.world_to_grid(position).y, GridSnapSystem.world_to_grid(position).z],
		"rotation": [rotation_degrees.x, rotation_degrees.y, rotation_degrees.z],
		"scale": [scale.x, scale.y, scale.z],
		"attachments": attachment_points.duplicate(true),
		"properties": component_properties.duplicate(true)
	}

func apply_record(record: Dictionary) -> void:
	construction_id = str(record.construction_id)
	var grid: Array = record.position
	position = GridSnapSystem.grid_to_world(Vector3i(int(grid[0]), int(grid[1]), int(grid[2])))
	var saved_rotation: Array = record.rotation
	rotation_degrees = Vector3(float(saved_rotation[0]), float(saved_rotation[1]), float(saved_rotation[2]))
	var saved_scale: Array = record.scale
	scale = Vector3(float(saved_scale[0]), float(saved_scale[1]), float(saved_scale[2]))
	attachment_points = record.get("attachments", []).duplicate(true)
	component_properties = record.properties.duplicate(true)
