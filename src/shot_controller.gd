class_name ShotController
extends Node2D

signal state_changed(state: int)
signal swing_started(direction: Vector2, speed: float, accuracy: float, perfect: bool)
signal shot_committed(direction: Vector2, speed: float, accuracy: float)
signal cancelled()

enum ShotState { AIMING, POWER, ACCURACY, ARMED, SWINGING, BALL_MOVING, HOLE_COMPLETE }

@export var cursor_speed := 120.0
@export var power_cycle_seconds := 4.0
@export var accuracy_cycle_seconds := 2.4
@export var minimum_power := 0.05
@export var minimum_ball_speed := 60.0
@export var maximum_ball_speed := 420.0
@export var perfect_accuracy_window := 0.05
@export var maximum_error_degrees := 8.0
@export var swing_contact_delay := 0.10

var state := ShotState.AIMING
var power_value := minimum_power
var accuracy_value := 0.0
var cursor_position := Vector2.ZERO
var aiming_bounds := Rect2(176, 16, 448, 328)
var ball: PrototypeBall
var initial_aim_offset := Vector2(60.0, 0.0)

var _meter_elapsed := 0.0
var _locked_power := minimum_power
var _locked_accuracy := 0.0
var _swing_generation := 0
var _swing_elapsed := 0.0
var _pending_direction := Vector2.RIGHT
var _pending_speed := 0.0
var _pending_accuracy := 0.0


func _ready() -> void:
	ControllerSupport.focus_changed.connect(_on_focus_changed)


func configure(target_ball: PrototypeBall, bounds: Rect2, aim_offset := Vector2(60.0, 0.0)) -> void:
	ball = target_ball
	aiming_bounds = bounds
	initial_aim_offset = aim_offset
	reset_aim()


func reset_aim() -> void:
	if ball == null:
		return
	_swing_generation += 1
	cursor_position = _clamp_cursor(ball.global_position + initial_aim_offset)
	power_value = minimum_power
	accuracy_value = 0.0
	_meter_elapsed = 0.0
	_set_state(ShotState.AIMING)
	queue_redraw()


func _process(delta: float) -> void:
	if not ControllerSupport.focused:
		return
	if state == ShotState.BALL_MOVING and ball != null and not ball.moving:
		reset_aim()
		return
	if state == ShotState.AIMING:
		var input_vector: Vector2 = ControllerSupport.get_aim_vector()
		advance_aim(input_vector, delta)
	elif state in [ShotState.POWER, ShotState.ACCURACY]:
		advance_meter(delta)
	elif state == ShotState.SWINGING:
		advance_swing(delta)


func _unhandled_input(event: InputEvent) -> void:
	if ControllerSupport.is_calibrating():
		return
	if event is InputEventKey and event.echo:
		return
	if event is InputEventMouseMotion and state == ShotState.AIMING:
		cursor_position = _clamp_cursor(get_global_mouse_position())
		queue_redraw()
		return
	if ControllerSupport.event_is_pressed(event, &"shot_cancel"):
		cancel_shot()
		get_viewport().set_input_as_handled()
		return
	if ControllerSupport.event_is_pressed(event, &"shot_action") and state != ShotState.HOLE_COMPLETE:
		action_pressed()
		get_viewport().set_input_as_handled()
		return
	if ControllerSupport.event_is_released(event, &"shot_action"):
		action_released()
		get_viewport().set_input_as_handled()


func action_pressed() -> void:
	match state:
		ShotState.AIMING:
			_meter_elapsed = 0.0
			power_value = minimum_power
			_set_state(ShotState.POWER)
		ShotState.POWER:
			_locked_power = power_value
			_meter_elapsed = 0.0
			accuracy_value = -1.0
			_set_state(ShotState.ACCURACY)
		ShotState.ACCURACY:
			_locked_accuracy = accuracy_value
			_set_state(ShotState.ARMED)


