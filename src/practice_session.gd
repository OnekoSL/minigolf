class_name PracticeSession
extends Node

var app: GameApp
var catalog: TutorialCatalog
var progress := PracticeProgress.new()
var game: PrototypeMain
var trace: PracticeTrace
var overlay: PracticeHUD
var monitor: PracticeLessonMonitor
var profile := PlayerProfile.create(1, "Ben", 0)
var lesson_index := -1
var section_index := 0
var basic_course := false
var category_index := 0
var hole_index := 0
var hole_page := 0
var section: TutorialSection
var screen := "hub"
var show_trace := true
var resume_pending := false
var restoring := false
var snapshot: EditorTestState
var candidate: EditorTestState
var snapshot_goal := {}
var candidate_goal := {}
var snapshot_target := Vector2.ZERO
var candidate_target := Vector2.ZERO
var _generation := 0
var _transporting := false
var _tracing := false
var _grid_title: Label
var _grid_start := 0
var _grid_count := 0
var _selection_seen := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = 120
	catalog = TutorialCatalog.load_default()
	progress.read()
	ControllerSupport.focus_changed.connect(_focus_changed)
	ControllerSupport.active_device_changed.connect(_device_changed)
	show_hub()


func _process(delta: float) -> void:
	if app.settings_menu != null or restoring:
		return
	if app._menu_input_locked:
		if ControllerSupport.focused and ControllerSupport.menu_controls_are_neutral() and not ControllerSupport.is_calibrating() and not app.diagnostics_visible:
			app._neutral_elapsed += delta
			if app._neutral_elapsed >= 0.12:
				app._menu_input_locked = false
				if resume_pending and game != null:
					resume_pending = false
					game.set_external_paused(false)
					game.set_input_enabled(true)
					game.set_process_input(true)
					get_tree().paused = false
		else:
			app._neutral_elapsed = 0.0
		return
	if screen == "play":
		if overlay != null:
			overlay.update_hint()
		return
	if not app._can_use_menu():
		return
	var aim := ControllerSupport.get_aim_vector()
	if aim.length() < app.MENU_NAV_THRESHOLD:
		app._nav_was_active = false
		app._nav_repeat_left = 0.0
	else:
		app._nav_repeat_left -= delta
		if not app._nav_was_active or app._nav_repeat_left <= 0:
			app._move_selection(aim)
			app._nav_repeat_left = app.MENU_REPEAT_RATE if app._nav_was_active else app.MENU_REPEAT_DELAY
			app._nav_was_active = true
	if screen == "holes" and app.selected_option != _selection_seen:
		_update_grid_selection()


func _input(event: InputEvent) -> void:
	if app.settings_menu != null or restoring:
		return
	if event is InputEventKey and event.echo:
		return
	if screen == "play":
		return # Production game owns shot, pause, restart and training actions.
	if event.is_action_pressed("toggle_diagnostics", false, true):
		app._toggle_diagnostics()
		get_viewport().set_input_as_handled()
		return
	if not app._can_use_menu():
		return
	if ControllerSupport.event_is_pressed(event, &"menu_back"):
		go_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause", false, true) and screen == "tools":
		resume()
		get_viewport().set_input_as_handled()
	elif ControllerSupport.event_is_pressed(event, &"menu_confirm") and not event is InputEventMouseButton:
		app._activate_selected()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if game == null or get_tree().paused or not _tracing:
		return
	var transported := game.ball.is_tunnel_sequence_active()
	if transported or transported != _transporting:
		trace.break_segment()
	_transporting = transported
	if not transported and game.ball.visible:
		trace.sample(game.ball.position - Vector2(0, game.ball._visual_lift))
	if not game.ball.moving and not game.ball.is_cannon_sequence_active() and not transported:
		_tracing = false


func _build(name: String, title: String, subtitle := "") -> void:
	screen = name
	resume_pending = false
	if game != null:
		game.set_input_enabled(false)
		game.set_process_input(false)
		game.set_external_paused(true)
	get_tree().paused = game != null
	app.current_screen = GameApp.ScreenState.PRACTICE
	app._build_screen(title, subtitle)
	app.controller_status_label.hide()
	_grid_title = null
	_selection_seen = -1
	app._add_footer(I18n.text("PRACTICE_NAV"), I18n.text("PRACTICE_SAVE_ERROR") if progress.error != OK else I18n.text("PRACTICE_NO_RECORDS"))


