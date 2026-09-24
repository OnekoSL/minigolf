class_name SettingsMenu
extends RefCounted

const CATEGORIES := ["SETTINGS_LANGUAGE", "SETTINGS_AUDIO", "SETTINGS_DISPLAY", "SETTINGS_CONTROLS"]
const LANGUAGE_NAMES := ["Deutsch", "English", "Français", "Español", "Italiano"]
var app: GameApp
var from_pause := false
var page := 0
var adjustments: Dictionary = {}
var error_message := ""
var confirmation_visible := false
var countdown_label: Label
var calibration_visible := false
var calibration_label: Label


func _init(owner_app: GameApp, paused: bool) -> void:
	app = owner_app
	from_pause = paused
	SettingsManager.begin()


func show() -> void:
	app.current_screen = GameApp.ScreenState.SETTINGS
	app._build_screen(tr("SETTINGS_TITLE"), tr("SETTINGS_PREVIEW"))
	adjustments.clear()
	confirmation_visible = SettingsManager.display_previous != null
	if confirmation_visible:
		countdown_label = MenuWidgets.label("", Vector2(80, 120), Vector2(480, 50), 14, Color("fff1b0"))
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		app.screen_root.add_child(countdown_label)
		app._add_option_button(tr("SETTINGS_KEEP_DISPLAY"), Rect2(92, 200, 218, 36), _confirm_display)
		app._add_option_button(tr("SETTINGS_REVERT"), Rect2(330, 200, 218, 36), _reject_display)
	elif calibration_visible:
		calibration_label = MenuWidgets.label("", Vector2(50, 110), Vector2(540, 135), 12, Color("fff1b0"))
		calibration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		app.screen_root.add_child(calibration_label)
		app._add_option_button(tr("SETTINGS_BACK"), Rect2(220, 280, 200, 30), _close_calibration)
		app._add_footer(tr("SETTINGS_CALIBRATION_SEPARATE"), tr("SETTINGS_CALIBRATION_EXIT"))
	else:
		_row(tr("SETTINGS_CATEGORY"), tr(CATEGORIES[page]), func(direction: int):
			page = posmod(page + direction, CATEGORIES.size())
			_refresh(0), 82)
		match page:
			0:
				_row(tr("SETTINGS_LANGUAGE"), LANGUAGE_NAMES[GameSettings.LANGUAGES.find(SettingsManager.draft.language)], func(direction: int): _adjust("language", direction), 126)
			1:
				_row(tr("SETTINGS_MASTER"), "%d %%" % SettingsManager.draft.master_volume, func(direction: int): _adjust("master_volume", direction), 126)
				_row(tr("SETTINGS_EFFECTS"), "%d %%" % SettingsManager.draft.effects_volume, func(direction: int): _adjust("effects_volume", direction), 160)
			2:
				_row(tr("SETTINGS_WINDOW_MODE"), tr("SETTINGS_FULLSCREEN" if SettingsManager.draft.fullscreen else "SETTINGS_WINDOWED"), func(direction: int): _adjust("fullscreen", direction), 120)
				var size: Vector2i = GameSettings.WINDOW_SIZES[SettingsManager.draft.window_size]
				_row(tr("SETTINGS_WINDOW_SIZE"), "%d × %d" % [size.x, size.y], func(direction: int): _adjust("window_size", direction), 151)
				_row("VSync", _on_off(SettingsManager.draft.vsync), func(direction: int): _adjust("vsync", direction), 182)
				_row(tr("SETTINGS_SHAKE"), _on_off(SettingsManager.draft.camera_shake), func(direction: int): _adjust("camera_shake", direction), 213)
			3:
				var help := MenuWidgets.label(tr("SETTINGS_CONTROL_HELP"), Vector2(60, 120), Vector2(520, 86), 10, Color("d7edcf"))
				help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				app.screen_root.add_child(help)
				app._add_option_button(tr("SETTINGS_CALIBRATE"), Rect2(105, 216, 430, 30), _calibrate)
				app.option_buttons[-1].disabled = ControllerSupport.active_device_id < 0
		if not error_message.is_empty():
			var error := MenuWidgets.label(tr(error_message), Vector2(25, 250), Vector2(590, 36), 9, Color("ffb19b"))
			error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			app.screen_root.add_child(error)
		app._add_option_button(tr("SETTINGS_APPLY"), Rect2(28, 292, 180, 30), _commit)
		app._add_option_button(tr("SETTINGS_CANCEL"), Rect2(230, 292, 180, 30), cancel)
		app._add_option_button(tr("SETTINGS_DEFAULTS"), Rect2(432, 292, 180, 30), _defaults)
		app._add_footer(tr("SETTINGS_NAV_HELP"), tr("SETTINGS_CALIBRATION_SEPARATE") if page == 3 else "")
	app._finalize_options()
	update()


