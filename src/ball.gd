class_name PrototypeBall
extends CharacterBody2D

signal launched()
signal stopped(at_position: Vector2)
signal wall_hit(intensity: float, contact_position: Vector2, contact_normal: Vector2, kind: StringName)
signal hazard_entered(hazard_type: String)
signal holed(stroke_count: int)
signal external_motion_started()
signal surface_changed(surface_type: int)
signal cannon_feedback(kind: StringName, mechanism_id: StringName, world_position: Vector2, direction: Vector2)

const RADIUS := 5.0
const GRASS_DECELERATION := 120.0
const STOP_SPEED := 3.0
const STOP_SETTLE_TIME := 0.25
const STUCK_DISTANCE_PER_TICK := 0.05
const STUCK_SETTLE_TIME := 0.40
const WALL_RESTITUTION := 0.82
const WALL_SETTLE_NORMAL_SPEED := 28.0
const REPEATED_WALL_SETTLE_NORMAL_SPEED := 140.0
const SAME_WALL_NORMAL_DOT := 0.94
const MAX_HOLE_SPEED := 120.0
const HOLE_RADIUS := 7.0

var zones: Array[SurfaceZone] = []
var hole_position := Vector2.ZERO
var moving := false
var shot_origin := Vector2.ZERO
var current_stroke_count := 0
var current_surface_type := -1
var _slow_time := 0.0
var _hazard_generation := 0
var _stuck_time := 0.0
var _last_motion_position := Vector2.ZERO
var _last_static_wall_normal := Vector2.ZERO
var _same_wall_hit_count := 0
var _cannon_active := false
var _cannon_id := &""
var _cannon_elapsed := 0.0
var _cannon_intake_seconds := 0.0
var _cannon_ignition_seconds := 0.0
var _cannon_flight_seconds := 0.0
var _cannon_arc_height := 0.0
var _cannon_start := Vector2.ZERO
var _cannon_capture := Vector2.ZERO
var _cannon_landing := Vector2.ZERO
var _cannon_exit_velocity := Vector2.ZERO
var _cannon_fire_emitted := false
var _visual_lift := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func configure_environment(surface_zones: Array[SurfaceZone], target_hole: Vector2) -> void:
	zones = surface_zones
	hole_position = target_hole
	_set_current_surface_type(int(_surface_at(global_position).get("type", -1)))


func launch(direction: Vector2, speed: float, stroke_count: int) -> void:
	if moving:
		return
	_hazard_generation += 1
	shot_origin = global_position
	current_stroke_count = stroke_count
	velocity = direction.normalized() * speed
	moving = true
	_slow_time = 0.0
	_stuck_time = 0.0
	_last_motion_position = global_position
	_reset_wall_contact_memory()
	visible = true
	scale = Vector2.ONE
	launched.emit()


func reset_to(target_position: Vector2) -> void:
	_hazard_generation += 1
	_cancel_cannon_sequence()
	moving = false
	velocity = Vector2.ZERO
	global_position = target_position
	_set_current_surface_type(int(_surface_at(global_position).get("type", -1)))
	visible = true
	scale = Vector2.ONE
	_slow_time = 0.0
	_stuck_time = 0.0
	_last_motion_position = global_position
	_reset_wall_contact_memory()


