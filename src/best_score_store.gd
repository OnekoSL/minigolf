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


func submit(course_id: StringName, strokes: int) -> BestScoreResult:
	if course_id == &"" or strokes < 0:
		return BestScoreResult.new(-1, false, ERR_INVALID_PARAMETER)
	var config := ConfigFile.new()
	var load_error := config.load(storage_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return BestScoreResult.new(-1, false, load_error)
	var value = config.get_value("course_best", String(course_id), -1)
	var previous := int(value) if value is int or value is float else -1
	if previous >= 0 and strokes >= previous:
		return BestScoreResult.new(previous)
	config.set_value("course_best", String(course_id), strokes)
	var error := config.save(storage_path)
	if error != OK:
		return BestScoreResult.new(previous, false, error)
	return BestScoreResult.new(strokes, true)
