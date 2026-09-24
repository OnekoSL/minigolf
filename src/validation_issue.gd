class_name ValidationIssue
extends RefCounted

var key: String
var parameters: Array
var element_id: String


func _init(message_key: String, args: Array, target: Resource = null, marker := "") -> void:
	key = message_key
	parameters = args.duplicate()
	element_id = marker if not marker.is_empty() else (String(target.get_meta("editor_id", "")) if target != null else "")


func message() -> String:
	var template := I18n.text(key)
	return template % parameters if not parameters.is_empty() else template
