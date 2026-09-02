extends Node2D

const PIXELS_PER_METER := 32.0

var hole: HoleRuntime
var hole_catalog: HoleCatalog
var ball: PrototypeBall
var shot_controller: ShotController
var hud: PrototypeHUD
var course_camera: CourseCamera
var strokes := 0
var diagnostics_visible := false
var prototype_paused := false
var _diagnostics_elapsed := 0.0
var audio_feedback: PrototypeAudio
var feedback_effects: FeedbackEffects
var _pending_perfect := false
var active_hole_index := 0
var _switch_cooldown := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hole_catalog = HoleCatalog.load_default()
	if hole_catalog == null:
		push_error("Lochkatalog konnte nicht geladen werden")
		return
	var catalog_errors := hole_catalog.validate()
	if not catalog_errors.is_empty():
		for error in catalog_errors:
			push_error(error)
		return
	_build_game()
	_connect_signals()
	_create_audio()
	_update_controller_status(
		ControllerSupport.active_device_id,
		ControllerSupport.active_device_name,
		ControllerSupport.active_device_guid
	)
	_update_hud()


func _build_game() -> void:
	hole = _create_active_hole()
	hole.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(hole)

	ball = PrototypeBall.new()
	ball.process_mode = Node.PROCESS_MODE_PAUSABLE
	ball.position = hole.get_tee_position()
	add_child(ball)
	ball.configure_environment(hole.zones, hole.get_hole_position())

	shot_controller = ShotController.new()
	shot_controller.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(shot_controller)
	shot_controller.configure(ball, hole.get_course_rect(), hole.get_initial_aim_offset())

	course_camera = CourseCamera.new()
	course_camera.process_mode = Node.PROCESS_MODE_PAUSABLE
	course_camera.enabled = true
	add_child(course_camera)
	course_camera.configure(ball, hole.get_camera_center_bounds())
	_update_camera_focus()
	course_camera.snap_to_target()

	feedback_effects = FeedbackEffects.new()
	feedback_effects.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(feedback_effects)

	hud = PrototypeHUD.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.set_course_name(hole.get_display_name())


func _create_active_hole() -> HoleRuntime:
	var runtime := HoleRuntime.new()
	runtime.configure(hole_catalog.holes[active_hole_index])
	return runtime


func _connect_signals() -> void:
	shot_controller.state_changed.connect(_on_shot_state_changed)
	shot_controller.swing_started.connect(_on_swing_started)
	shot_controller.shot_committed.connect(_on_shot_committed)
	ball.stopped.connect(_on_ball_stopped)
	ball.wall_hit.connect(_on_wall_hit)
	ball.hazard_entered.connect(_on_hazard_entered)
	ball.holed.connect(_on_ball_holed)
	ball.external_motion_started.connect(_on_external_motion_started)
	ControllerSupport.active_device_changed.connect(_update_controller_status)
	ControllerSupport.calibration_updated.connect(_on_calibration_updated)
	ControllerSupport.calibration_finished.connect(_on_calibration_finished)


func _process(delta: float) -> void:
	_switch_cooldown = maxf(0.0, _switch_cooldown - delta)
	_update_camera_focus()
	if not prototype_paused:
		_update_hud()
		if audio_feedback != null:
			audio_feedback.update_roll(ball.velocity.length(), ball.current_surface_type, ball.moving)
		if feedback_effects != null:
			feedback_effects.update_ball(
				ball.global_position, ball.velocity.length(), ball.current_surface_type, ball.moving, delta
			)
	if diagnostics_visible:
		_diagnostics_elapsed += delta
		if _diagnostics_elapsed >= 0.08:
			_diagnostics_elapsed = 0.0
			hud.set_diagnostics(true, ControllerSupport.get_diagnostics_text())


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("toggle_diagnostics", false, true):
		diagnostics_visible = not diagnostics_visible
		hud.set_diagnostics(diagnostics_visible, ControllerSupport.get_diagnostics_text())
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("start_calibration", false, true):
		if ControllerSupport.is_calibrating():
			ControllerSupport.cancel_calibration()
		else:
			ControllerSupport.begin_calibration()
		diagnostics_visible = true
		hud.set_diagnostics(true, ControllerSupport.get_diagnostics_text())
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause", false, true):
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if prototype_paused:
		return
	if event.is_action_pressed("switch_test_hole", false, true) and _switch_cooldown <= 0.0:
		_switch_cooldown = 0.25
		switch_test_hole()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart_hole", false, true):
		restart_hole()
		get_viewport().set_input_as_handled()
		return
	if shot_controller.state == ShotController.ShotState.HOLE_COMPLETE and ControllerSupport.event_is_pressed(event, &"shot_action"):
		restart_hole()
		get_viewport().set_input_as_handled()


func _on_shot_committed(direction: Vector2, speed: float, accuracy: float) -> void:
	strokes += 1
	if audio_feedback != null:
		audio_feedback.play_hit(speed, _pending_perfect)
	if _pending_perfect and feedback_effects != null:
		feedback_effects.spawn_perfect(ball.global_position)
	ball.launch(direction, speed, strokes)
	_pending_perfect = false
	_update_hud()