func _button(key: String, y: float, action: Callable) -> Button:
	return app._add_option_button(I18n.text(key), Rect2(150, y, 340, 30), action)


func show_hub() -> void:
	_dispose_game()
	lesson_index = -1
	_build("hub", I18n.text("PRACTICE_TITLE"), I18n.text("PRACTICE_WELCOME"))
	_button("PRACTICE_BASIC", 94, func(): start_lesson(0, true))
	_button("PRACTICE_LESSONS", 139, show_lessons)
	_button("PRACTICE_FREE", 184, show_categories)
	_button("TEXT_BACK", 270, close)
	app._finalize_options()


func show_lessons() -> void:
	_dispose_game()
	_build("lessons", I18n.text("PRACTICE_LESSONS"), I18n.text("PRACTICE_ALL_OPEN"))
	for index in range(catalog.lessons.size()):
		var lesson := catalog.lessons[index]
		var text := "%d. %s%s" % [index + 1, I18n.text(lesson.title_key), "  ✓" if progress.contains(lesson.lesson_id) else ""]
		var button := app._add_option_button(text, Rect2(28 + (index % 2) * 300, 82 + (index / 2) * 51, 284, 42), func(): show_sections(index))
		button.add_theme_font_size_override("font_size", 10)
	_button("TEXT_BACK", 295, show_hub)
	app.option_columns = 2
	app._finalize_options()


func show_sections(index: int) -> void:
	_dispose_game()
	lesson_index = index
	basic_course = false
	var lesson := catalog.lessons[index]
	_build("sections", I18n.text(lesson.title_key), I18n.text("PRACTICE_CHOOSE_SECTION"))
	for part in range(lesson.sections.size()):
		var value := lesson.sections[part]
		var text := I18n.text(value.title_key) + ("  ✓" if progress.contains(value.section_id) else "")
		app._add_option_button(text, Rect2(130, 86 + part * 44, 380, 36), func(): start_lesson(index, false, part))
	_button("TEXT_BACK", 284, show_lessons)
	app._finalize_options()


func start_lesson(index: int, basic := false, part := 0) -> void:
	lesson_index = index
	section_index = part
	basic_course = basic
	section = catalog.lessons[index].sections[part]
	_start_game(section.hole, PlayerProfile.create(1, "Ben", 0))
	monitor = PracticeLessonMonitor.new()
	monitor.game = game
	monitor.section = section
	game.add_child(monitor)
	var generation := _generation
	monitor.succeeded.connect(func():
		if generation == _generation and monitor != null and monitor.completed:
			_complete_section()
	)
	monitor.missed_goal.connect(func():
		if generation == _generation and game != null and game.shot_controller.state == ShotController.ShotState.HOLE_COMPLETE:
			show_result(false)
	)
	overlay.section = section
	overlay.guided = index < 3
	overlay.update_hint()
	show_intro()


func show_intro() -> void:
	_build("intro", I18n.text(catalog.lessons[lesson_index].title_key), I18n.text(section.title_key))
	var text := MenuWidgets.label(I18n.text(section.hint_key) + "\n\n" + I18n.text("PRACTICE_INTRO_HELP"), Vector2(90, 90), Vector2(460, 135), 15, Color("#d7edcf"))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size = Vector2(460, 135)
	app.screen_root.add_child(text)
	text.set_deferred("size", Vector2(460, 135))
	_button("PRACTICE_BEGIN", 248, resume)
	_button("PRACTICE_SKIP", 287, next_section)
	app._finalize_options()


func show_categories() -> void:
	_dispose_game()
	lesson_index = -1
	section = null
	_build("categories", I18n.text("PRACTICE_FREE"), I18n.text("PRACTICE_CHOOSE_COURSE"))
	for index in range(app.course_catalog.courses.size() + 1):
		var text := I18n.content_name(app.course_catalog.courses[index]) if index < app.course_catalog.courses.size() else I18n.text("PRACTICE_LABS")
		app._add_option_button(text, Rect2(30 + (index % 3) * 196, 84 + (index / 3) * 46, 188, 37), func():
			if category_index != index:
				hole_index = 0
				hole_page = 0
			category_index = index
			show_holes()
		)
	_button("TEXT_BACK", 290, show_hub)
	app.option_columns = 3
	app._finalize_options()
	app._select_option(category_index)


