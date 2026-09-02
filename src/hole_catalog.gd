class_name HoleCatalog
extends Resource

const DEFAULT_CATALOG_PATH := "res://data/holes/hole_catalog.tres"

@export var holes: Array[HoleDefinition] = []


static func load_default() -> HoleCatalog:
	return load(DEFAULT_CATALOG_PATH) as HoleCatalog


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	if holes.is_empty():
		errors.append("Lochkatalog ist leer")
	for definition in holes:
		if definition == null:
			errors.append("Lochkatalog enthaelt einen leeren Eintrag")
			continue
		errors.append_array(definition.validate())
		if ids.has(definition.hole_id):
			errors.append("Doppelte Bahn-ID: %s" % definition.hole_id)
		ids[definition.hole_id] = true
	return errors


func get_hole(hole_id: StringName) -> HoleDefinition:
	for definition in holes:
		if definition != null and definition.hole_id == hole_id:
			return definition
	return null
