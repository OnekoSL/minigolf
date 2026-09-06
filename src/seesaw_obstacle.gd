class_name SeesawObstacle
extends SurfaceZone

@export var plank_size := Vector2(96.0, 64.0)
@export_range(1.0, 30.0, 0.5) var max_tilt_degrees := 16.0
@export_range(0.1, 3.0, 0.05) var response_seconds := 0.35
@export_range(0.0, 200.0, 1.0) var seesaw_slope_strength := 120.0
@export_range(0.0, 32.0, 1.0) var pivot_deadzone := 4.0
@export_range(1.0, 12.0, 1.0) var end_lip_thickness := 4.0
@export_range(0.05, 0.95, 0.05) var blocker_tilt_threshold := 0.2
@export_range(-1.0, 1.0, 0.05) var preferred_tilt := -1.0

var tilt := 0.0
var target_tilt := 0.0
var left_end_blocker: StaticBody2D
var right_end_blocker: StaticBody2D
var left_end_collision: CollisionShape2D
var right_end_collision: CollisionShape2D
var side_wall_nodes: Array[StaticBody2D] = []
var top_side_collisions: Array[CollisionShape2D] = []
var bottom_side_collisions: Array[CollisionShape2D] = []


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
	left_end_blocker = _create_end_blocker(-plank_size.x * 0.5)
	right_end_blocker = _create_end_blocker(plank_size.x * 0.5)
	_create_side_wall(true)
	_create_side_wall(false)
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
		target_tilt = preferred_tilt
	elif weighted_local_x < -pivot_deadzone:
		target_tilt = -1.0
	elif weighted_local_x > pivot_deadzone:
		target_tilt = 1.0
	else:
		target_tilt = 0.0
	var response := maxf(response_seconds, 0.01)
	tilt = move_toward(tilt, target_tilt, delta / response)
	_update_end_blockers()
	queue_redraw()


func reset_motion() -> void:
	tilt = preferred_tilt
	target_tilt = preferred_tilt
	_update_end_blockers()
	queue_redraw()


func is_left_end_blocking() -> bool:
	return tilt >= blocker_tilt_threshold


func is_right_end_blocking() -> bool:
	return tilt <= -blocker_tilt_threshold


func _create_end_blocker(local_x: float) -> StaticBody2D:
	var blocker := StaticBody2D.new()
	blocker.position = Vector2(local_x, 0.0)
	blocker.collision_layer = 2
	blocker.collision_mask = 0
	blocker.set_meta("feedback_kind", &"seesaw_lip")
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(end_lip_thickness, plank_size.y)
	collision.shape = shape
	collision.disabled = true
	blocker.add_child(collision)
	add_child(blocker)
	if local_x < 0.0:
		left_end_collision = collision
	else:
		right_end_collision = collision
	return blocker


func _update_end_blockers() -> void:
	sync_end_blockers(false)
	_sync_side_walls()


func sync_end_blockers(immediate: bool) -> void:
	if left_end_collision != null:
		if immediate:
			left_end_collision.disabled = not is_left_end_blocking()
		else:
			left_end_collision.set_deferred("disabled", not is_left_end_blocking())
	if right_end_collision != null:
		if immediate:
			right_end_collision.disabled = not is_right_end_blocking()
		else:
			right_end_collision.set_deferred("disabled", not is_right_end_blocking())