func category_holes() -> Array[HoleDefinition]:
	var result: Array[HoleDefinition] = []
	if category_index < app.course_catalog.courses.size():
		for id in app.course_catalog.courses[category_index].hole_ids:
			result.append(app.hole_catalog.get_hole(id))
	else:
		for hole in app.hole_catalog.holes:
			if hole.category == HoleDefinition.HoleCategory.TECHNICAL:
				result.append(hole)
	return result


func show_holes() -> void:
	_dispose_game()
	var holes := category_holes()
	hole_index = clampi(hole_index, 0, holes.size() - 1)
	hole_page = hole_index / 9
	var title := I18n.content_name(app.course_catalog.courses[category_index]) if category_index < app.course_catalog.courses.size() else I18n.text("PRACTICE_LABS")
	_build("holes", title, "")
	_grid_title = MenuWidgets.label("", Vector2(20, 52), Vector2(600, 24), 12, Color("#8fd5cc"))
	_grid_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	app.screen_root.add_child(_grid_title)
	var course := CourseDefinition.new()
	course.course_id = &"practice_preview"
	course.display_name = title
	_grid_start = hole_page * 9
	_grid_count = mini(9, holes.size() - _grid_start)
	for index in range(_grid_start, _grid_start + _grid_count):
		course.hole_ids.append(holes[index].hole_id)
	var preview := CoursePreview.new()
	preview.position = Vector2(50, 77)
	preview.cell_size = Vector2(180, 60)
	app.screen_root.add_child(preview)
	preview.show_course(course, app.hole_catalog)
	preview.title.hide()
	for local_index in range(_grid_count):
		var index := _grid_start + local_index
		var button := app._add_option_button("", Rect2(50 + (local_index % 3) * 180, 97 + (local_index / 3) * 60, 176, 56), func(): start_free(index))
		button.mouse_entered.connect(func():
			if screen == "holes" and app._can_use_menu():
				_update_grid_selection()
		)
	app._add_option_button(I18n.text("TEXT_PREVIOUS"), Rect2(48, 290, 170, 30), func():
		hole_index = maxi(0, _grid_start - 9)
		show_holes()
	).disabled = hole_page == 0
	app._add_option_button(I18n.text("TEXT_BACK"), Rect2(235, 290, 170, 30), show_categories)
	app._add_option_button(I18n.text("TEXT_NEXT"), Rect2(422, 290, 170, 30), func():
		hole_index = _grid_start + 9
		show_holes()
	).disabled = _grid_start + 9 >= holes.size()
	app.option_columns = 3
	app._finalize_options()
	app._select_option(hole_index - _grid_start)
	_update_grid_selection()


func _update_grid_selection() -> void:
	_selection_seen = app.selected_option
	if app.selected_option < _grid_count:
		hole_index = _grid_start + app.selected_option
	var holes := category_holes()
	_grid_title.text = "%d. %s  ·  PAR %d" % [hole_index + 1, I18n.content_name(holes[hole_index]), holes[hole_index].par]
	for index in range(_grid_count):
		var color := Color("#f0c45b") if index == app.selected_option else Color("#40596a")
		var style := MenuWidgets.panel_style(Color(0, 0, 0, 0), color, 2 if index == app.selected_option else 1)
		app.option_buttons[index].add_theme_stylebox_override("normal", style)
		app.option_buttons[index].add_theme_stylebox_override("hover", style)


func start_free(index: int) -> void:
	hole_index = index
	lesson_index = -1
	section = null
	_start_game(category_holes()[index], profile)
	resume()