func _physics_process(delta: float) -> void:
	if not moving:
		return
	if _cannon_active:
		_advance_cannon_sequence(delta)
		return
	var tick_start_position := global_position
	var surface := _surface_at(global_position)
	_set_current_surface_type(int(surface.get("type", -1)))
	if int(surface.get("type", -1)) == SurfaceZone.SurfaceType.WATER:
		_enter_hazard("Wasser")
		return
	velocity = apply_surface_acceleration(
		velocity,
		Vector2(surface.get("acceleration", Vector2.ZERO)),
		delta
	)
	velocity = apply_flow_assist(
		velocity,
		Vector2(surface.get("acceleration", Vector2.ZERO)).normalized(),
		float(surface.get("minimum_flow_speed", 0.0)),
		float(surface.get("maximum_flow_speed", 0.0)),
		float(surface.get("flow_alignment_rate", 0.0)),
		delta
	)
	velocity = apply_flow_centering(
		velocity,
		global_position,
		Vector2(surface.get("center", global_position)),
		Vector2(surface.get("acceleration", Vector2.ZERO)).normalized(),
		float(surface.get("flow_centering_strength", 0.0)),
		delta
	)

	var distance_this_tick := velocity.length() * delta
	var max_step_distance := RADIUS * 0.5
	var steps := maxi(1, ceili(distance_this_tick / max_step_distance))
	var step_delta := delta / float(steps)
	for _step in range(steps):
		var collision := move_and_collide(velocity * step_delta)
		if collision:
			var before := velocity.length()
			var collider_velocity := collision.get_collider_velocity()
			var collider := collision.get_collider()
			var contact_normal := collision.get_normal().normalized()
			var collision_kind := &"wall"
			if collider is MovingObstacle:
				_reset_wall_contact_memory()
				collision_kind = collider.feedback_kind
				collider_velocity = collider.get_velocity_at_world_point(collision.get_position())
				velocity = resolve_rotating_obstacle_collision(
					velocity,
					contact_normal,
					collider_velocity,
					WALL_RESTITUTION,
					collider.get_impulse_multiplier(),
					collider.get_minimum_kick_speed()
				).limit_length(520.0)
			else:
				if collider != null and collider.has_meta("feedback_kind"):
					collision_kind = StringName(collider.get_meta("feedback_kind"))
				var same_wall_hits := _register_static_wall_hit(contact_normal)
				if should_settle_static_wall_contact(velocity, contact_normal, same_wall_hits):
					velocity = remove_inward_wall_velocity(velocity, contact_normal)
				else:
					velocity = calculate_bounce(velocity, contact_normal, WALL_RESTITUTION)
			wall_hit.emit(before, collision.get_position(), contact_normal, collision_kind)
			if not collider is MovingObstacle and velocity.length() < STOP_SPEED:
				_finish_stopped()
				return
		var stepped_surface := _surface_at(global_position)
		if int(stepped_surface.get("type", -1)) == SurfaceZone.SurfaceType.WATER:
			_enter_hazard("Wasser")
			return

	surface = _surface_at(global_position)
	_set_current_surface_type(int(surface.get("type", -1)))
	var deceleration := float(surface.get("deceleration", GRASS_DECELERATION))
	velocity = apply_deceleration(velocity, deceleration, delta)

	if can_capture_hole(global_position.distance_to(hole_position), velocity.length()):
		_capture_hole()
		return

	if global_position.distance_to(tick_start_position) <= STUCK_DISTANCE_PER_TICK:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	_last_motion_position = global_position
	if _stuck_time >= STUCK_SETTLE_TIME:
		_finish_stopped()
		return

	if velocity.length() < STOP_SPEED:
		_slow_time += delta
		if _slow_time >= STOP_SETTLE_TIME:
			_finish_stopped()
	else:
		_slow_time = 0.0


func _surface_at(point: Vector2) -> Dictionary:
	for zone in zones:
		if zone.contains_global_point(point):
			return zone.get_surface_data()
	return {
		"type": -1,
		"deceleration": GRASS_DECELERATION,
		"acceleration": Vector2.ZERO,
		"minimum_flow_speed": 0.0,
		"maximum_flow_speed": 0.0,
		"flow_alignment_rate": 0.0,
		"flow_centering_strength": 0.0,
		"center": global_position,
	}


func _enter_hazard(hazard_type: String) -> void:
	if not moving:
		return
	moving = false
	velocity = Vector2.ZERO
	visible = false
	_hazard_generation += 1
	var generation := _hazard_generation
	hazard_entered.emit(hazard_type)
	await get_tree().create_timer(0.6).timeout
	if generation != _hazard_generation:
		return
	global_position = shot_origin
	visible = true
	scale = Vector2.ONE
	stopped.emit(global_position)


func _finish_stopped() -> void:
	moving = false
	velocity = Vector2.ZERO
	_slow_time = 0.0
	_stuck_time = 0.0
	stopped.emit(global_position)


func _register_static_wall_hit(normal: Vector2) -> int:
	var normalized_normal := normal.normalized()
	if not _last_static_wall_normal.is_zero_approx() and normalized_normal.dot(_last_static_wall_normal) >= SAME_WALL_NORMAL_DOT:
		_same_wall_hit_count += 1
	else:
		_same_wall_hit_count = 1
	_last_static_wall_normal = normalized_normal
	return _same_wall_hit_count


func _reset_wall_contact_memory() -> void:
	_last_static_wall_normal = Vector2.ZERO
	_same_wall_hit_count = 0


func _set_current_surface_type(value: int) -> void:
	if current_surface_type == value:
		return
	current_surface_type = value
	surface_changed.emit(current_surface_type)


func _capture_hole() -> void:
	_cancel_cannon_sequence()
	moving = false
	velocity = Vector2.ZERO
	global_position = hole_position
	_hazard_generation += 1
	var generation := _hazard_generation
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if generation != _hazard_generation:
		return
	visible = false
	holed.emit(current_stroke_count)


