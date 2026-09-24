class_name Blueprint
extends RefCounted

const CURRENT_VERSION := 2
const LEGACY_VERSION := 1
const REQUIRED_ROOT_FIELDS := ["id", "name", "version", "parts"]
const REQUIRED_RECORD_FIELDS := ["order", "part_id", "construction_id", "position", "rotation", "scale", "properties"]

var id: String
var display_name: String
var version: int = CURRENT_VERSION
var parts: Array[Dictionary] = []
var is_prebuilt := false
var integrity_hash := ""

func _init__(blueprint_id := "", blueprint_name := "Untitled") -> void:
	id = blueprint_id if not blueprint_id.is_empty() else "%s_%s" % [Time.get_unix_time_from_system(), randi()]
	display_name = blueprint_name

func append_part(record: Dictionary) -> void:
	var copy := record.duplicate(true)
	copy["order"] = parts.size() + 1
	parts.append(copy)
	integrity_hash = ""

func to_dictionary() -> Dictionary:
	version = CURRENT_VERSION
	integrity_hash = calculate_integrity_hash()
	return {
		"id": id,
		"name": display_name,
		"version": version,
		"is_prebuilt": is_prebuilt,
		"parts": parts,
		"integrity_hash": integrity_hash
	}

func canonical_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"version": version,
		"is_prebuilt": is_prebuilt,
		"parts": parts
	}

func canonical_bytes() -> PackedByteArray:
	var canonical := _canonical_encode(canonical_dictionary())
	if canonical.is_empty():
		return PackedByteArray()
	return canonical.to_utf8_buffer()

func calculate_integrity_hash() -> String:
	var bytes := canonical_bytes()
	if bytes.is_empty():
		return ""
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()

static func from_dictionary(value: Dictionary) -> Blueprint:
	if not value.has_all(REQUIRED_ROOT_FIELDS):
		push_error("Blueprint is missing required fields")
		return null
	if typeof(value.version) != TYPE_INT:
		push_error("Blueprint version must be an integer")
		return null

	var source_version := int(value.version)
	if source_version < LEGACY_VERSION or source_version > CURRENT_VERSION:
		push_error("Unsupported Blueprint format version: %s" % source_version)
		return null

	var normalized := value.duplicate(true)
	if source_version == LEGACY_VERSION:
		normalized = _migrate_v1(normalized)
		if normalized == null:
			return null

	if not _validate_normalized(normalized):
		return null

	var blueprint := Blueprint.new(str(normalized.id), str(normalized.name))
	blueprint.version = CURRENT_VERSION
	blueprint.is_prebuilt = bool(normalized.get("is_prebuilt", false))
	blueprint.parts = normalized.parts.duplicate(true)

	var calculated_hash := blueprint.calculate_integrity_hash()
	if source_version == CURRENT_VERSION:
		var stored_hash := str(normalized.get("integrity_hash", ""))
		if stored_hash.is_empty() or stored_hash.to_lower() != calculated_hash:
			push_error("Blueprint integrity hash mismatch")
			return null
	blueprint.integrity_hash = stored_hash.to_lower()
	else:
		# v1 remains unchanged on disk; migration only normalizes the in-memory model.
		blueprint.integrity_hash = calculated_hash

	return blueprint

static func _migrate_v1(value: Dictionary) -> Dictionary:
	var migrated := value.duplicate(true)
	migrated["version"] = CURRENT_VERSION
	for index in migrated.parts.size():
		var record = migrated.parts[index]
		if not record is Dictionary:
			push_error("Blueprint v1 contains an invalid construction record")
			return null
		if not record.has("attachments"):
			record["attachments"] = []
		migrated.parts[index] = record
	return migrated

static func _validate_normalized(value: Dictionary) -> bool:
	if not value.has_all(REQUIRED_ROOT_FIELDS):
		push_error("Normalized Blueprint is missing required fields")
		return false
	if typeof(value.id) != TYPE_STRING or str(value.id).is_empty():
		push_error("Blueprint id must be a non-empty string")
		return false
	if typeof(value.name) != TYPE_STRING:
		push_error("Blueprint name must be a string")
		return false
	if typeof(value.version) != TYPE_INT or int(value.version) != CURRENT_VERSION:
		push_error("Normalized Blueprint must be version %s" % CURRENT_VERSION)
		return false
	if typeof(value.get("is_prebuilt", false)) != TYPE_BOOL:
		push_error("Blueprint is_prebuilt must be a boolean")
		return false
	if typeof(value.parts) != TYPE_ARRAY:
		push_error("Blueprint parts must be an array")
		return false

	var seen_orders := {}
	var seen_construction_ids := {}
	for record in value.parts:
		if not record is Dictionary or not record.has_all(REQUIRED_RECORD_FIELDS):
			push_error("Blueprint contains an invalid construction record")
			return false
		if not _validate_record(record, seen_orders, seen_construction_ids):
			return false
	return true

