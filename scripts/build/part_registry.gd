extends Node

const PART_SCENES := {
	"block_1m": preload("res://parts/blocks/Block_1m.tscn"),
	"propeller": preload("res://parts/propulsion/Propeller.tscn"),
}

func create_part(part_id: String, properties: Dictionary = {}) -> ConstructionPart:
	if not PART_SCENES.has(part_id):
		push_error("Unknown part type: %s" % part_id)
		return null
	var part := PART_SCENES[part_id].instantiate() as ConstructionPart
	part.configure(part_id, properties)
	return part

func has_part(part_id: String) -> bool:
	return PART_SCENES.has(part_id)
