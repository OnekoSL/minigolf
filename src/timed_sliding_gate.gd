class_name TimedSlidingGate
extends MovingObstacle

@export var gate_size := Vector2(10.0, 86.0)
@export var open_offset := Vector2(0.0, -100.0)
@export var cycle_seconds := 2.8
@export var transition_seconds := 0.25
@export var open_hold_seconds := 1.0
@export var phase_offset_seconds := 0.0

var wake_area: Area2D
var closed_position := Vector2.ZERO
var elapsed_seconds := 0.0
var linear_velocity := Vector2.ZERO


func _ready() -> void:
	feedback_kind = &"gate"
	collision_layer = 2
	collision_mask = 0
	# Motion is advanced in _physics_process already; direct transforms keep the
	# visual body, collision body and deterministic test state in lockstep.
	sync_to_physics = false
	closed_position = position
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = gate_size
	collision.shape = shape
	add_child(collision)
	wake_area = Area2D.new()
	wake_area.collision_layer = 0
	wake_area.collision_mask = 1
	wake_area.monitoring = true
	wake_area.monitorable = false
	var wake_collision := CollisionShape2D.new()
	var wake_shape := RectangleShape2D.new()
	wake_shape.size = gate_size + Vector2(10.0, 10.0)
	wake_collision.shape = wake_shape
	wake_area.add_child(wake_collision)
	wake_area.body_entered.connect(_on_wake_area_body_entered)
	add_child(wake_area)
	reset_motion()
	queue_redraw()


func _physics_process(delta: float) -> void:
	advance_motion(delta)
	_wake_overlapping_balls()


func advance_motion(delta: float) -> void:
	if delta <= 0.0:
		return
	var previous_position := position
	elapsed_seconds = fposmod(elapsed_seconds + delta, cycle_seconds)
	position = closed_position + open_offset * openness_at_time(
		elapsed_seconds + phase_offset_seconds,
		cycle_seconds,
		transition_seconds,
		open_hold_seconds
	)
	linear_velocity = (position - previous_position) / delta


func reset_motion() -> void:
	elapsed_seconds = 0.0
	linear_velocity = Vector2.ZERO
	position = closed_position + open_offset * openness_at_time(
		phase_offset_seconds,
		cycle_seconds,
		transition_seconds,
		open_hold_seconds
	)


func get_velocity_at_world_point(_world_point: Vector2) -> Vector2:
	return linear_velocity


func get_contact_normal(world_point: Vector2) -> Vector2:
	var local_point := to_local(world_point)
	var half_size := gate_size * 0.5
	var x_penetration := half_size.x + PrototypeBall.RADIUS - absf(local_point.x)
	var y_penetration := half_size.y + PrototypeBall.RADIUS - absf(local_point.y)
	if x_penetration < y_penetration:
		return Vector2(signf(local_point.x), 0.0).rotated(global_rotation)
	return Vector2(0.0, signf(local_point.y) if not is_zero_approx(local_point.y) else 1.0).rotated(global_rotation)


func _on_wake_area_body_entered(body: Node2D) -> void:
	_try_move_ball(body)


func _wake_overlapping_balls() -> void:
	if wake_area == null or linear_velocity.is_zero_approx():
		return
	for body in wake_area.get_overlapping_bodies():
		_try_move_ball(body)


func _try_move_ball(body: Node2D) -> void:
	if not body is PrototypeBall:
		return
	var ball := body as PrototypeBall
	var normal := get_contact_normal(ball.global_position)
	if (linear_velocity - ball.velocity).dot(normal) <= 2.0:
		return
	ball.apply_moving_obstacle_contact(
		linear_velocity,
		normal,
		get_impulse_multiplier(),
		get_minimum_kick_speed(),
		feedback_kind
	)


func _draw() -> void:
	var rect := Rect2(-gate_size * 0.5, gate_size)
	draw_rect(rect, Color("#76b8c4"), true)
	draw_rect(rect, Color("#243c4a"), false, 2.0)
	for y in range(int(rect.position.y) + 6, int(rect.end.y), 12):
		draw_line(Vector2(rect.position.x + 2, y), Vector2(rect.end.x - 2, y), Color("#d7e7df"), 1.0)


static func openness_at_time(
	time: float,
	cycle: float,
	transition: float,
	open_hold: float
) -> float:
	if cycle <= 0.0:
		return 0.0
	var closed_hold := maxf(0.0, cycle - open_hold - transition * 2.0)
	var phase := fposmod(time, cycle)
	if phase < closed_hold:
		return 0.0
	phase -= closed_hold
	if phase < transition:
		return phase / transition if transition > 0.0 else 1.0
	phase -= transition
	if phase < open_hold:
		return 1.0
	phase -= open_hold
	if phase < transition:
		return 1.0 - phase / transition if transition > 0.0 else 0.0
	return 0.0
