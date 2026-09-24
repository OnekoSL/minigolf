class_name GameSettings
extends RefCounted

const LANGUAGES := ["de", "en", "fr", "es", "it"]
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const KEYS := ["language", "master_volume", "effects_volume", "fullscreen", "window_size", "vsync", "camera_shake"]

var language := "de"
var master_volume := 100
var effects_volume := 100
var fullscreen := false
var window_size := 2
var vsync := true
var camera_shake := true


func copy() -> GameSettings:
	var result := GameSettings.new()
	for key in KEYS:
		result.set(key, get(key))
	return result


func set_checked(key: String, value: Variant) -> void:
	match key:
		"language":
			if value is String and value in LANGUAGES:
				language = value
		"master_volume", "effects_volume":
			if value is int and value >= 0 and value <= 100 and value % 5 == 0:
				set(key, value)
		"window_size":
			if value is int and value >= 0 and value < WINDOW_SIZES.size():
				window_size = value
		"fullscreen", "vsync", "camera_shake":
			if value is bool:
				set(key, value)


func same_display(other: GameSettings) -> bool:
	return fullscreen == other.fullscreen and window_size == other.window_size and vsync == other.vsync
