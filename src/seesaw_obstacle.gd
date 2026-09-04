class_name SeesawObstacle
extends SurfaceZone

@export var plank_size := Vector2(96.0, 64.0)
@export_range(1.0, 30.0, 0.5) var max_tilt_degrees := 16.0
@export_range(0.1, 3.0, 0.05) var response_seconds := 0.35
@export_range(0.0, 200.0, 1.0) var seesaw_slope_strength := 120.0
@export_range(0.0, 32.0, 1.0) var pivot_deadzone := 4.0

var tilt := 0.0
var target_tilt := 0.0


func _ready() -> void:
	zone_size = plank_size
	surface_type = SurfaceType.SLOPE
	deceleration = 70.0
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = plank_size
	collision.shape = shape
	add_child(collision)
	reset_motion()
	queue_redraw()


func _physics_process(delta: float) -> void:
	var weighted_local_x := INF
	for body in get_overlapping_bodies():
		if body is PrototypeBall and body.visible:
			weighted_local_x = to_local(body.global_position).x
			break
	advance_tilt(delta, weighted_local_x)


func advance_tilt(delta: float, weighted_local_x: float = INF) -> void:
	if delta <= 0.0:
		return
	if is_inf(weighted_local_x):
		target_tilt = 0.0
	elif weighted_local_x < -pivot_deadzone:
		target_tilt = -1.0
	elif weighted_local_x > pivot_deadzone:
		target_tilt = 1.0
	else:
		target_tilt = 0.0
	var response := maxf(response_seconds, 0.01)
	tilt = move_toward(tilt, target_tilt, delta / response)
	queue_redraw()


func reset_motion() -> void:
	tilt = 0.0
	target_tilt = 0.0
	queue_redraw()


func get_surface_data() -> Dictionary:
	var reference_sine := sin(deg_to_rad(16.0))
	var angle_scale := sin(deg_to_rad(max_tilt_degrees)) / reference_sine
	var downhill := Vector2.RIGHT.rotated(global_rotation) * seesaw_slope_strength * angle_scale * tilt
	return {
		"type": SurfaceType.SLOPE,
		"deceleration": deceleration,
		"acceleration": downhill,
		"minimum_flow_speed": 0.0,
		"maximum_flow_speed": 0.0,
		"flow_alignment_rate": 0.0,
		"flow_centering_strength": 0.0,
		"center": global_position,
	}


func _draw() -> void:
	var half := plank_size * 0.5
	var left_panel := Rect2(Vector2(-half.x, -half.y), Vector2(half.x, plank_size.y))
	var right_panel := Rect2(Vector2(0.0, -half.y), Vector2(half.x, plank_size.y))
	var base_color := Color("#b58a55")
	var high_color := Color("#d9b77b")
	var low_color := Color("#8c653e")
	var left_height := -tilt
	var right_height := tilt
	draw_rect(left_panel, base_color.lerp(high_color if left_height > 0.0 else low_color, absf(left_height) * 0.72), true)
	draw_rect(right_panel, base_color.lerp(high_color if right_height > 0.0 else low_color, absf(right_height) * 0.72), true)
	draw_rect(Rect2(-half, plank_size), Color("#513a2b"), false, 2.0)
	draw_line(Vector2(0.0, -half.y + 2.0), Vector2(0.0, half.y - 2.0), Color("#63483a"), 2.0)
	for y in [-half.y + 10.0, half.y - 10.0]:
		draw_circle(Vector2(0.0, y), 5.0, Color("#684940"))
		draw_circle(Vector2(0.0, y), 2.0, Color("#f1d28a"))
	if absf(tilt) >= 0.12:
		var direction := Vector2.RIGHT * signf(tilt)
		_draw_downhill_arrow(Vector2(-half.x * 0.5, 0.0), direction)
		_draw_downhill_arrow(Vector2(half.x * 0.5, 0.0), direction)


func _draw_downhill_arrow(center: Vector2, direction: Vector2) -> void:
	var perpendicular := direction.orthogonal()
	var tail := center - direction * 10.0
	var neck := center + direction * 3.0
	var tip := center + direction * 12.0
	var color := Color("#f3dda8")
	draw_line(tail, neck, color, 2.0)
	draw_line(tip, neck + perpendicular * 5.0, color, 2.0)
	draw_line(tip, neck - perpendicular * 5.0, color, 2.0)
