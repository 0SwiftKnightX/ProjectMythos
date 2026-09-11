class_name PhysicsVehicle
extends RigidBody3D

@export var thrust_multiplier := 18.0
var construction_parts: Array[ConstructionPart] = []

func add_construction_part(part: ConstructionPart, record: Dictionary) -> void:
	add_child(part)
	part.apply_record(record)
	construction_parts.append(part)

func _integrate_forces(_state: PhysicsDirectBodyState3D) -> void:
	for part in construction_parts:
		if part.part_id != "propeller":
			continue
		var power := float(part.component_properties.get("power", 1.0))
		# -Z is the authored forward/thrust axis for every propeller scene.
		var force := part.global_transform.basis * Vector3(0.0, 0.0, -power * thrust_multiplier)
		apply_force(force, part.global_position - global_position)
