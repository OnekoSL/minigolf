class_name EditorCodec
extends RefCounted

const VERSION := 1
const MAX_ITEMS := 8192
const MAX_BYTES := 16777216
const THEMES := ["stadtpark", "duenenkueste", "muehlental", "bergpass", "schlossgarten", "uhrwerkfabrik", "tempelruinen", "sternwarte", "zirkus", "baustelle", "urban_winter"]
const SCRIPTS := {
	"hole": preload("res://src/hole_definition.gd"),
	"outline": preload("res://src/lane_outline_definition.gd"),
	"wall": preload("res://src/wall_definition.gd"),
	"tile": preload("res://src/wall_tile_definition.gd"),
	"surface": preload("res://src/surface_definition.gd"),
	"arrow": preload("res://src/arrow_tile_definition.gd"),
	"obstacle": preload("res://src/obstacle_definition.gd"),
	"trigger": preload("res://src/trigger_definition.gd"),
	"cannon": preload("res://src/cannon_definition.gd"),
	"tunnel": preload("res://src/tunnel_definition.gd"),
	"pipe": preload("res://src/pipe_system_definition.gd"),
	"course": preload("res://src/course_definition.gd"),
}

var error := ""
var _remaining := 100000


static func new_id(prefix := "custom_") -> String:
	return prefix + Crypto.new().generate_random_bytes(16).hex_encode()


static func fields(resource: Resource) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for property in resource.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_EDITOR:
			result.append(property)
	return result


static func encode(value: Variant) -> Variant:
	if value is CourseTheme:
		return {"theme": String(value.theme_id)}
	if value is Resource:
		var kind := ""
		for candidate in SCRIPTS:
			if value.get_script() == SCRIPTS[candidate]:
				kind = candidate
		var data := {}
		for property in fields(value):
			data[property.name] = encode(value.get(property.name))
		return {"kind": kind, "eid": String(value.get_meta("editor_id", "")), "fields": data}
	if value is Vector2 or value is Vector2i:
		return [value.x, value.y]
	if value is Rect2:
		return [value.position.x, value.position.y, value.size.x, value.size.y]
	if value is Array or value is PackedVector2Array or value is PackedInt32Array or value is PackedStringArray:
		var result := []
		for item in value:
			result.append(encode(item))
		return result
	if value is StringName:
		return String(value)
	return value


func decode(data: Variant, expected_kind := "") -> Resource:
	error = ""
	_remaining = 100000
	var result := _resource(data, 0)
	if result != null and not expected_kind.is_empty() and result.get_script() != SCRIPTS.get(expected_kind):
		error = I18n.text("TEXT_WRONG_DOCUMENT_TYPE")
	return result if error.is_empty() else null


func _resource(data: Variant, depth: int) -> Resource:
	_remaining -= 1
	if depth > 20 or _remaining < 0 or not data is Dictionary:
		return _fail(I18n.text("TEXT_INVALID_OR_EXCESSIVELY_NESTED_DATA"))
	if data.has("theme"):
		if data.theme is String and data.theme in THEMES:
			return load("res://data/themes/%s.tres" % data.theme)
		return _fail(I18n.text("TEXT_UNKNOWN_THEME"))
	if not data.get("kind") is String or not SCRIPTS.has(data.kind) or not data.get("fields") is Dictionary:
		return _fail(I18n.text("TEXT_UNKNOWN_COMPONENT_TYPE"))
	var resource: Resource = SCRIPTS[data.kind].new()
	var known := {}
	for property in fields(resource):
		known[property.name] = property
	for key in data.fields:
		if not known.has(key):
			return _fail(I18n.text("TEXT_UNKNOWN_PROPERTY") % key)
		var decoded: Variant = _value(data.fields[key], resource.get(key), known[key], depth + 1)
		if not error.is_empty():
			return null
		resource.set(key, decoded)
	var eid: Variant = data.get("eid", "")
	if not eid is String or eid.length() > 128:
		return _fail(I18n.text("TEXT_INVALID_ELEMENT_ID"))
	if not eid.is_empty():
		resource.set_meta("editor_id", eid)
	if resource is LaneOutlineDefinition:
		if resource.points.size() > 512:
			return _fail(I18n.text("TEXT_TOO_MANY_OUTLINE_POINTS"))
		for point in resource.points:
			if absf(point.x) > 16384 or absf(point.y) > 16384:
				return _fail(I18n.text("TEXT_OUTLINE_OUTSIDE_THE_WORK_AREA"))
	if resource is WallDefinition and (resource.arc_segments < 4 or resource.arc_segments > 128 or resource.radius > 4096):
		return _fail(I18n.text("TEXT_UNSUPPORTED_ARC_SIZE_OR_SEGMENT_COUNT"))
	if resource is HoleDefinition and (resource.course_rect.size.x > 8192 or resource.course_rect.size.y > 8192):
		return _fail(I18n.text("TEXT_HOLE_EXCEEDS_8192_8192_PIXELS"))
	return resource


