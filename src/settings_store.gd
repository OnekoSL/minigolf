class_name SettingsStore
extends RefCounted

var storage_path := "user://settings.cfg"
var load_error: Error = OK


func _init(path := "user://settings.cfg") -> void:
	storage_path = path


func read() -> GameSettings:
	var result := GameSettings.new()
	var config := ConfigFile.new()
	load_error = config.load(storage_path)
	if load_error == ERR_FILE_NOT_FOUND:
		load_error = OK
	if load_error == OK:
		for key in GameSettings.KEYS:
			result.set_checked(key, config.get_value("settings", key, result.get(key)))
	return result


func write(value: GameSettings) -> Error:
	# Never replace an unreadable existing file, even if it changed since startup.
	var config := ConfigFile.new()
	var error := config.load(storage_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		return error
	for key in GameSettings.KEYS:
		config.set_value("settings", key, value.get(key))
	var temporary := storage_path + ".tmp"
	error = config.save(temporary)
	if error != OK:
		return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(storage_path))