static func _validate_record(record: Dictionary, seen_orders: Dictionary, seen_construction_ids: Dictionary) -> bool:
	if typeof(record.order) != TYPE_INT or int(record.order) <= 0:
		push_error("Blueprint construction order must be a positive integer")
		return false
	if seen_orders.has(record.order):
		push_error("Blueprint construction order must be unique")
		return false
	seen_orders[record.order] = true

	if typeof(record.part_id) != TYPE_STRING or str(record.part_id).is_empty():
		push_error("Blueprint part_id must be a non-empty string")
		return false
	if typeof(record.construction_id) != TYPE_STRING or str(record.construction_id).is_empty():
		push_error("Blueprint construction_id must be a non-empty string")
		return false
	if seen_construction_ids.has(record.construction_id):
		push_error("Blueprint construction_id must be unique")
		return false
	seen_construction_ids[record.construction_id] = true

	if not _validate_numeric_array(record.position, 3, true):
		push_error("Blueprint position must contain exactly three integers")
		return false
	if not _validate_numeric_array(record.rotation, 3, false):
		push_error("Blueprint rotation must contain exactly three finite numbers")
		return false
	if not _validate_numeric_array(record.scale, 3, false):
		push_error("Blueprint scale must contain exactly three finite numbers")
		return false
	if record.has("attachments") and not _validate_metadata(record.attachments):
		push_error("Blueprint attachments contain an unsupported metadata type")
		return false
	if not _validate_metadata(record.properties):
		push_error("Blueprint properties contain an unsupported metadata type")
		return false
	return true

static func _validate_numeric_array(value: Variant, expected_size: int, integers_only: bool) -> bool:
	if typeof(value) != TYPE_ARRAY or value.size() != expected_size:
		return false
	for item in value:
		if integers_only:
			if typeof(item) != TYPE_INT:
				return false
		else:
			if typeof(item) != TYPE_INT and typeof(item) != TYPE_FLOAT:
				return false
			if typeof(item) == TYPE_FLOAT and not is_finite(float(item)):
				return false
	return true

static func _validate_metadata(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(float(value))
		TYPE_ARRAY:
			for item in value:
				if not _validate_metadata(item):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value.keys():
				if typeof(key) != TYPE_STRING or not _validate_metadata(value[key]):
					return false
			return true
		_:
			return false

static func _canonical_encode(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "n"
		TYPE_BOOL:
			return "b:true" if value else "b:false"
		TYPE_INT:
			return "i:%d" % int(value)
		TYPE_FLOAT:
			if not is_finite(float(value)):
				push_error("Cannot canonicalize non-finite float")
				return ""
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_double(0, float(value))
			return "f:" + bytes.hex_encode()
		TYPE_STRING:
			var string_bytes: PackedByteArray = value.to_utf8_buffer()
			return "s:%d:%s" % [string_bytes.size(), string_bytes.hex_encode()]
		TYPE_ARRAY:
			var array_parts: Array[String] = []
			for item in value:
				var encoded_item := _canonical_encode(item)
				if encoded_item.is_empty():
					return ""
				array_parts.append(encoded_item)
			return "a:%d:%s" % [array_parts.size(), ";".join(array_parts)]
		TYPE_DICTIONARY:
			var entries: Array = []
			for key in value.keys():
				if typeof(key) != TYPE_STRING:
					push_error("Canonical dictionaries require string keys")
					return ""
				var encoded_key := _canonical_encode(key)
				var encoded_value := _canonical_encode(value[key])
				if encoded_key.is_empty() or encoded_value.is_empty():
					return ""
				entries.append([encoded_key, encoded_value])
			entries.sort_custom(func(a, b): return a[0] < b[0])
			var dictionary_parts: Array[String] = []
			for entry in entries:
				dictionary_parts.append("%s=%s" % [entry[0], entry[1]])
			return "d:%d:%s" % [dictionary_parts.size(), ";".join(dictionary_parts)]
		_:
			push_error("Unsupported Blueprint metadata type: %s" % typeof(value))
			return ""