func _start_game(definition: HoleDefinition, golfer: PlayerProfile) -> void:
	_dispose_game()
	app._clear_screen()
	game = PrototypeMain.new()
	game.practice_enabled = true
	game.configure_attempt(definition, golfer, true, 1, 1, 0, false)
	add_child(game)
	game.set_input_enabled(false)
	game.set_process_input(false)
	game.set_external_paused(true)
	get_tree().paused = true
	app.gameplay = game
	trace = PracticeTrace.new()
	trace.z_index = 20
	trace.visible = show_trace
	game.add_child(trace)
	overlay = PracticeHUD.new()
	overlay.game = game
	game.hud.add_child(overlay)
	overlay.menu_requested.connect(_request_tools)
	game.training_menu_requested.connect(_request_tools)
	game.pause_requested.connect(show_tools)
	game.hole_restarted.connect(_restarted)
	game.shot_controller.state_changed.connect(_shot_state)
	game.shot_controller.cancelled.connect(func(): candidate = null)
	game.shot_controller.shot_committed.connect(_shot_contact)
	game.ball.hazard_entered.connect(func(_kind):
		_tracing = false
		trace.break_segment()
	)
	var generation := _generation
	game.ball.holed.connect(func(_strokes):
		if lesson_index < 0:
			_show_free_result.call_deferred(generation)
	)


func _show_free_result(generation: int) -> void:
	if generation == _generation and game != null and game.shot_controller.state == ShotController.ShotState.HOLE_COMPLETE:
		show_result(true)


func _shot_state(state: int) -> void:
	if state == ShotController.ShotState.POWER:
		candidate = EditorTestState.capture(game)
		candidate_target = game.shot_controller.cursor_position
		candidate_goal = monitor.capture() if monitor != null else {}
	if overlay != null:
		overlay.update_hint()


func _shot_contact(_direction: Vector2, _speed: float, _accuracy: float) -> void:
	if not trace.current.is_empty():
		trace.previous.clear()
	if candidate != null:
		snapshot = candidate
		snapshot_target = candidate_target
		snapshot_goal = candidate_goal.duplicate(true)
	candidate = null
	trace.clear_current()
	trace.sample(game.ball.position)
	_transporting = false
	_tracing = true


func _request_tools() -> void:
	if not app._menu_input_locked and game != null and game.input_enabled and ControllerSupport.focused and not game.diagnostics_visible and not ControllerSupport.is_calibrating():
		show_tools()


func show_tools() -> void:
	if game == null:
		return
	_build("tools", I18n.text("PRACTICE_TOOLS"), I18n.text("PRACTICE_NO_RECORDS"))
	var actions: Array = [
		["TEXT_RESUME", resume], ["PRACTICE_RETRY", retry],
		["TEXT_RESTART_HOLE", restart], ["PRACTICE_TRACE_OFF" if show_trace else "PRACTICE_TRACE_ON", toggle_trace],
		["PRACTICE_SKIP" if lesson_index >= 0 else "PRACTICE_GOLFER", next_section if lesson_index >= 0 else show_golfers],
		["PRACTICE_LESSONS" if lesson_index >= 0 else "PRACTICE_PICK_HOLE", show_lessons if lesson_index >= 0 else show_holes],
		["SETTINGS_TITLE", func(): app._show_settings(true)], ["PRACTICE_TITLE", show_hub],
	]
	for index in range(actions.size()):
		var action: Array = actions[index]
		var button := app._add_option_button(I18n.text(action[0]), Rect2(36 + (index % 2) * 290, 87 + (index / 2) * 54, 278, 40), action[1])
		if index == 1:
			button.disabled = snapshot == null
	app.option_columns = 2
	app._finalize_options()


func resume() -> void:
	if game == null:
		return
	app._clear_screen()
	app.current_screen = GameApp.ScreenState.PRACTICE
	screen = "play"
	resume_pending = true
	game.set_input_enabled(false)
	game.set_process_input(false)
	game.set_external_paused(true)
	get_tree().paused = true
	app._arm_input_gate()
	overlay.update_hint()


func retry() -> void:
	if snapshot == null or restoring or game == null:
		return
	restoring = true
	var generation := _generation
	game.set_input_enabled(false)
	game.set_external_paused(true)
	get_tree().paused = true
	await get_tree().physics_frame
	if generation != _generation or game == null:
		restoring = false
		return
	snapshot.restore(game)
	game.hud.golfer.reset_animation()
	game.shot_controller.reset_aim()
	game.shot_controller.cursor_position = snapshot_target
	if monitor != null:
		monitor.restore(snapshot_goal)
	trace.compare()
	_tracing = false
	candidate = null
	await get_tree().physics_frame
	restoring = false
	if generation == _generation and game != null:
		resume()


