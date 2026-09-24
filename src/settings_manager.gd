extends Node

signal changed()

var store := SettingsStore.new()
var saved := GameSettings.new()
var current := GameSettings.new()
var draft: GameSettings
var display_previous: GameSettings
var display_seconds_left := 0.0
var display_reverted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	saved = store.read()
	apply(saved)
	if DisplayServer.get_name() != "headless":
		_apply_display()


func _process(delta: float) -> void:
	if display_previous != null:
		display_seconds_left -= delta
		if display_seconds_left <= 0.0:
			reject_display()
			display_reverted = true


func begin() -> void:
	draft = saved.copy()
	display_reverted = false


func preview() -> void:
	if draft == null:
		return
	if not current.same_display(draft) and display_previous == null:
		display_previous = current.copy()
		display_seconds_left = 15.0
	apply(draft)


func confirm_display() -> void:
	display_previous = null
	display_seconds_left = 0.0


func reject_display() -> void:
	if display_previous == null:
		return
	draft.fullscreen = display_previous.fullscreen
	draft.window_size = display_previous.window_size
	draft.vsync = display_previous.vsync
	confirm_display()
	apply(draft)


func commit() -> Error:
	if draft == null or display_previous != null:
		return ERR_BUSY
	var error := store.write(draft)
	if error == OK:
		saved = draft.copy()
		draft = null
	return error


func cancel() -> void:
	confirm_display()
	draft = null
	apply(saved)


func apply(value: GameSettings) -> void:
	var display_changed := not current.same_display(value)
	current = value.copy()
	TranslationServer.set_locale(current.language)
	var effects_bus := AudioServer.get_bus_index("Effects")
	if effects_bus < 0:
		AudioServer.add_bus()
		effects_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(effects_bus, "Effects")
		AudioServer.set_bus_send(effects_bus, "Master")
	_set_volume(AudioServer.get_bus_index("Master"), current.master_volume)
	_set_volume(effects_bus, current.effects_volume)
	if DisplayServer.get_name() != "headless" and display_changed:
		_apply_display()
	changed.emit()


func _set_volume(bus: int, percent: int) -> void:
	AudioServer.set_bus_mute(bus, percent == 0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, float(percent) / 100.0)))


func _apply_display() -> void:
	var window := get_window()
	window.mode = Window.MODE_FULLSCREEN if current.fullscreen else Window.MODE_WINDOWED
	if not current.fullscreen:
		var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
		var desired: Vector2i = GameSettings.WINDOW_SIZES[current.window_size]
		var available := (usable.size - Vector2i(24, 64)).max(Vector2i(640, 360))
		var scale := minf(1.0, minf(float(available.x) / desired.x, float(available.y) / desired.y))
		window.size = Vector2i(Vector2(desired) * scale)
		window.position = usable.position + (usable.size - window.size) / 2
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if current.vsync else DisplayServer.VSYNC_DISABLED)