func _row(label: String, value: String, adjust: Callable, y: float) -> void:
	var index := app.option_buttons.size()
	adjustments[index] = adjust
	app._add_option_button("%s:  %s" % [label, value], Rect2(80, y, 480, 28), func(): adjust.call(1))
	var generation := app._screen_generation
	for direction in [-1, 1]:
		var arrow := MenuWidgets.button("‹" if direction < 0 else "›", Rect2(42 if direction < 0 else 566, y, 32, 28))
		arrow.pressed.connect(func():
			if generation == app._screen_generation and app._can_use_menu():
				app.selected_option = index
				adjust.call(direction)
		)
		app.screen_root.add_child(arrow)


func navigate(direction: Vector2) -> bool:
	if absf(direction.x) <= absf(direction.y) or not adjustments.has(app.selected_option):
		return false
	adjustments[app.selected_option].call(1 if direction.x > 0 else -1)
	return true


func _adjust(key: String, direction: int) -> void:
	match key:
		"language":
			SettingsManager.draft.language = GameSettings.LANGUAGES[posmod(GameSettings.LANGUAGES.find(SettingsManager.draft.language) + direction, GameSettings.LANGUAGES.size())]
		"window_size":
			SettingsManager.draft.window_size = posmod(SettingsManager.draft.window_size + direction, GameSettings.WINDOW_SIZES.size())
		"master_volume", "effects_volume":
			SettingsManager.draft.set(key, clampi(int(SettingsManager.draft.get(key)) + direction * 5, 0, 100))
		_:
			SettingsManager.draft.set(key, not bool(SettingsManager.draft.get(key)))
	SettingsManager.preview()
	_refresh(app.selected_option)


func _refresh(selection: int) -> void:
	show()
	if not confirmation_visible:
		app._select_option(selection)


func update() -> void:
	if confirmation_visible:
		if SettingsManager.display_previous == null:
			show()
		else:
			countdown_label.text = tr("SETTINGS_DISPLAY_COUNTDOWN") % ceili(SettingsManager.display_seconds_left)
	if calibration_visible and is_instance_valid(calibration_label):
		calibration_label.text = ControllerSupport.get_calibration_prompt()


func back() -> void:
	if confirmation_visible:
		_reject_display()
	elif calibration_visible:
		_close_calibration()
	else:
		cancel()


func _confirm_display() -> void:
	SettingsManager.confirm_display()
	show()


func _reject_display() -> void:
	SettingsManager.reject_display()
	show()


func _defaults() -> void:
	SettingsManager.draft = GameSettings.new()
	SettingsManager.preview()
	show()


func _commit() -> void:
	if SettingsManager.commit() != OK:
		error_message = "SETTINGS_SAVE_ERROR"
		show()
		return
	_close()


func cancel() -> void:
	SettingsManager.cancel()
	_close()


func _close() -> void:
	adjustments.clear()
	app.settings_menu = null
	if from_pause:
		app._show_pause()
	else:
		app._show_title()


func _calibrate() -> void:
	calibration_visible = true
	calibration_visible = ControllerSupport.begin_calibration()
	show()


func _close_calibration() -> void:
	ControllerSupport.cancel_calibration()
	calibration_visible = false
	show()


func _on_off(value: bool) -> String:
	return tr("SETTINGS_ON" if value else "SETTINGS_OFF")
