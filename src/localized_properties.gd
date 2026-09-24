class_name LocalizedProperties
extends Node

var bindings: Dictionary = {}


func bind(property: StringName, key: String, parameters: Array) -> void:
	bindings[property] = {"key": key, "parameters": parameters.duplicate()}
	refresh()


func refresh() -> void:
	var target := get_parent()
	if target == null:
		return
	for property in bindings:
		var entry: Dictionary = bindings[property]
		var template := I18n.text(entry.key)
		target.set(property, template if entry.parameters.is_empty() else template % entry.parameters)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh()
