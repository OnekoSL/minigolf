class_name CourseCamera
extends Camera2D

@export var follow_speed := 5.0
@export var gameplay_screen_offset := Vector2(80.0, 0.0)
@export var viewport_size := Vector2(640.0, 360.0)
@export var aiming_deadzone := Rect2(220.0, 52.0, 360.0, 256.0)
@export var ball_lookahead_seconds := 0.12
@export var maximum_ball_lookahead := 48.0
@export var lookahead_smoothing := 7.0
@export var impact_threshold := 220.0
@export var maximum_impact_intensity := 520.0
@export var maximum_impact_offset := 2.0
@export var impact_decay_seconds := 0.12

var follow_target: Node2D
var center_bounds := Rect2(Vector2(320.0, 180.0), Vector2.ZERO)
var focus_position := Vector2.ZERO
var has_focus_position := false
var use_aiming_deadzone := false
var lookahead_target := Vector2.ZERO
var lookahead_current := Vector2.ZERO
var impact_offset := Vector2.ZERO


func configure(target: Node2D, bounds: Rect2) -> void:
	follow_target = target
	center_bounds = bounds
	focus_position = target.global_position if target != null else bounds.position
	has_focus_position = true
	lookahead_target = Vector2.ZERO
	lookahead_current = Vector2.ZERO
	impact_offset = Vector2.ZERO
	offset = Vector2.ZERO


func set_focus_position(world_position: Vector2, keep_inside_aiming_area := false) -> void:
	focus_position = world_position
	has_focus_position = true
	use_aiming_deadzone = keep_inside_aiming_area
	lookahead_target = Vector2.ZERO


func set_follow_motion(world_position: Vector2, velocity: Vector2) -> void:
	focus_position = world_position
	has_focus_position = true
	use_aiming_deadzone = false
	lookahead_target = lookahead_for_velocity(velocity, ball_lookahead_seconds, maximum_ball_lookahead)


func add_impact(contact_normal: Vector2, intensity: float) -> void:
	impact_offset = impact_for_collision(
		contact_normal,
		intensity,
		impact_threshold,
		maximum_impact_intensity,
		maximum_impact_offset
	)


func snap_to_target() -> void:
	if not has_focus_position and follow_target == null:
		return
	var target_position := focus_position if has_focus_position else follow_target.global_position
	global_position = _desired_position(target_position).round()
	offset = Vector2.ZERO


func _process(delta: float) -> void:
	if not has_focus_position and follow_target == null:
		return
	var target_position := focus_position if has_focus_position else follow_target.global_position
	var lookahead_weight := 1.0 - exp(-lookahead_smoothing * delta)
	lookahead_current = lookahead_current.lerp(lookahead_target, lookahead_weight)
	var desired := _desired_position(target_position)
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight).round()
	if impact_decay_seconds > 0.0:
		impact_offset = impact_offset.move_toward(Vector2.ZERO, maximum_impact_offset / impact_decay_seconds * delta)
	else:
		impact_offset = Vector2.ZERO
	offset = impact_offset.round()


func _desired_position(target_position: Vector2) -> Vector2:
	if use_aiming_deadzone:
		return position_for_deadzone(
			global_position,
			target_position,
			center_bounds,
			viewport_size,
			aiming_deadzone
		)
	return clamp_to_bounds(target_position + lookahead_current - gameplay_screen_offset, center_bounds)


static func clamp_to_bounds(value: Vector2, bounds: Rect2) -> Vector2:
	return Vector2(
		clampf(value.x, bounds.position.x, bounds.end.x),
		clampf(value.y, bounds.position.y, bounds.end.y)
	)


static func position_for_deadzone(
	current_position: Vector2,
	target_position: Vector2,
	bounds: Rect2,
	internal_viewport_size: Vector2,
	deadzone: Rect2
) -> Vector2:
	var screen_position := target_position - current_position + internal_viewport_size * 0.5
	var desired := current_position
	if screen_position.x < deadzone.position.x:
		desired.x += screen_position.x - deadzone.position.x
	elif screen_position.x > deadzone.end.x:
		desired.x += screen_position.x - deadzone.end.x
	if screen_position.y < deadzone.position.y:
		desired.y += screen_position.y - deadzone.position.y
	elif screen_position.y > deadzone.end.y:
		desired.y += screen_position.y - deadzone.end.y
	return clamp_to_bounds(desired, bounds)


static func lookahead_for_velocity(velocity: Vector2, seconds: float, maximum_distance: float) -> Vector2:
	return (velocity * seconds).limit_length(maximum_distance)


static func impact_for_collision(
	contact_normal: Vector2,
	intensity: float,
	threshold: float,
	maximum_intensity: float,
	maximum_offset: float
) -> Vector2:
	if contact_normal == Vector2.ZERO or intensity < threshold:
		return Vector2.ZERO
	var strength := inverse_lerp(threshold, maximum_intensity, minf(intensity, maximum_intensity))
	return contact_normal.normalized() * lerpf(0.5, maximum_offset, strength)