func apply_moving_obstacle_contact(
	surface_velocity: Vector2,
	contact_normal: Vector2,
	impulse_multiplier: float,
	minimum_kick_speed: float,
	obstacle_kind: StringName = &"windmill"
) -> bool:
	var normal := contact_normal.normalized()
	var relative_velocity := velocity - surface_velocity
	if relative_velocity.dot(normal) >= -2.0:
		return false
	var was_moving := moving
	var previous_velocity := velocity
	var transferred_velocity := resolve_rotating_obstacle_collision(
		velocity,
		normal,
		surface_velocity,
		WALL_RESTITUTION,
		impulse_multiplier,
		minimum_kick_speed
	).limit_length(520.0)
	if not was_moving:
		shot_origin = global_position
	velocity = transferred_velocity
	moving = true
	_slow_time = 0.0
	_stuck_time = 0.0
	_last_motion_position = global_position
	wall_hit.emit(
		maxf(transferred_velocity.length(), (transferred_velocity - previous_velocity).length()),
		global_position,
		normal,
		obstacle_kind
	)
	if not was_moving:
		external_motion_started.emit()
	return true


func is_cannon_sequence_active() -> bool:
	return _cannon_active


func start_cannon_sequence(
	mechanism_id: StringName,
	capture_position: Vector2,
	landing_position: Vector2,
	intake_seconds: float,
	ignition_seconds: float,
	flight_seconds: float,
	arc_height: float,
	exit_velocity: Vector2
) -> bool:
	if not moving or _cannon_active:
		return false
	_cannon_active = true
	_cannon_id = mechanism_id
	_cannon_elapsed = 0.0
	_cannon_intake_seconds = maxf(0.001, intake_seconds)
	_cannon_ignition_seconds = maxf(0.0, ignition_seconds)
	_cannon_flight_seconds = maxf(0.001, flight_seconds)
	_cannon_arc_height = maxf(0.0, arc_height)
	_cannon_start = global_position
	_cannon_capture = capture_position
	_cannon_landing = landing_position
	_cannon_exit_velocity = exit_velocity
	_cannon_fire_emitted = false
	_visual_lift = 0.0
	velocity = Vector2.ZERO
	_slow_time = 0.0
	_stuck_time = 0.0
	collision_mask = 0
	cannon_feedback.emit(&"cannon_load", _cannon_id, global_position, (_cannon_landing - _cannon_capture).normalized())
	queue_redraw()
	return true


func advance_cannon_sequence(delta: float) -> void:
	if _cannon_active:
		_advance_cannon_sequence(delta)


func _advance_cannon_sequence(delta: float) -> void:
	_cannon_elapsed += maxf(0.0, delta)
	var flight_start := _cannon_intake_seconds + _cannon_ignition_seconds
	var total_duration := flight_start + _cannon_flight_seconds
	if _cannon_elapsed < _cannon_intake_seconds:
		var intake_progress := clampf(_cannon_elapsed / _cannon_intake_seconds, 0.0, 1.0)
		global_position = _cannon_start.lerp(_cannon_capture, intake_progress)
		_visual_lift = 0.0
		queue_redraw()
		return
	if _cannon_elapsed < flight_start:
		global_position = _cannon_capture
		_visual_lift = 0.0
		queue_redraw()
		return
	if not _cannon_fire_emitted:
		_cannon_fire_emitted = true
		cannon_feedback.emit(
			&"cannon_fire",
			_cannon_id,
			_cannon_capture,
			(_cannon_landing - _cannon_capture).normalized()
		)
	if _cannon_elapsed < total_duration:
		var flight_progress := clampf((_cannon_elapsed - flight_start) / _cannon_flight_seconds, 0.0, 1.0)
		global_position = _cannon_capture.lerp(_cannon_landing, flight_progress)
		_visual_lift = 4.0 * _cannon_arc_height * flight_progress * (1.0 - flight_progress)
		queue_redraw()
		return
	global_position = _cannon_landing
	velocity = _cannon_exit_velocity
	_visual_lift = 0.0
	collision_mask = 2
	_cannon_active = false
	_set_current_surface_type(int(_surface_at(global_position).get("type", -1)))
	_last_motion_position = global_position
	var landed_id := _cannon_id
	_cannon_id = &""
	cannon_feedback.emit(
		&"cannon_land",
		landed_id,
		global_position,
		velocity.normalized() if not velocity.is_zero_approx() else Vector2.RIGHT
	)
	queue_redraw()
	if velocity.length() < STOP_SPEED:
		_finish_stopped()


