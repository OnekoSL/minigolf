class_name PracticeProgress
extends RefCounted

var storage_path := "user://practice.cfg"
var completed: Array[String] = []
var error: Error = OK
var _config := ConfigFile.new()


func read() -> void:
	completed.clear()
	_config.clear()
	error = _config.load(storage_path)
	if error == ERR_FILE_NOT_FOUND:
		error = OK
		return
	if error != OK:
		return
	if not _config.has_section_key("tutorial", "completed"):
		error = ERR_INVALID_DATA
		return
	var ids: Variant = _config.get_value("tutorial", "completed", PackedStringArray())
	if not ids is PackedStringArray:
		error = ERR_INVALID_DATA
		return
	completed.assign(ids)


func mark_complete(id: StringName) -> void:
	if String(id) not in completed:
		completed.append(String(id))
	# Keep malformed files intact while allowing progress in memory.
	if error != OK:
		return
	_config.set_value("tutorial", "completed", PackedStringArray(completed))
	error = _config.save(storage_path)


func contains(id: StringName) -> bool:
	return String(id) in completed
