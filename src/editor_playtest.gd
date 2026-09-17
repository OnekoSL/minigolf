class_name EditorPlaytest
extends Node

signal closed()

var definition: HoleDefinition
var golfer_id := &"allrounder"
var game: PrototypeMain
var snapshot: EditorTestState
var trace: Line2D
var show_trace := true
var placing := false
var _neutral_time := 0.0
var _locked := true
var _paused := false
var _closing := false
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().content_scale_size = Vector2i(640, 360)
	game = PrototypeMain.new()
	game.configure_attempt(definition, PlayerProfile.create(1, "TEST", 0, golfer_id), true, 1, 1, 0, false)
	add_child(game)
	game.set_input_enabled(false)
	get_tree().paused = true
	game.shot_controller.swing_started.connect(_capture)
	game.pause_requested.connect(_toggle_pause)
	game.hole_restarted.connect(func():
		snapshot = null
		if trace != null:
			trace.clear_points()
	)
	trace = Line2D.new()
	trace.width = 1
	trace.default_color = Color(1, 0.85, 0.3, 0.75)
	trace.z_index = 20
	game.add_child(trace)
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	var panel := GridContainer.new()
	panel.columns = 2
	panel.position = Vector2(4, 4)
	panel.custom_minimum_size.x = 152
	layer.add_child(panel)
	game.hud.controller_label.hide()
	game.hud.course_label.hide()
	for entry in [["Editor", _close], ["Wiederholen", _repeat], ["Ball setzen", _place_mode], ["Spur an/aus", _toggle_trace], ["Pause", _toggle_pause], ["Neustart", _restart]]:
		var button := Button.new()
		button.text = entry[0]
		button.add_theme_font_size_override("font_size", 9)
		button.custom_minimum_size = Vector2(76, 20)
		button.pressed.connect(entry[1])
		panel.add_child(button)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 8)
	_status.text = "TEST · R Neustart · P Pause"
	_status.position = Vector2(4, 73)
	_status.size = Vector2(158, 12)
	_status.clip_text = true
	layer.add_child(_status)


func _process(delta: float) -> void:
	if _closing:
		return
	if _locked:
		if ControllerSupport.focused and ControllerSupport.menu_controls_are_neutral():
			_neutral_time += delta
			if _neutral_time >= 0.12:
				_locked = false
				game.set_input_enabled(not _paused and not placing)
				get_tree().paused = _paused or placing
		else:
			_neutral_time = 0
	trace.visible = show_trace


func _physics_process(_delta: float) -> void:
	if not _paused and game.ball.moving:
		var point := game.ball.global_position
		if trace.get_point_count() == 0 or trace.get_point_position(trace.get_point_count() - 1).distance_to(point) > 1:
			trace.add_point(point)
			if trace.get_point_count() > 12000:
				trace.remove_point(0)


func _capture(_direction: Vector2, _speed: float, _accuracy: float, _perfect: bool) -> void:
	snapshot = EditorTestState.capture(game)
	trace.clear_points()


func _repeat() -> void:
	if snapshot == null or _locked:
		return
	_locked = true
	_neutral_time = -1.0
	game.set_external_paused(true)
	game.set_input_enabled(false)
	get_tree().paused = true
	# Restore outside physics flushing; one disabled physics frame refreshes overlaps.
	await get_tree().physics_frame
	snapshot.restore(game)
	await get_tree().physics_frame
	trace.clear_points()
	game.set_external_paused(false)
	_paused = false
	placing = false
	_arm_gate()
	_status.text = "TEST · gleicher Ausgangszustand"


func _arm_gate() -> void:
	_locked = true
	_neutral_time = 0
	game.set_input_enabled(false)
	get_tree().paused = true


func _place_mode() -> void:
	if _locked:
		return
	placing = true
	_paused = true
	game.set_external_paused(true)
	game.set_input_enabled(false)
	get_tree().paused = true
	_status.text = "Freien Boden anklicken · Esc Abbruch"


func _input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("pause", false, true) and _paused and not placing:
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if placing:
			placing = false
			_paused = false
			game.set_external_paused(false)
			_arm_gate()
		else:
			_close()
		get_viewport().set_input_as_handled()
	if placing and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.position.x > 168:
		var point := game.ball.get_global_mouse_position()
		if can_place(point):
			game.ball.reset_to(point)
			game.shot_controller.reset_aim()
			game.hud.hide_result()
			game._attempt_reported = false
			trace.clear_points()
			snapshot = null
			placing = false
			_paused = false
			game.set_external_paused(false)
			_arm_gate()
			_status.text = "TEST · Ball versetzt"
		else:
			_status.text = "Position blockiert · anderen Boden wählen"
		get_viewport().set_input_as_handled()


func can_place(point: Vector2) -> bool:
	if not EditorDocument.new(definition).clear_position(point, false):
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PrototypeBall.RADIUS
	query.shape = shape
	query.transform = Transform2D(0, point)
	query.collision_mask = 2
	query.collide_with_areas = false
	return game.ball.get_world_2d().direct_space_state.intersect_shape(query).is_empty()


func _toggle_pause() -> void:
	_paused = not _paused
	game.set_external_paused(_paused)
	_arm_gate()
	_status.text = "PAUSE · P fortsetzen" if _paused else "TEST · R Neustart · P Pause"


func _toggle_trace() -> void:
	show_trace = not show_trace


func _restart() -> void:
	snapshot = null
	trace.clear_points()
	game.restart_hole()
	_paused = false
	placing = false
	game.set_external_paused(false)
	_arm_gate()


func _close() -> void:
	if _closing:
		return
	_closing = true
	game.set_input_enabled(false)
	game.set_external_paused(true)
	get_tree().paused = false
	closed.emit()