func _cancel_cannon_sequence() -> void:
	_cannon_active = false
	_cannon_id = &""
	_cannon_elapsed = 0.0
	_cannon_fire_emitted = false
	_visual_lift = 0.0
	collision_mask = 2
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 1.0, Color(0.05, 0.08, 0.10, 0.45))
	var ball_center := Vector2(0.0, -_visual_lift)
	draw_circle(ball_center + Vector2(-1, -1), RADIUS, Color("#f5f0d7"))
	draw_circle(ball_center + Vector2(-2, -2), 1.2, Color("#ffffff"))


static func apply_deceleration(input_velocity: Vector2, deceleration: float, delta: float) -> Vector2:
	return input_velocity.move_toward(Vector2.ZERO, deceleration * delta)


static func apply_surface_acceleration(input_velocity: Vector2, acceleration: Vector2, delta: float) -> Vector2:
	return input_velocity + acceleration * delta


static func apply_flow_assist(
	input_velocity: Vector2,
	direction: Vector2,
	minimum_speed: float,
	maximum_speed: float,
	alignment_rate: float,
	delta: float
) -> Vector2:
	if direction == Vector2.ZERO or minimum_speed <= 0.0:
		return input_velocity
	var normalized_direction := direction.normalized()
	var input_speed := input_velocity.length()
	var forward_speed := input_velocity.dot(normalized_direction)
	if input_speed > 0.001 and forward_speed < 0.0:
		return input_velocity
	if input_speed <= 0.001:
		return normalized_direction * minimum_speed
	var target_speed := maxf(input_speed, minimum_speed)
	if maximum_speed > 0.0:
		target_speed = minf(target_speed, maximum_speed)
	var alignment_weight := 1.0 - exp(-alignment_rate * delta) if alignment_rate > 0.0 else 0.0
	var result := input_velocity.lerp(normalized_direction * target_speed, alignment_weight)
	if input_speed < minimum_speed:
		var assisted_forward_speed := result.dot(normalized_direction)
		if assisted_forward_speed < minimum_speed:
			result += normalized_direction * (minimum_speed - assisted_forward_speed)
	return result


static func apply_flow_centering(
	input_velocity: Vector2,
	position: Vector2,
	center: Vector2,
	direction: Vector2,
	centering_strength: float,
	delta: float
) -> Vector2:
	if direction == Vector2.ZERO or centering_strength <= 0.0:
		return input_velocity
	var normalized_direction := direction.normalized()
	var offset := position - center
	var lateral_offset := offset - normalized_direction * offset.dot(normalized_direction)
	return input_velocity - lateral_offset * centering_strength * delta


static func calculate_bounce(input_velocity: Vector2, normal: Vector2, restitution: float) -> Vector2:
	return input_velocity.bounce(normal) * restitution


static func should_settle_static_wall_contact(input_velocity: Vector2, normal: Vector2, same_wall_hits: int) -> bool:
	var inward_speed := maxf(0.0, -input_velocity.dot(normal.normalized()))
	return inward_speed <= WALL_SETTLE_NORMAL_SPEED \
		or (same_wall_hits >= 2 and inward_speed <= REPEATED_WALL_SETTLE_NORMAL_SPEED)


static func remove_inward_wall_velocity(input_velocity: Vector2, normal: Vector2) -> Vector2:
	var normalized_normal := normal.normalized()
	var normal_speed := input_velocity.dot(normalized_normal)
	if normal_speed >= 0.0:
		return input_velocity
	return input_velocity - normalized_normal * normal_speed


static func resolve_moving_surface_collision(
	input_velocity: Vector2,
	normal: Vector2,
	surface_velocity: Vector2,
	restitution: float
) -> Vector2:
	var relative_velocity := input_velocity - surface_velocity
	return relative_velocity.bounce(normal) * restitution + surface_velocity


static func resolve_rotating_obstacle_collision(
	input_velocity: Vector2,
	normal: Vector2,
	surface_velocity: Vector2,
	restitution: float,
	impulse_multiplier: float,
	minimum_outward_speed: float
) -> Vector2:
	var base_result := resolve_moving_surface_collision(
		input_velocity, normal, surface_velocity, restitution
	)
	var result := input_velocity + (base_result - input_velocity) * impulse_multiplier
	var outward_speed := result.dot(normal)
	if outward_speed < minimum_outward_speed:
		result += normal * (minimum_outward_speed - outward_speed)
	return result


static func can_capture_hole(distance_to_hole: float, speed: float) -> bool:
	return distance_to_hole <= HOLE_RADIUS and speed <= MAX_HOLE_SPEED
