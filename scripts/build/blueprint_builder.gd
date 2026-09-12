class_name BlueprintBuilder
extends RefCounted

func build_editable(blueprint: Blueprint, parent: Node3D) -> Array[ConstructionPart]:
	var parts: Array[ConstructionPart] = []
	for record in blueprint.parts:
		var part := PartRegistry.create_part(str(record.part_id), record.properties)
		if part == null:
			continue
		parent.add_child(part)
		part.apply_record(record)
		parts.append(part)
	return parts

func build_runtime(blueprint: Blueprint, parent: Node, spawn_transform: Transform3D) -> PhysicsVehicle:
	var vehicle := preload("res://scenes/vehicles/RuntimeVehicle.tscn").instantiate() as PhysicsVehicle
	parent.add_child(vehicle)
	vehicle.global_transform = spawn_transform
	for record in blueprint.parts:
		var part := PartRegistry.create_part(str(record.part_id), record.properties)
		if part == null:
			continue
		vehicle.add_construction_part(part, record)
	return vehicle