func _create_side_wall(is_top: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("feedback_kind", &"seesaw_side")
	for _segment_index in range(2):
		var collision := CollisionShape2D.new()
		collision.shape = RectangleShape2D.new()
		body.add_child(collision)
		if is_top:
			top_side_collisions.append(collision)
		else:
			bottom_side_collisions.append(collision)
	side_wall_nodes.append(body)
	add_child(body)


func _sync_side_walls() -> void:
	if top_side_collisions.size() != 2 or bottom_side_collisions.size() != 2:
		return
	var side_points := _get_side_points()
	_sync_side_segments(top_side_collisions, side_points["top"])
	_sync_side_segments(bottom_side_collisions, side_points["bottom"])
	_sync_end_blocker_width(left_end_collision, side_points["top"][0], side_points["bottom"][0])
	_sync_end_blocker_width(right_end_collision, side_points["top"][2], side_points["bottom"][2])


func _sync_side_segments(collisions: Array[CollisionShape2D], points: PackedVector2Array) -> void:
	for index in range(2):
		var start := points[index]
		var end := points[index + 1]
		var edge := end - start
		var collision := collisions[index]
		collision.position = (start + end) * 0.5
		collision.rotation = edge.angle()
		var shape := collision.shape as RectangleShape2D
		shape.size = Vector2(edge.length() + end_lip_thickness, end_lip_thickness)


func _sync_end_blocker_width(collision: CollisionShape2D, top: Vector2, bottom: Vector2) -> void:
	if collision == null:
		return
	var shape := collision.shape as RectangleShape2D
	shape.size.y = top.distance_to(bottom)


func _get_side_points() -> Dictionary:
	var half := plank_size * 0.5
	var perspective := minf(7.0, half.y * 0.25)
	# Die angehobene Seite erscheint breiter (naeher), die abgesenkte schmaler.
	# So stimmt der perspektivische Groessenhinweis mit Farbe und Sperrkante ueberein.
	var left_outer_half_width := half.y + tilt * perspective
	var right_outer_half_width := half.y - tilt * perspective
	return {
		"top": PackedVector2Array([
			Vector2(-half.x, -left_outer_half_width),
			Vector2(0.0, -half.y),
			Vector2(half.x, -right_outer_half_width),
		]),
		"bottom": PackedVector2Array([
			Vector2(-half.x, left_outer_half_width),
			Vector2(0.0, half.y),
			Vector2(half.x, right_outer_half_width),
		]),
	}


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
	var base_color := Color("#b58a55")
	var high_color := Color("#d9b77b")
	var low_color := Color("#8c653e")
	# Positive height is the raised end. A ball on one half lowers that half,
	# so the opposite lip remains visibly and physically raised.
	var left_height := tilt
	var right_height := -tilt
	var perspective := minf(7.0, half.y * 0.25)
	var left_outer_half_width := half.y + left_height * perspective
	var right_outer_half_width := half.y + right_height * perspective
	var left_panel := PackedVector2Array([
		Vector2(-half.x, -left_outer_half_width),
		Vector2(0.0, -half.y),
		Vector2(0.0, half.y),
		Vector2(-half.x, left_outer_half_width),
	])
	var right_panel := PackedVector2Array([
		Vector2(0.0, -half.y),
		Vector2(half.x, -right_outer_half_width),
		Vector2(half.x, right_outer_half_width),
		Vector2(0.0, half.y),
	])
	var outline := Color("#513a2b")
	draw_colored_polygon(left_panel, base_color.lerp(high_color if left_height > 0.0 else low_color, absf(left_height) * 0.72))
	draw_colored_polygon(right_panel, base_color.lerp(high_color if right_height > 0.0 else low_color, absf(right_height) * 0.72))
	draw_polyline(PackedVector2Array([left_panel[0], left_panel[1], left_panel[2], left_panel[3], left_panel[0]]), outline, 2.0)
	draw_polyline(PackedVector2Array([right_panel[0], right_panel[1], right_panel[2], right_panel[3], right_panel[0]]), outline, 2.0)
	var side_points := _get_side_points()
	_draw_side_rail(side_points["top"])
	_draw_side_rail(side_points["bottom"])
	draw_line(Vector2(0.0, -half.y + 2.0), Vector2(0.0, half.y - 2.0), Color("#63483a"), 2.0)
	for y in [-half.y + 10.0, half.y - 10.0]:
		draw_circle(Vector2(0.0, y), 5.0, Color("#684940"))
		draw_circle(Vector2(0.0, y), 2.0, Color("#f1d28a"))
	if is_left_end_blocking():
		_draw_raised_lip(-half.x, left_outer_half_width)
	if is_right_end_blocking():
		_draw_raised_lip(half.x, right_outer_half_width)
	if absf(tilt) >= 0.12:
		var direction := Vector2.RIGHT * signf(tilt)
		_draw_downhill_arrow(Vector2(-half.x * 0.5, 0.0), direction)
		_draw_downhill_arrow(Vector2(half.x * 0.5, 0.0), direction)


func _draw_raised_lip(x: float, half_width: float) -> void:
	var start := Vector2(x, -half_width)
	var end := Vector2(x, half_width)
	draw_line(start, end, Color("#3f2b24"), end_lip_thickness + 2.0)
	draw_line(start, end, Color("#f1d28a"), end_lip_thickness)


func _draw_side_rail(points: PackedVector2Array) -> void:
	draw_polyline(points, Color("#3f2b24"), end_lip_thickness + 2.0)
	draw_polyline(points, Color("#d9c895"), end_lip_thickness)


func _draw_downhill_arrow(center: Vector2, direction: Vector2) -> void:
	var perpendicular := direction.orthogonal()
	var tail := center - direction * 10.0
	var neck := center + direction * 3.0
	var tip := center + direction * 12.0
	var color := Color("#f3dda8")
	draw_line(tail, neck, color, 2.0)
	draw_line(tip, neck + perpendicular * 5.0, color, 2.0)
	draw_line(tip, neck - perpendicular * 5.0, color, 2.0)
