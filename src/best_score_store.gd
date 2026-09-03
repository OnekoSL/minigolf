class_name BestScoreStore
extends RefCounted

const DEFAULT_PATH := "user://progress.cfg"

var storage_path := DEFAULT_PATH


func _init(path := DEFAULT_PATH) -> void:
	storage_path = path


func get_best(course_id: StringName) -> int:
	var config := ConfigFile.new()
	if config.load(storage_path) != OK:
		return -1
	var value = config.get_value("course_best", String(course_id), -1)
	return int(value) if value is int or value is float else -1


func submit(course_id: StringName, strokes: int) -> int:
	var previous := get_best(course_id)
	if previous >= 0 and strokes >= previous:
		return previous
	var config := ConfigFile.new()
	config.load(storage_path)
	config.set_value("course_best", String(course_id), strokes)
	var error := config.save(storage_path)
	if error != OK:
		push_warning("Bestwert konnte nicht gespeichert werden: %s" % error_string(error))
		return previous
	return strokes
