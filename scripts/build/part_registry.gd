extends Node

const PART_SCENES := {
	"block_1m": preload("res://parts/blocks/Block_1m.tscn"),
	"propeller": preload("res://parts/propulsion/Propeller.tscn"),
}

func create_part(part_id: String, properties: Dictionary = {}) -> ConstructionPart:
	if not is_valid_part_id(part_id):
		push_error("Unknown part type: %s" % part_id)
		return null
	var scene = PART_SCENES[part_id]
	if scene == null or not scene is PackedScene:
		push_error("Invalid scene configuration for part type: %s" % part_id)
		return null
	var part := scene.instantiate()
	if not part is ConstructionPart:
		push_error("Registered scene does not instantiate ConstructionPart: %s" % part_id)
		return null
	var construction_part := part as ConstructionPart
	construction_part.configure(part_id, properties)
	return construction_part

func has_part(part_id: String) -> bool:
	return PART_SCENES.has(part_id)

func is_valid_part_id(part_id: String) -> bool:
	return has_part(part_id)
