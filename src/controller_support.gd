extends Node

signal active_device_changed(id: int, device_name: String, guid: String)
signal mapping_required(id: int, guid: String)
signal focus_changed(has_focus: bool)
signal calibration_updated(prompt: String)
signal calibration_finished(guid: String)

const USER_MAPPING_PATH := "user://controller_mappings.cfg"
const PROJECT_MAPPING_PATH := "res://config/controller_mappings.cfg"
const DEADZONE := 0.20

var active_device_id := -1
var active_device_name := "Kein Controller"
var active_device_guid := ""
var focused := true
var last_input_kind := "Tastatur"

var user_mapping_path := USER_MAPPING_PATH
var _calibration_status := ""
var _profiles: Dictionary = {}
var _last_axes: Dictionary = {}
var _last_buttons: Dictionary = {}
var _calibration_steps := [
	"shot_button",
	"cancel_button",
	"dpad_up",
	"dpad_down",
	"dpad_left",
	"dpad_right",
	"axis_x",
	"axis_y",
]
var _calibration_step := -1
var _calibration_profile: Dictionary = {}
var _device_poll_elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	_load_sdl_mappings()
	_load_user_profiles()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	call_deferred("_refresh_active_device")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		focus_changed.emit(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		focus_changed.emit(true)


func _process(delta: float) -> void:
	_device_poll_elapsed += delta
	if _device_poll_elapsed < 0.5:
		return
	_device_poll_elapsed = 0.0
	var joypads := Input.get_connected_joypads()
	if joypads.is_empty() and active_device_id >= 0:
		_refresh_active_device()
	elif not joypads.is_empty() and (active_device_id < 0 or active_device_id not in joypads):
		_set_active_device(joypads[0])


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		last_input_kind = "Controller"
		_last_buttons[event.button_index] = event.pressed
		if active_device_id < 0:
			_set_active_device(event.device)
		if _calibration_step >= 0 and event.device == active_device_id:
			_capture_calibration_button(event)
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) >= DEADZONE:
			last_input_kind = "Controller"
		_last_axes[event.axis] = event.axis_value
		if active_device_id < 0:
			_set_active_device(event.device)
		if _calibration_step >= 0 and event.device == active_device_id:
			_capture_calibration_axis(event)
	elif event is InputEventMouse:
		last_input_kind = "Maus"
	elif event is InputEventKey and event.pressed:
		last_input_kind = "Tastatur"


func _ensure_input_actions() -> void:
	_add_action("aim_left", [
		_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0), _joy_button(JOY_BUTTON_DPAD_LEFT)
	], DEADZONE)
	_add_action("aim_right", [
		_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0), _joy_button(JOY_BUTTON_DPAD_RIGHT)
	], DEADZONE)
	_add_action("aim_up", [
		_key(KEY_W), _key(KEY_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0), _joy_button(JOY_BUTTON_DPAD_UP)
	], DEADZONE)
	_add_action("aim_down", [
		_key(KEY_S), _key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0), _joy_button(JOY_BUTTON_DPAD_DOWN)
	], DEADZONE)
	_add_action("shot_action", [
		_key(KEY_SPACE), _key(KEY_ENTER), _mouse_button(MOUSE_BUTTON_LEFT), _joy_button(JOY_BUTTON_A)
	])
	_add_action("menu_confirm", [
		_key(KEY_SPACE), _key(KEY_ENTER), _mouse_button(MOUSE_BUTTON_LEFT), _joy_button(JOY_BUTTON_A)
	])
	_add_action("shot_cancel", [
		_key(KEY_ESCAPE), _mouse_button(MOUSE_BUTTON_RIGHT), _joy_button(JOY_BUTTON_B)
	])
	_add_action("menu_back", [
		_key(KEY_ESCAPE), _mouse_button(MOUSE_BUTTON_RIGHT), _joy_button(JOY_BUTTON_B)
	])
	_add_action("restart_hole", [_key(KEY_R), _joy_button(JOY_BUTTON_X)])
	_add_action("switch_test_hole", [_key(KEY_F2), _joy_button(JOY_BUTTON_Y)])
	_add_action("toggle_diagnostics", [_key(KEY_F3)])
	_add_action("start_calibration", [_key(KEY_F4)])
	_add_action("pause", [_key(KEY_P), _joy_button(JOY_BUTTON_START)])


func _add_action(action_name: StringName, events: Array, deadzone := 0.5) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, deadzone)
	else:
		InputMap.action_set_deadzone(action_name, deadzone)
	for event in events:
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


