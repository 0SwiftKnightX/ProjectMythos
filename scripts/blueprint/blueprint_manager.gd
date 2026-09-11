extends Node

const BlueprintModel := preload("res://scripts/blueprint/blueprint.gd")
const SAVE_DIRECTORY := "user://blueprints"
const PREBUILT_DIRECTORY := "res://data/blueprints"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIRECTORY))

func create_blueprint(name: String) -> Blueprint:
	return BlueprintModel.new("bp_%s_%s" % [Time.get_unix_time_from_system(), randi()], name)

func save_blueprint(blueprint: Blueprint) -> Error:
	if blueprint == null or blueprint.id.is_empty():
		return ERR_INVALID_PARAMETER
	var file := FileAccess.open(_user_path(blueprint.id), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(blueprint.to_dictionary(), "\t"))
	return OK

func load_blueprint(blueprint_id: String) -> Blueprint:
	var user_blueprint := _read_blueprint(_user_path(blueprint_id))
	return user_blueprint if user_blueprint != null else _read_blueprint("%s/%s.json" % [PREBUILT_DIRECTORY, blueprint_id])

func list_blueprints() -> Array[Blueprint]:
	var result: Array[Blueprint] = []
	for directory in [PREBUILT_DIRECTORY, SAVE_DIRECTORY]:
		var dir := DirAccess.open(directory)
		if dir == null:
			continue
		for filename in dir.get_files():
			if filename.ends_with(".json"):
				var blueprint := _read_blueprint("%s/%s" % [directory, filename])
				if blueprint != null:
					result.append(blueprint)
	return result

func delete_blueprint(blueprint_id: String) -> Error:
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(_user_path(blueprint_id)))

func duplicate_blueprint(blueprint_id: String, new_name: String) -> Blueprint:
	var source := load_blueprint(blueprint_id)
	if source == null:
		return null
	var duplicate := create_blueprint(new_name)
	duplicate.parts = source.parts.duplicate(true)
	for index in duplicate.parts.size():
		duplicate.parts[index]["order"] = index + 1
	return duplicate

func _user_path(blueprint_id: String) -> String:
	return "%s/%s.json" % [SAVE_DIRECTORY, blueprint_id]

func _read_blueprint(path: String) -> Blueprint:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Unable to parse blueprint: %s" % path)
		return null
	return BlueprintModel.from_dictionary(json.data) if json.data is Dictionary else null
