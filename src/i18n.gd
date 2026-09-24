class_name I18n
extends RefCounted


static func text(key: String) -> String:
	return TranslationServer.translate(key)


# Only for fixed engine enum labels / UI constant arrays, never user text.
static func source(value: String) -> String:
	return text(I18nSourceKeys.KEYS.get(value, value))


static func content_name(content: Resource) -> String:
	if content == null:
		return ""
	var id := String(content.get("course_id") if content is CourseDefinition else content.get("hole_id"))
	if id.begins_with("custom_"):
		return content.display_name
	var key := ("COURSE_" if content is CourseDefinition else "HOLE_") + id.to_upper()
	var translated := text(key)
	return content.display_name if translated == key else translated


static func golfer_description(golfer: Resource) -> String:
	return text("GOLFER_" + String(golfer.golfer_id).to_upper() + "_DESCRIPTION")


static func bind(target: Node, property: StringName, key: String, parameters: Array = []) -> void:
	var bindings := target.get_node_or_null("LocalizedProperties") as LocalizedProperties
	if bindings == null:
		bindings = LocalizedProperties.new()
		bindings.name = "LocalizedProperties"
		target.add_child(bindings)
	bindings.bind(property, key, parameters)