func _value(raw: Variant, sample: Variant, property: Dictionary, depth: int) -> Variant:
	_remaining -= 1
	if depth > 20 or _remaining < 0:
		return _fail(I18n.text("TEXT_FILE_CONTAINS_TOO_MUCH_DATA"))
	match int(property.type):
		TYPE_BOOL:
			if raw is bool:
				return raw
		TYPE_STRING, TYPE_STRING_NAME:
			if raw is String and raw.length() <= 4096:
				return StringName(raw) if property.type == TYPE_STRING_NAME else raw
		TYPE_INT, TYPE_FLOAT:
			if _number(raw):
				if property.type == TYPE_INT:
					if float(raw) != floorf(float(raw)):
						return _fail(I18n.text("TEXT_INTEGER_EXPECTED") % property.name)
					if property.hint == PROPERTY_HINT_ENUM:
						var choices := String(property.hint_string).split(",")
						var allowed: Array[int] = []
						for index in range(choices.size()):
							allowed.append(int(choices[index].get_slice(":", 1)) if ":" in choices[index] else index)
						if int(raw) not in allowed:
							return _fail(I18n.text("TEXT_UNKNOWN_SELECTION") % property.name)
					return int(raw)
				return float(raw)
		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_RECT2:
			var count := 4 if property.type == TYPE_RECT2 else 2
			if raw is Array and raw.size() == count:
				for item in raw:
					if not _number(item):
						return _fail(I18n.text("TEXT_INVALID_COORDINATE"))
				if property.type == TYPE_RECT2:
					return Rect2(raw[0], raw[1], raw[2], raw[3])
				if property.type == TYPE_VECTOR2I:
					if raw[0] != floorf(raw[0]) or raw[1] != floorf(raw[1]):
						return _fail(I18n.text("TEXT_GRID_COORDINATES_MUST_BE_INTEGERS"))
					return Vector2i(raw[0], raw[1])
				return Vector2(raw[0], raw[1])
		TYPE_OBJECT:
			if raw == null:
				return null
			var resource := _resource(raw, depth)
			if resource != null:
				var expected: String = property.get("class_name", "")
				if expected.is_empty():
					expected = property.get("hint_string", "")
				if not _matches_class(resource, expected):
					return _fail(I18n.text("TEXT_WRONG_RESOURCE_TYPE") % property.name)
			return resource
		TYPE_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_STRING_ARRAY:
			if not raw is Array or raw.size() > MAX_ITEMS:
				return _fail(I18n.text("TEXT_INVALID_OR_OVERSIZED_LIST"))
			var output: Variant = sample.duplicate()
			output.clear()
			var element_type := TYPE_VECTOR2 if property.type == TYPE_PACKED_VECTOR2_ARRAY else TYPE_INT
			if property.type == TYPE_PACKED_STRING_ARRAY:
				element_type = TYPE_STRING
			if property.type == TYPE_ARRAY:
				element_type = sample.get_typed_builtin()
			for item in raw:
				var decoded: Variant = _value(item, null, {"type": element_type, "name": property.name, "hint": PROPERTY_HINT_NONE}, depth + 1)
				if not error.is_empty():
					return null
				if element_type == TYPE_OBJECT:
					if decoded == null or decoded.get_script() != sample.get_typed_script():
						return _fail(I18n.text("TEXT_WRONG_ELEMENT_IN") % property.name)
				output.append(decoded)
			return output
	return _fail(I18n.text("TEXT_INVALID_VALUE") % property.name)


func _matches_class(resource: Resource, expected: String) -> bool:
	return expected.is_empty() or expected == "Resource" or resource.get_script().get_global_name() == expected


func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value)) <= 1000000.0


func _fail(message: String) -> Variant:
	error = message
	return null


static func gameplay_hash(hole: HoleDefinition) -> String:
	var data: Dictionary = encode(hole)
	for key in ["display_name", "hole_id", "category", "theme", "garden_presentation", "camera_center_bounds"]:
		data.fields.erase(key)
	_strip_editor_ids(data)
	return JSON.stringify(data, "", true, true).sha256_text()


static func _strip_editor_ids(value: Variant) -> void:
	if value is Dictionary:
		value.erase("eid")
		for child in value.values():
			_strip_editor_ids(child)
	elif value is Array:
		for child in value:
			_strip_editor_ids(child)