func _mouse_button(index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	return event


func _joy_button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event


func _joy_axis(index: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = index
	event.axis_value = value
	return event


func _load_sdl_mappings() -> void:
	if not FileAccess.file_exists(PROJECT_MAPPING_PATH):
		return
	var file := FileAccess.open(PROJECT_MAPPING_PATH, FileAccess.READ)
	if file == null:
		return
	for line in parse_mapping_lines(file.get_as_text()):
		Input.add_joy_mapping(line, true)


static func parse_mapping_lines(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		result.append(line)
	return result


func _load_user_profiles() -> void:
	var config := ConfigFile.new()
	if config.load(user_mapping_path) != OK:
		return
	for section in config.get_sections():
		var profile: Dictionary = {}
		for key in config.get_section_keys(section):
			profile[key] = config.get_value(section, key)
		_profiles[section] = profile


func _save_user_profile(guid: String, profile: Dictionary) -> Error:
	var config := ConfigFile.new()
	var load_error := config.load(user_mapping_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error
	for key in profile.keys():
		config.set_value(guid, key, profile[key])
	return config.save(user_mapping_path)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		_set_active_device(device)
	elif device == active_device_id:
		_refresh_active_device()


func _refresh_active_device() -> void:
	var joypads := Input.get_connected_joypads()
	if joypads.is_empty():
		active_device_id = -1
		active_device_name = "Kein Controller"
		active_device_guid = ""
		active_device_changed.emit(-1, active_device_name, "")
		return
	_set_active_device(joypads[0])


func _set_active_device(device: int) -> void:
	active_device_id = device
	active_device_name = Input.get_joy_name(device)
	active_device_guid = Input.get_joy_guid(device)
	active_device_changed.emit(device, active_device_name, active_device_guid)


func event_is_pressed(event: InputEvent, action: StringName) -> bool:
	if not focused:
		return false
	if event.is_action_pressed(action, false, true):
		return true
	if event is InputEventJoypadButton and event.pressed:
		return _custom_button_matches(event, action)
	return false


func event_is_released(event: InputEvent, action: StringName) -> bool:
	if not focused:
		return false
	if event.is_action_released(action, true):
		return true
	if event is InputEventJoypadButton and not event.pressed:
		return _custom_button_matches(event, action)
	return false


func _custom_button_matches(event: InputEventJoypadButton, action: StringName) -> bool:
	if event.device != active_device_id or not _profiles.has(active_device_guid):
		return false
	var profile: Dictionary = _profiles[active_device_guid]
	if action in [&"shot_action", &"menu_confirm"]:
		return event.button_index == int(profile.get("shot_button", -999))
	if action in [&"shot_cancel", &"menu_back"]:
		return event.button_index == int(profile.get("cancel_button", -999))
	return false


func is_action_held(action: StringName) -> bool:
	if Input.is_action_pressed(action):
		return true
	if active_device_id < 0 or not _profiles.has(active_device_guid):
		return false
	var profile: Dictionary = _profiles[active_device_guid]
	if action in [&"shot_action", &"menu_confirm"]:
		return Input.is_joy_button_pressed(active_device_id, int(profile.get("shot_button", -999)))
	if action in [&"shot_cancel", &"menu_back"]:
		return Input.is_joy_button_pressed(active_device_id, int(profile.get("cancel_button", -999)))
	return false


func menu_controls_are_neutral() -> bool:
	return get_aim_vector().length() < 0.10 \
		and not is_action_held(&"menu_confirm") \
		and not is_action_held(&"menu_back") \
		and not Input.is_action_pressed("pause")


func get_aim_vector() -> Vector2:
	if not focused:
		return Vector2.ZERO
	if active_device_id >= 0:
		var joy := _read_active_controller_aim()
		var keyboard := _keyboard_aim_vector()
		return joy if joy.length_squared() >= keyboard.length_squared() else keyboard
	return Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", DEADZONE)


func _read_active_controller_aim() -> Vector2:
	var profile: Dictionary = _profiles.get(active_device_guid, {})
	var axis_x := int(profile.get("axis_x", JOY_AXIS_LEFT_X))
	var axis_y := int(profile.get("axis_y", JOY_AXIS_LEFT_Y))
	var joy := Vector2(
		Input.get_joy_axis(active_device_id, axis_x) * float(profile.get("axis_x_sign", 1.0)),
		Input.get_joy_axis(active_device_id, axis_y) * float(profile.get("axis_y_sign", 1.0))
	)
	if profile.is_empty():
		if Input.is_joy_button_pressed(active_device_id, JOY_BUTTON_DPAD_LEFT):
			joy.x -= 1.0
		if Input.is_joy_button_pressed(active_device_id, JOY_BUTTON_DPAD_RIGHT):
			joy.x += 1.0
		if Input.is_joy_button_pressed(active_device_id, JOY_BUTTON_DPAD_UP):
			joy.y -= 1.0
		if Input.is_joy_button_pressed(active_device_id, JOY_BUTTON_DPAD_DOWN):
			joy.y += 1.0
	else:
		joy += _custom_dpad_vector(profile)
	return _apply_deadzone(joy.limit_length(1.0))


func _custom_dpad_vector(profile: Dictionary) -> Vector2:
	var result := Vector2.ZERO
	if Input.is_joy_button_pressed(active_device_id, int(profile.get("dpad_left", -999))):
		result.x -= 1.0
	if Input.is_joy_button_pressed(active_device_id, int(profile.get("dpad_right", -999))):
		result.x += 1.0
	if Input.is_joy_button_pressed(active_device_id, int(profile.get("dpad_up", -999))):
		result.y -= 1.0
	if Input.is_joy_button_pressed(active_device_id, int(profile.get("dpad_down", -999))):
		result.y += 1.0
	return result.limit_length(1.0)


func _keyboard_aim_vector() -> Vector2:
	var result := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		result.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		result.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		result.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		result.y += 1.0
	return result.normalized() if result.length_squared() > 1.0 else result


func _apply_deadzone(value: Vector2) -> Vector2:
	var length := value.length()
	if length < DEADZONE:
		return Vector2.ZERO
	var scaled := clampf((length - DEADZONE) / (1.0 - DEADZONE), 0.0, 1.0)
	return value.normalized() * scaled


func begin_calibration() -> bool:
	if active_device_id < 0:
		mapping_required.emit(-1, "")
		return false
	_calibration_status = ""
	_calibration_step = 0
	_calibration_profile = {}
	calibration_updated.emit(get_calibration_prompt())
	return true


func cancel_calibration() -> void:
	_calibration_step = -1
	_calibration_profile = {}
	calibration_updated.emit("")


func is_calibrating() -> bool:
	return _calibration_step >= 0


func get_calibration_prompt() -> String:
	if _calibration_step < 0:
		return _calibration_status + "\nF4: Controller kalibrieren" if not _calibration_status.is_empty() else "F4: Controller kalibrieren"
	var prompts := {
		"shot_button": "Kreuz / Schlagtaste druecken",
		"cancel_button": "Kreis / Abbruchtaste druecken",
		"dpad_up": "Steuerkreuz OBEN druecken",
		"dpad_down": "Steuerkreuz UNTEN druecken",
		"dpad_left": "Steuerkreuz LINKS druecken",
		"dpad_right": "Steuerkreuz RECHTS druecken",
		"axis_x": "Linken Stick deutlich nach RECHTS bewegen",
		"axis_y": "Linken Stick deutlich nach UNTEN bewegen",
	}
	return "Kalibrierung %d/%d: %s" % [
		_calibration_step + 1,
		_calibration_steps.size(),
		prompts[_calibration_steps[_calibration_step]],
	]


func _capture_calibration_button(event: InputEventJoypadButton) -> void:
	if not event.pressed:
		return
	var step: String = _calibration_steps[_calibration_step]
	if step in ["axis_x", "axis_y"]:
		return
	_calibration_profile[step] = event.button_index
	_advance_calibration()


func _capture_calibration_axis(event: InputEventJoypadMotion) -> void:
	if absf(event.axis_value) < 0.70:
		return
	var step: String = _calibration_steps[_calibration_step]
	if step == "axis_x":
		_calibration_profile["axis_x"] = event.axis
		_calibration_profile["axis_x_sign"] = 1.0 if event.axis_value > 0.0 else -1.0
		_advance_calibration()
	elif step == "axis_y":
		_calibration_profile["axis_y"] = event.axis
		_calibration_profile["axis_y_sign"] = 1.0 if event.axis_value > 0.0 else -1.0
		_advance_calibration()


func _advance_calibration() -> void:
	_calibration_step += 1
	if _calibration_step < _calibration_steps.size():
		calibration_updated.emit(get_calibration_prompt())
		return
	_profiles[active_device_guid] = _calibration_profile.duplicate(true)
	var error := _save_user_profile(active_device_guid, _calibration_profile)
	_calibration_step = -1
	if error == OK:
		_calibration_status = "Kalibrierung gespeichert"
		calibration_finished.emit(active_device_guid)
	else:
		_calibration_status = "Nur fuer diese Sitzung aktiv – Speichern fehlgeschlagen"
	calibration_updated.emit(_calibration_status)


func get_diagnostics_text() -> String:
	var lines := PackedStringArray()
	lines.append("CONTROLLER-DIAGNOSE  [F3 schliessen | F4 kalibrieren]")
	lines.append("ID: %d" % active_device_id)
	lines.append("Name: %s" % active_device_name)
	lines.append("GUID: %s" % (active_device_guid if not active_device_guid.is_empty() else "-"))
	lines.append("SDL-Mapping: %s" % ("bekannt" if active_device_id >= 0 and Input.is_joy_known(active_device_id) else "unbekannt"))
	lines.append("Eingabe: %s | Fokus: %s" % [last_input_kind, "ja" if focused else "nein"])
	lines.append("Profil: %s" % ("benutzerdefiniert" if _profiles.has(active_device_guid) else "SDL-Standard"))
	var axis_text := PackedStringArray()
	var axis_keys := _last_axes.keys()
	axis_keys.sort()
	for key in axis_keys:
		axis_text.append("%s=%+.2f" % [key, _last_axes[key]])
	lines.append("Achsen: %s" % (", ".join(axis_text) if not axis_text.is_empty() else "noch keine Bewegung"))
	var pressed := PackedStringArray()
	var button_keys := _last_buttons.keys()
	button_keys.sort()
	for key in button_keys:
		if _last_buttons[key]:
			pressed.append(str(key))
	lines.append("Gedrueckte Tasten: %s" % (", ".join(pressed) if not pressed.is_empty() else "keine"))
	lines.append(get_calibration_prompt())
	return "\n".join(lines)
