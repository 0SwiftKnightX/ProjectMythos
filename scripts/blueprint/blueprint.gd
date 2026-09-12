class_name Blueprint
extends RefCounted

const CURRENT_VERSION := 1

var id: String
var display_name: String
var version: int = CURRENT_VERSION
var parts: Array[Dictionary] = []
var is_prebuilt := false

func _init(blueprint_id := "", blueprint_name := "Untitled") -> void:
	id = blueprint_id if not blueprint_id.is_empty() else "%s_%s" % [Time.get_unix_time_from_system(), randi()]
	display_name = blueprint_name

func append_part(record: Dictionary) -> void:
	var copy := record.duplicate(true)
	copy["order"] = parts.size() + 1
	parts.append(copy)

func to_dictionary() -> Dictionary:
	return {"id": id, "name": display_name, "version": version, "is_prebuilt": is_prebuilt, "parts": parts}

static func from_dictionary(value: Dictionary) -> Blueprint:
	if not value.has_all(["id", "name", "version", "parts"]):
		push_error("Blueprint is missing required fields")
		return null
	var blueprint := Blueprint.new(str(value.id), str(value.name))
	blueprint.version = int(value.version)
	blueprint.is_prebuilt = bool(value.get("is_prebuilt", false))
	if blueprint.version > CURRENT_VERSION:
		push_error("Blueprint format is newer than this game supports")
		return null
	for record in value.parts:
		if not record is Dictionary or not record.has_all(["order", "part_id", "construction_id", "position", "rotation", "scale", "properties"]):
			push_error("Blueprint contains an invalid construction record")
			return null
		blueprint.parts.append(record.duplicate(true))
	blueprint.parts.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.order) < int(b.order))
	return blueprint
