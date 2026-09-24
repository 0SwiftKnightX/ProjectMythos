extends SceneTree

const BlueprintModel := preload("res://scripts/blueprint/blueprint.gd")

const REQUIRED_SCENE_PATHS := {
	"block_1m": "res://parts/blocks/Block_1m.tscn",
	"propeller": "res://parts/propulsion/Propeller.tscn",
}
const PARITY_JSON := "build/blueprint-validation/migrated_blueprint.json"
const PARITY_CANONICAL := "build/blueprint-validation/canonical.txt"
const PARITY_HASH := "build/blueprint-validation/sha256.txt"

func _initialize() -> void:
	var failures := 0
	failures += _validate_blueprint_migration_and_parity()
	failures += _validate_part_registry()
	failures += _validate_negative_fixture()
	if failures == 0:
		print("Blueprint validation passed.")
		quit(0)
	else:
		push_error("Blueprint validation failed with %d error(s)." % failures)
		quit(1)

func _validate_blueprint_migration_and_parity() -> int:
	var failures := 0
	var source_file := FileAccess.open("res://data/blueprints/starter_flyer.json", FileAccess.READ)
	if source_file == null:
		push_error("Missing starter Blueprint fixture")
		return 1
	var source_json := JSON.parse_string(source_file.get_as_text())
	if not source_json is Dictionary:
		push_error("Starter Blueprint is not a dictionary")
		return 1
	if int(source_json.version) != 1:
		push_error("Starter Blueprint must remain the v1 migration fixture")
		failures += 1

	var migrated := BlueprintModel.from_dictionary(source_json)
	if migrated == null:
		push_error("v1 Blueprint failed explicit migration")
		return failures + 1
	if migrated.version != BlueprintModel.CURRENT_VERSION:
		push_error("Migrated Blueprint did not normalize to v2")
		failures += 1
	if migrated.integrity_hash.is_empty():
		push_error("Migrated Blueprint has no integrity hash")
		failures += 1

	var generated_json := _read_json(PARITY_JSON)
	if generated_json == null:
		return failures + 1
	var expected_hash := _read_text(PARITY_HASH).strip_edges()
	var expected_canonical := _read_text(PARITY_CANONICAL)
	if expected_hash.is_empty() or expected_canonical.is_empty():
		push_error("Python parity artifacts are missing")
		return failures + 1

	if migrated.to_dictionary()["integrity_hash"] != expected_hash:
		push_error("Python/Godot SHA-256 mismatch")
		failures += 1
	if migrated.canonical_bytes().get_string_from_utf8() != expected_canonical:
		push_error("Python/Godot canonical bytes mismatch")
		failures += 1
	if migrated.to_dictionary() != generated_json:
		push_error("Python/Godot normalized Blueprint mismatch")
		failures += 1

	var v2 := generated_json.duplicate(true)
	var v2_model := BlueprintModel.from_dictionary(v2)
	if v2_model == null:
		push_error("Generated v2 Blueprint failed direct validation")
		failures += 1

	return failures

func _validate_part_registry() -> int:
	var failures := 0
	for part_id in REQUIRED_SCENE_PATHS.keys():
		if not PartRegistry.has_part(part_id):
			push_error("Registry missing has_part() entry: %s" % part_id)
			failures += 1
		if not PartRegistry.is_valid_part_id(part_id):
			push_error("Registry rejected valid part ID: %s" % part_id)
			failures += 1
		var expected_path := str(REQUIRED_SCENE_PATHS[part_id])
		if not ResourceLoader.exists(expected_path, "PackedScene"):
			push_error("Registered scene path is missing: %s" % expected_path)
			failures += 1
		var scene = PartRegistry.PART_SCENES[part_id]
		if scene == null or not (scene is PackedScene):
			push_error("Registry scene is not a PackedScene: %s" % part_id)
			failures += 1
			continue
		var part := PartRegistry.create_part(part_id, {"validation": true})
		if part == null or not part is ConstructionPart:
			push_error("Registry failed to instantiate ConstructionPart: %s" % part_id)
			failures += 1
			continue
		if part.part_id != part_id or not bool(part.component_properties.get("validation", false)):
			push_error("Registry create_part() configuration changed: %s" % part_id)
			failures += 1
		part.free()

	var missing_id := "__missing_part_for_validation__"
	if PartRegistry.has_part(missing_id) or PartRegistry.is_valid_part_id(missing_id) or PartRegistry.create_part(missing_id) != null:
		push_error("Registry accepted an unknown part ID")
		failures += 1
	return failures

func _validate_negative_fixture() -> int:
	var fixture_file := FileAccess.open("res://tests/fixtures/missing_part_scene.json", FileAccess.READ)
	if fixture_file == null:
		push_error("Missing isolated negative fixture")
		return 1
	var fixture := JSON.parse_string(fixture_file.get_as_text())
	if not fixture is Dictionary or not fixture.has_all(["part_id", "scene_path"]):
		push_error("Invalid isolated negative fixture")
		return 1
	var path := str(fixture.scene_path)
	if ResourceLoader.exists(path, "PackedScene"):
		push_error("Negative fixture scene unexpectedly exists: %s" % path)
		return 1
	if PartRegistry.has_part(str(fixture.part_id)):
		push_error("Negative fixture contaminated the production registry: %s" % fixture.part_id)
		return 1
	return 0

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _read_json(path: String):
	var text := _read_text(path)
	if text.is_empty():
		push_error("Missing JSON artifact: %s" % path)
		return null
	var parsed := JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("Invalid JSON artifact: %s" % path)
		return null
	return parsed
