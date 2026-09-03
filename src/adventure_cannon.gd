class_name AdventureCannon
extends Node2D

@export var mechanism_id := &"unnamed_cannon"
@export var required_trigger_id := &""
@export var capture_size := Vector2(24.0, 18.0)
@export var entry_direction := Vector2.RIGHT
@export var landing_position := Vector2.ZERO
@export var landing_velocity := Vector2(55.0, 0.0)
@export var intake_seconds := 0.20
@export var ignition_seconds := 0.12
@export var flight_seconds := 0.55
@export var arc_height := 34.0

var is_enabled := false
var is_busy := false
var capture_area: Area2D
var shutter_collision: CollisionShape2D
var _flash_time := 0.0


func _ready() -> void:
	z_index = 2
	entry_direction = entry_direction.normalized()
	capture_area = Area2D.new()
	capture_area.collision_layer = 0
	capture_area.collision_mask = 1
	capture_area.monitoring = true
	capture_area.monitorable = false
	var capture_collision := CollisionShape2D.new()
	var capture_shape := RectangleShape2D.new()
	capture_shape.size = capture_size
	capture_collision.shape = capture_shape
	capture_area.add_child(capture_collision)
	capture_area.body_entered.connect(_on_body_entered)
	add_child(capture_area)

	var shutter := StaticBody2D.new()
	shutter.collision_layer = 2
	shutter.collision_mask = 0
	shutter.set_meta("feedback_kind", &"cannon_locked")
	shutter_collision = CollisionShape2D.new()
	var shutter_shape := RectangleShape2D.new()
	shutter_shape.size = capture_size
	shutter_collision.shape = shutter_shape
	shutter.add_child(shutter_collision)
	add_child(shutter)
	reset_state()


func _process(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		queue_redraw()


func set_enabled(value: bool) -> void:
	is_enabled = value
	if shutter_collision != null:
		shutter_collision.set_deferred("disabled", value)
	queue_redraw()


func reset_state() -> void:
	is_busy = false
	_flash_time = 0.0
	set_enabled(required_trigger_id == &"")


func can_capture_ball(ball: PrototypeBall) -> bool:
	if not is_enabled or is_busy or not ball.moving or ball.is_cannon_sequence_active():
		return false
	if ball.velocity.length() < PrototypeBall.STOP_SPEED:
		return false
	return ball.velocity.normalized().dot(entry_direction) >= 0.35


func _on_body_entered(body: Node2D) -> void:
	if not body is PrototypeBall:
		return
	var ball := body as PrototypeBall
	if not can_capture_ball(ball):
		return
	is_busy = true
	if not ball.cannon_feedback.is_connected(_on_ball_cannon_feedback):
		ball.cannon_feedback.connect(_on_ball_cannon_feedback)
	ball.start_cannon_sequence(
		mechanism_id,
		global_position,
		landing_position,
		intake_seconds,
		ignition_seconds,
		flight_seconds,
		arc_height,
		landing_velocity
	)


func _on_ball_cannon_feedback(kind: StringName, source_id: StringName, _position: Vector2, _direction: Vector2) -> void:
	if source_id != mechanism_id:
		return
	if kind == &"cannon_fire":
		_flash_time = 0.12
		queue_redraw()
	elif kind == &"cannon_land":
		is_busy = false


func _draw() -> void:
	var direction := (landing_position - global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var perpendicular := direction.orthogonal()
	var body_color := Color("#72cfad") if is_enabled else Color("#626c75")
	var outline := Color("#16252c")
	var barrel_start := -direction * 8.0
	var barrel_end := direction * 24.0
	draw_line(barrel_start + perpendicular * 6.0, barrel_end + perpendicular * 6.0, outline, 10.0)
	draw_line(barrel_start - perpendicular * 6.0, barrel_end - perpendicular * 6.0, outline, 10.0)
	draw_line(barrel_start, barrel_end, body_color, 14.0)
	draw_circle(-direction * 10.0, 11.0, outline)
	draw_circle(-direction * 10.0, 8.0, body_color)
	var capture_rect := Rect2(-capture_size * 0.5, capture_size)
	draw_rect(capture_rect, Color("#8ff3cf") if is_enabled else Color("#ed6d62"), false, 1.0)
	draw_circle(-direction * 10.0, 2.5, Color("#e8f4d0") if is_enabled else Color("#ff8877"))
	if _flash_time > 0.0:
		var muzzle := barrel_end + direction * 5.0
		var flash := PackedVector2Array([
			muzzle + direction * 10.0,
			muzzle + perpendicular * 5.0,
			muzzle - perpendicular * 5.0,
		])
		draw_colored_polygon(flash, Color("#fff0a0"))
