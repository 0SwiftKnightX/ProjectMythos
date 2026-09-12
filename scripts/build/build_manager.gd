class_name BuildManager
extends Node3D

signal blueprint_saved(blueprint: Blueprint)

@export var construction_root: Node3D
var active_blueprint: Blueprint
var selected_part: ConstructionPart
var selected_part_type := "block_1m"
var _builder := BlueprintBuilder.new()

func new_blueprint(name := "Untitled Vehicle") -> void:
	_clear_parts()
	active_blueprint = BlueprintManager.create_blueprint(name)

func load_blueprint(blueprint_id: String) -> bool:
	var blueprint := BlueprintManager.load_blueprint(blueprint_id)
	if blueprint == null:
		return false
	_clear_parts()
	active_blueprint = blueprint
	_builder.build_editable(active_blueprint, construction_root)
	return true

func select_part_type(part_id: String) -> void:
	if PartRegistry.has_part(part_id):
		selected_part_type = part_id

func place_part(world_position: Vector3) -> ConstructionPart:
	if active_blueprint == null:
		new_blueprint()
	var part := PartRegistry.create_part(selected_part_type)
	if part == null:
		return null
	construction_root.add_child(part)
	part.position = _snap_to_attachment(part, GridSnapSystem.snap_world_position(world_position))
	selected_part = part
	return part

func move_selected(world_position: Vector3) -> void:
	if selected_part != null:
		selected_part.position = _snap_to_attachment(selected_part, GridSnapSystem.snap_world_position(world_position))

func rotate_selected(direction: int) -> void:
	if selected_part != null:
		selected_part.rotation_degrees.y = fmod(selected_part.rotation_degrees.y + 90.0 * direction, 360.0)

func delete_selected() -> void:
	if selected_part != null:
		selected_part.queue_free()
		selected_part = null

func duplicate_selected() -> ConstructionPart:
	if selected_part == null:
		return null
	var duplicate := PartRegistry.create_part(selected_part.part_id, selected_part.component_properties)
	construction_root.add_child(duplicate)
	duplicate.position = GridSnapSystem.snap_world_position(selected_part.position + Vector3(1.0, 0.0, 0.0))
	duplicate.rotation = selected_part.rotation
	selected_part = duplicate
	return duplicate

func save_active_blueprint() -> Error:
	if active_blueprint == null:
		return ERR_DOES_NOT_EXIST
	active_blueprint.parts.clear()
	var order := 1
	for child in construction_root.get_children():
		if child is ConstructionPart and not child.is_queued_for_deletion():
			active_blueprint.append_part(child.to_record(order))
			order += 1
	var result := BlueprintManager.save_blueprint(active_blueprint)
	if result == OK:
		blueprint_saved.emit(active_blueprint)
	return result

func test_current_vehicle() -> PhysicsVehicle:
	if save_active_blueprint() != OK:
		return null
	return _builder.build_runtime(active_blueprint, get_tree().current_scene, Transform3D(Basis.IDENTITY, global_position + Vector3(0.0, 2.0, -5.0)))

func _clear_parts() -> void:
	for child in construction_root.get_children():
		child.queue_free()
	selected_part = null

func _snap_to_attachment(part: ConstructionPart, requested_position: Vector3) -> Vector3:
	# Scenes provide these points, so compatible new part types need no Blueprint changes.
	var best_position := requested_position
	var best_distance := 0.2
	for candidate in construction_root.get_children():
		if candidate == part or not candidate is ConstructionPart:
			continue
		for own_point in part.attachment_points:
			for other_point in candidate.attachment_points:
				var own_values: Array = own_point.get("position", [0, 0, 0])
				var other_values: Array = other_point.get("position", [0, 0, 0])
				var own_offset := Vector3(own_values[0], own_values[1], own_values[2])
				var other_position := candidate.position + Vector3(other_values[0], other_values[1], other_values[2])
				var snapped_position := other_position - own_offset
				var distance := requested_position.distance_to(snapped_position)
				if distance < best_distance:
					best_distance = distance
					best_position = GridSnapSystem.snap_world_position(snapped_position)
	return best_position