func action_released() -> void:
	if state != ShotState.ARMED or ball == null:
		return
	var direction := (cursor_position - ball.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var error := accuracy_to_angle(_locked_accuracy)
	direction = direction.rotated(error)
	var speed := lerpf(minimum_ball_speed, maximum_ball_speed, _locked_power)
	_swing_generation += 1
	_swing_elapsed = 0.0
	_pending_direction = direction
	_pending_speed = speed
	_pending_accuracy = _locked_accuracy
	_set_state(ShotState.SWINGING)
	swing_started.emit(direction, speed, _locked_accuracy, absf(_locked_accuracy) <= perfect_accuracy_window)


func cancel_shot() -> void:
	if state not in [ShotState.POWER, ShotState.ACCURACY, ShotState.ARMED, ShotState.SWINGING]:
		return
	_swing_generation += 1
	_meter_elapsed = 0.0
	power_value = minimum_power
	accuracy_value = 0.0
	_set_state(ShotState.AIMING)
	cancelled.emit()


func notify_ball_stopped(_position: Vector2) -> void:
	if state == ShotState.HOLE_COMPLETE:
		return
	reset_aim()


func notify_external_motion_started() -> void:
	if state == ShotState.AIMING:
		_set_state(ShotState.BALL_MOVING)


func notify_hole_complete() -> void:
	_swing_generation += 1
	_set_state(ShotState.HOLE_COMPLETE)


func advance_meter(delta: float) -> void:
	_meter_elapsed += delta
	if state == ShotState.POWER:
		power_value = power_at_time(_meter_elapsed)
	elif state == ShotState.ACCURACY:
		accuracy_value = accuracy_at_time(_meter_elapsed)


func advance_swing(delta: float) -> void:
	if state != ShotState.SWINGING:
		return
	_swing_elapsed += maxf(delta, 0.0)
	if _swing_elapsed + 0.000001 < swing_contact_delay:
		return
	_set_state(ShotState.BALL_MOVING)
	shot_committed.emit(_pending_direction, _pending_speed, _pending_accuracy)


func advance_aim(input_vector: Vector2, delta: float) -> void:
	if state != ShotState.AIMING or input_vector == Vector2.ZERO:
		return
	cursor_position = _clamp_cursor(cursor_position + input_vector.limit_length(1.0) * cursor_speed * delta)
	queue_redraw()


func power_at_time(time: float) -> float:
	var phase := fposmod(time, power_cycle_seconds) / power_cycle_seconds
	var triangle := 1.0 - absf(phase * 2.0 - 1.0)
	return lerpf(minimum_power, 1.0, triangle)


func accuracy_at_time(time: float) -> float:
	var phase := fposmod(time, accuracy_cycle_seconds) / accuracy_cycle_seconds
	return -1.0 + (1.0 - absf(phase * 2.0 - 1.0)) * 2.0


func accuracy_to_angle(value: float) -> float:
	if absf(value) <= perfect_accuracy_window:
		return 0.0
	var normalized := inverse_lerp(perfect_accuracy_window, 1.0, absf(value))
	var degrees := pow(normalized, 1.4) * maximum_error_degrees * signf(value)
	return deg_to_rad(degrees)


func get_locked_power() -> float:
	return _locked_power


func get_locked_accuracy() -> float:
	return _locked_accuracy


func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)
	queue_redraw()


func _clamp_cursor(value: Vector2) -> Vector2:
	return Vector2(
		clampf(value.x, aiming_bounds.position.x + 7.0, aiming_bounds.end.x - 7.0),
		clampf(value.y, aiming_bounds.position.y + 7.0, aiming_bounds.end.y - 7.0)
	)


func _on_focus_changed(has_focus: bool) -> void:
	if not has_focus:
		cancel_shot()


func _draw() -> void:
	if ball == null or state in [ShotState.SWINGING, ShotState.BALL_MOVING, ShotState.HOLE_COMPLETE]:
		return
	var start := ball.global_position
	var direction := (cursor_position - start).normalized()
	draw_dashed_line(start, cursor_position, Color(0.93, 0.92, 0.66, 0.75), 1.0, 5.0)
	draw_circle(cursor_position, 6.0, Color(0.05, 0.08, 0.10, 0.35), false, 2.0)
	draw_line(cursor_position - Vector2(9, 0), cursor_position + Vector2(9, 0), Color("#f5e99a"), 1.0)
	draw_line(cursor_position - Vector2(0, 9), cursor_position + Vector2(0, 9), Color("#f5e99a"), 1.0)
	if direction != Vector2.ZERO:
		draw_line(start, start + direction * 14.0, Color("#ffffff"), 2.0)
