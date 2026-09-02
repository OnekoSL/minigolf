class_name RotatingObstacle
extends MovingObstacle

@export var seconds_per_revolution := 2.4
@export var blade_size := Vector2(72.0, 8.0)
@export var impulse_multiplier := 1.25
@export var minimum_kick_speed := 55.0

var wake_area: Area2D
var start_rotation := 0.0


func _ready() -> void:
	feedback_kind = &"windmill"
	start_rotation = rotation
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = blade_size
	collision.shape = shape
	add_child(collision)
	wake_area = Area2D.new()
	wake_area.collision_layer = 0
	wake_area.collision_mask = 1
	wake_area.monitoring = true
	wake_area.monitorable = false
	var wake_collision := CollisionShape2D.new()
	var wake_shape := RectangleShape2D.new()
	wake_shape.size = blade_size + Vector2(10, 10)
	wake_collision.shape = wake_shape
	wake_area.add_child(wake_collision)
	wake_area.body_entered.connect(_on_wake_area_body_entered)
	add_child(wake_area)
	queue_redraw()


func _physics_process(delta: float) -> void:
	rotation += TAU * delta / seconds_per_revolution
	_wake_overlapping_stationary_balls()


func get_angular_speed() -> float:
	return TAU / seconds_per_revolution


func get_velocity_at_world_point(world_point: Vector2) -> Vector2:
	var radius_vector := world_point - global_position
	return radius_vector.orthogonal() * get_angular_speed()


func get_impulse_multiplier() -> float:
	return impulse_multiplier


func get_minimum_kick_speed() -> float:
	return minimum_kick_speed


func reset_motion() -> void:
	rotation = start_rotation


func get_contact_normal(world_point: Vector2) -> Vector2:
	var local_point := to_local(world_point)
	var half_size := blade_size * 0.5
	var x_penetration := half_size.x + PrototypeBall.RADIUS - absf(local_point.x)
	var y_penetration := half_size.y + PrototypeBall.RADIUS - absf(local_point.y)
	var local_normal: Vector2
	if x_penetration < y_penetration:
		local_normal = Vector2(signf(local_point.x), 0.0)
	else:
		local_normal = Vector2(0.0, signf(local_point.y))
	if local_normal == Vector2.ZERO:
		local_normal = Vector2.DOWN
	return local_normal.rotated(global_rotation)


func _on_wake_area_body_entered(body: Node2D) -> void:
	_try_wake_ball(body)


func _wake_overlapping_stationary_balls() -> void:
	if wake_area == null:
		return
	for body in wake_area.get_overlapping_bodies():
		_try_wake_ball(body)


func _try_wake_ball(body: Node2D) -> void:
	if not body is PrototypeBall:
		return
	var ball := body as PrototypeBall
	var normal := get_contact_normal(ball.global_position)
	var surface_velocity := get_velocity_at_world_point(ball.global_position)
	var approach_speed: float = (surface_velocity - ball.velocity).dot(normal)
	if approach_speed <= 2.0:
		return
	ball.apply_moving_obstacle_contact(
		surface_velocity,
		normal,
		impulse_multiplier,
		minimum_kick_speed,
		feedback_kind
	)


func _draw() -> void:
	var rect := Rect2(-blade_size * 0.5, blade_size)
	draw_rect(rect, Color("#d9c27b"), true)
	draw_rect(rect, Color("#4a342d"), false, 2.0)
	draw_circle(Vector2.ZERO, 6.0, Color("#6f3f38"))
	draw_circle(Vector2.ZERO, 2.0, Color("#f1d28a"))