func _restarted() -> void:
	snapshot = null
	candidate = null
	snapshot_goal.clear()
	_tracing = false
	trace.clear_all()
	if monitor != null:
		monitor.reset()
	# Defer the gate until the production reset has finished.
	var generation := _generation
	(func():
		if generation == _generation and game != null:
			resume()
	).call_deferred()


func restart() -> void:
	game.restart_hole()


func toggle_trace() -> void:
	show_trace = not show_trace
	trace.visible = show_trace
	show_tools()


func _complete_section() -> void:
	progress.mark_complete(section.section_id)
	var lesson := catalog.lessons[lesson_index]
	if lesson.sections.all(func(value: TutorialSection): return progress.contains(value.section_id)):
		progress.mark_complete(lesson.lesson_id)
	show_result(true)


func show_result(success: bool) -> void:
	if game == null:
		return
	var title := I18n.text("PRACTICE_SUCCESS" if success else "PRACTICE_TRY_GOAL")
	_build("result", title, I18n.text(section.title_key) if section != null and not success else I18n.text("PRACTICE_RESULT") % game.strokes)
	if lesson_index >= 0:
		_button("PRACTICE_CONTINUE" if success else "PRACTICE_SKIP", 97, next_section)
		_button("PRACTICE_RETRY", 140, retry).disabled = snapshot == null
		_button("PRACTICE_AGAIN", 183, func(): start_lesson(lesson_index, basic_course, section_index))
		_button("PRACTICE_OVERVIEW", 269, show_lessons)
	else:
		_button("PRACTICE_RETRY", 97, retry).disabled = snapshot == null
		_button("TEXT_RESTART_HOLE", 140, restart)
		_button("PRACTICE_NEXT_HOLE", 183, next_hole)
		_button("PRACTICE_PICK_HOLE", 269, show_holes)
	app._finalize_options()


func next_section() -> void:
	if section_index + 1 < catalog.lessons[lesson_index].sections.size():
		start_lesson(lesson_index, basic_course, section_index + 1)
	elif basic_course and lesson_index < 2:
		start_lesson(lesson_index + 1, true)
	else:
		show_lessons()


func next_hole() -> void:
	if hole_index + 1 < category_holes().size():
		start_free(hole_index + 1)
	else:
		show_holes()


func show_golfers() -> void:
	_build("golfers", I18n.text("PRACTICE_GOLFER"), I18n.text("PRACTICE_GOLFER_RESTART"))
	for index in range(GolferDefinition.IDS.size()):
		var id := GolferDefinition.IDS[index]
		app._add_option_button(GolferDefinition.get_golfer(id).display_name, Rect2(160, 82 + index * 39, 320, 32), func():
			if id == &"don":
				show_don()
			else:
				profile = PlayerProfile.create(1, GolferDefinition.get_golfer(id).display_name, 0, id)
				start_free(hole_index)
		)
	_button("TEXT_BACK", 287, show_tools)
	app._finalize_options()


func show_don() -> void:
	screen = "don"
	app._show_test_golfer_stats()
	app.option_actions[-1] = func():
		profile = PlayerProfile.create(1, "Don", 0, &"don", app.setup_test_golfer)
		start_free(hole_index)


func go_back() -> void:
	match screen:
		"hub": close()
		"categories", "lessons": show_hub()
		"holes": show_categories()
		"sections", "intro", "result": show_lessons() if lesson_index >= 0 else show_holes()
		"golfers": show_tools()
		"don": show_golfers()
		"tools": resume()


func _focus_changed(focused: bool) -> void:
	if not focused and screen == "play" and not restoring:
		show_tools()


func _device_changed(_id: int, _name: String, _guid: String) -> void:
	if screen == "play" and not restoring:
		show_tools()


func _dispose_game() -> void:
	_generation += 1
	resume_pending = false
	if game != null:
		game.set_input_enabled(false)
		game.set_external_paused(true)
		remove_child(game)
		game.queue_free()
	game = null
	app.gameplay = null
	monitor = null
	overlay = null
	trace = null
	snapshot = null
	candidate = null
	_tracing = false
	get_tree().paused = false


func close() -> void:
	_dispose_game()
	app.practice = null
	app._show_mode()
	queue_free()