func _on_swing_started(_direction: Vector2, _speed: float, _accuracy: float, perfect: bool) -> void:
	_pending_perfect = perfect
	hud.play_golfer_reaction("perfect_swing" if perfect else "swing")
	_update_hud()


func _on_shot_state_changed(state: int) -> void:
	if audio_feedback != null:
		audio_feedback.play_phase(state)
	_update_hud()


func _on_ball_stopped(at_position: Vector2) -> void:
	shot_controller.notify_ball_stopped(at_position)
	_update_hud()


func _on_external_motion_started() -> void:
	shot_controller.notify_external_motion_started()
	_update_hud()


func _on_wall_hit(intensity: float, position: Vector2, normal: Vector2, kind: StringName) -> void:
	if intensity >= 35.0 and audio_feedback != null:
		audio_feedback.play_wall(intensity, kind)
	if feedback_effects != null:
		feedback_effects.spawn_wall(position, normal, intensity, kind)
	if course_camera != null:
		course_camera.add_impact(normal, intensity)


func _on_hazard_entered(_hazard_type: String) -> void:
	strokes += 1
	ball.current_stroke_count = strokes
	hud.play_golfer_reaction("frustration")
	if audio_feedback != null:
		audio_feedback.play_water()
	if feedback_effects != null:
		feedback_effects.spawn_water(ball.global_position)
	_update_hud()


func _on_ball_holed(final_strokes: int) -> void:
	shot_controller.notify_hole_complete()
	hud.play_golfer_reaction("success")
	hud.show_result(final_strokes, hole.get_par())
	if audio_feedback != null:
		audio_feedback.play_hole()
	if feedback_effects != null:
		feedback_effects.spawn_hole(ball.global_position)
	_update_hud()


func restart_hole() -> void:
	strokes = 0
	hole.reset_obstacles()
	ball.reset_to(hole.get_tee_position())
	shot_controller.reset_aim()
	_update_camera_focus()
	course_camera.snap_to_target()
	hud.hide_result()
	_pending_perfect = false
	if feedback_effects != null:
		feedback_effects.clear()
	_update_hud()


func switch_test_hole() -> void:
	active_hole_index = (active_hole_index + 1) % hole_catalog.holes.size()
	shot_controller.cancel_shot()
	remove_child(hole)
	hole.queue_free()
	hole = _create_active_hole()
	hole.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(hole)
	move_child(hole, 0)
	strokes = 0
	ball.configure_environment(hole.zones, hole.get_hole_position())
	ball.reset_to(hole.get_tee_position())
	shot_controller.configure(ball, hole.get_course_rect(), hole.get_initial_aim_offset())
	course_camera.configure(ball, hole.get_camera_center_bounds())
	_update_camera_focus()
	course_camera.snap_to_target()
	hud.hide_result()
	hud.set_course_name(hole.get_display_name())
	_pending_perfect = false
	if feedback_effects != null:
		feedback_effects.clear()
	_update_hud()


func _update_camera_focus() -> void:
	if course_camera == null or ball == null or shot_controller == null:
		return
	var focus := ball.global_position
	var aiming_with_cursor := false
	if shot_controller.state in [
		ShotController.ShotState.AIMING,
		ShotController.ShotState.POWER,
		ShotController.ShotState.ACCURACY,
		ShotController.ShotState.ARMED,
		ShotController.ShotState.SWINGING,
	]:
		focus = shot_controller.cursor_position
		aiming_with_cursor = true
	if aiming_with_cursor:
		course_camera.set_focus_position(focus, true)
	else:
		course_camera.set_follow_motion(focus, ball.velocity)


func _toggle_pause() -> void:
	prototype_paused = not prototype_paused
	get_tree().paused = prototype_paused
	hud.set_paused(prototype_paused)
	if audio_feedback != null:
		audio_feedback.set_game_paused(prototype_paused)


func _update_hud() -> void:
	if hud == null or shot_controller == null:
		return
	hud.update_game(
		strokes,
		hole.get_par(),
		shot_controller.power_value,
		shot_controller.accuracy_value,
		shot_controller.state,
		int(round(ball.global_position.distance_to(shot_controller.cursor_position) / PIXELS_PER_METER * 10.0))
	)


func _update_controller_status(id: int, device_name: String, guid: String) -> void:
	if hud == null:
		return
	if id < 0:
		hud.set_controller_status("KEIN CONTROLLER\nTastatur und Maus aktiv")
		if shot_controller != null:
			shot_controller.cancel_shot()
	else:
		var short_guid := guid.left(12) + "..." if guid.length() > 15 else guid
		hud.set_controller_status("CONTROLLER %d\n%s\n%s" % [id, device_name, short_guid])


func _on_calibration_updated(_prompt: String) -> void:
	diagnostics_visible = true
	hud.set_diagnostics(true, ControllerSupport.get_diagnostics_text())


func _on_calibration_finished(_guid: String) -> void:
	diagnostics_visible = true
	hud.set_diagnostics(true, ControllerSupport.get_diagnostics_text())


func _create_audio() -> void:
	audio_feedback = PrototypeAudio.new()
	audio_feedback.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(audio_feedback)
