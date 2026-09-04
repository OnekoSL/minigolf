class_name SurfaceZone
extends Area2D

enum SurfaceType { SAND, SLOPE, WATER }
enum SlopeDirection { UP, UP_RIGHT, RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT }
enum SlopeGrade { SHALLOW, MEDIUM, STEEP }

const DEFAULT_SLOPE_ACCELERATION := 90.0
const SHALLOW_SLOPE_ACCELERATION := 60.0
const MEDIUM_SLOPE_ACCELERATION := 90.0
const STEEP_SLOPE_ACCELERATION := 150.0

@export var surface_type := SurfaceType.SAND
@export var deceleration := 260.0
@export var acceleration := Vector2.ZERO
@export var slope_direction: SlopeDirection = SlopeDirection.UP
@export_range(0.0, 200.0, 1.0) var slope_strength := DEFAULT_SLOPE_ACCELERATION
@export_range(0.0, 300.0, 1.0) var minimum_flow_speed := 0.0
@export_range(0.0, 500.0, 1.0) var maximum_flow_speed := 0.0
@export_range(0.0, 30.0, 0.5) var flow_alignment_rate := 0.0
@export_range(0.0, 30.0, 0.5) var flow_centering_strength := 0.0

var zone_size := Vector2(64.0, 32.0)
var is_atomic_arrow_tile := false
var arrow_tile_grade: SlopeGrade = SlopeGrade.SHALLOW


func configure(
	rect: Rect2,
	type: SurfaceType,
	zone_deceleration: float,
	zone_acceleration := Vector2.ZERO,
	zone_rotation_degrees := 0.0
) -> void:
	position = rect.position + rect.size * 0.5
	rotation = deg_to_rad(zone_rotation_degrees)
	zone_size = rect.size
	surface_type = type
	deceleration = zone_deceleration
	acceleration = zone_acceleration


func configure_slope(
	rect: Rect2,
	direction: SlopeDirection,
	strength := DEFAULT_SLOPE_ACCELERATION,
	zone_deceleration := 120.0,
	flow_minimum_speed := 0.0,
	flow_maximum_speed := 0.0,
	alignment_rate := 0.0,
	centering_strength := 0.0,
	zone_rotation_degrees := 0.0
) -> void:
	slope_direction = direction
	slope_strength = strength
	minimum_flow_speed = flow_minimum_speed
	maximum_flow_speed = flow_maximum_speed
	flow_alignment_rate = alignment_rate
	flow_centering_strength = centering_strength
	configure(
		rect,
		SurfaceType.SLOPE,
		zone_deceleration,
		direction_vector(direction) * strength,
		zone_rotation_degrees
	)


func configure_arrow_tile(
	rect: Rect2,
	direction: SlopeDirection,
	grade: SlopeGrade,
	zone_deceleration := 120.0,
	flow_minimum_speed := 0.0,
	flow_maximum_speed := 0.0,
	alignment_rate := 0.0,
	centering_strength := 0.0
) -> void:
	assert(is_equal_approx(rect.size.x, rect.size.y), "Pfeilzellen muessen quadratisch sein")
	configure_slope(
		rect,
		direction,
		slope_strength_for_grade(grade),
		zone_deceleration,
		flow_minimum_speed,
		flow_maximum_speed,
		alignment_rate,
		centering_strength,
		0.0
	)
	is_atomic_arrow_tile = true
	arrow_tile_grade = grade


static func direction_vector(direction: SlopeDirection) -> Vector2:
	match direction:
		SlopeDirection.UP:
			return Vector2.UP
		SlopeDirection.UP_RIGHT:
			return Vector2(1.0, -1.0).normalized()
		SlopeDirection.RIGHT:
			return Vector2.RIGHT
		SlopeDirection.DOWN_RIGHT:
			return Vector2(1.0, 1.0).normalized()
		SlopeDirection.DOWN:
			return Vector2.DOWN
		SlopeDirection.DOWN_LEFT:
			return Vector2(-1.0, 1.0).normalized()
		SlopeDirection.LEFT:
			return Vector2.LEFT
		SlopeDirection.UP_LEFT:
			return Vector2(-1.0, -1.0).normalized()
	return Vector2.UP


static func slope_strength_for_grade(grade: SlopeGrade) -> float:
	match grade:
		SlopeGrade.SHALLOW:
			return SHALLOW_SLOPE_ACCELERATION
		SlopeGrade.MEDIUM:
			return MEDIUM_SLOPE_ACCELERATION
		SlopeGrade.STEEP:
			return STEEP_SLOPE_ACCELERATION
	return SHALLOW_SLOPE_ACCELERATION


static func slope_color_for_grade(grade: SlopeGrade) -> Color:
	match grade:
		SlopeGrade.SHALLOW:
			return Color("#245537")
		SlopeGrade.MEDIUM:
			return Color("#244c70")
		SlopeGrade.STEEP:
			return Color("#71343a")
	return Color("#245537")


static func slope_grade_from_strength(strength: float) -> SlopeGrade:
	if strength >= (MEDIUM_SLOPE_ACCELERATION + STEEP_SLOPE_ACCELERATION) * 0.5:
		return SlopeGrade.STEEP
	if strength >= (SHALLOW_SLOPE_ACCELERATION + MEDIUM_SLOPE_ACCELERATION) * 0.5:
		return SlopeGrade.MEDIUM
	return SlopeGrade.SHALLOW


func _ready() -> void:
	if surface_type == SurfaceType.SLOPE:
		acceleration = direction_vector(slope_direction) * slope_strength
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = zone_size
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-zone_size * 0.5, zone_size)
	match surface_type:
		SurfaceType.SAND:
			draw_rect(rect, Color("#b99458"), true)
			for x in range(int(rect.position.x) + 5, int(rect.end.x), 11):
				for y in range(int(rect.position.y) + 5, int(rect.end.y), 11):
					draw_circle(Vector2(x, y), 1.0, Color("#7d603a"))
		SurfaceType.SLOPE:
			var is_flow := minimum_flow_speed > 0.0
			var is_strong := slope_strength >= 120.0
			var visual_grade := arrow_tile_grade if is_atomic_arrow_tile else slope_grade_from_strength(slope_strength)
			var background := slope_color_for_grade(visual_grade)
			draw_rect(rect, background, true)
			if is_flow:
				draw_rect(rect.grow(-1.0), Color("#a8d98d"), false, 2.0)
			var direction := acceleration.rotated(-rotation).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.UP
			if is_atomic_arrow_tile:
				draw_rect(rect, background.lightened(0.24), false, 1.0)
				_draw_slope_arrow(Vector2.ZERO, direction, is_strong, false, 0.5)
			else:
				var spacing := 20 if is_strong else 24
				for x in range(int(rect.position.x) + int(spacing / 2), int(rect.end.x), spacing):
					for y in range(int(rect.position.y) + int(spacing / 2), int(rect.end.y), spacing):
						_draw_slope_arrow(Vector2(x, y), direction, is_strong, is_flow)
		SurfaceType.WATER:
			draw_rect(rect, Color("#2877a8"), true)
			for y in range(int(rect.position.y) + 7, int(rect.end.y), 12):
				draw_line(Vector2(rect.position.x + 4, y), Vector2(rect.end.x - 4, y), Color("#6ec5d9"), 1.0)


func _draw_slope_arrow(center: Vector2, direction: Vector2, is_strong: bool, is_flow: bool, visual_scale := 1.0) -> void:
	var color := Color("#d5e8a4")
	var perpendicular := direction.orthogonal()
	var tail := center - direction * 7.0 * visual_scale
	var neck := center + direction * 2.0 * visual_scale
	var tip := center + direction * 8.0 * visual_scale
	var stroke := maxf(1.0, 2.0 * visual_scale)
	draw_line(tail, neck, color, stroke)
	draw_line(tip, neck + perpendicular * 4.0 * visual_scale, color, stroke)
	draw_line(tip, neck - perpendicular * 4.0 * visual_scale, color, stroke)
	if is_strong:
		var second_neck := neck - direction * 5.0 * visual_scale
		draw_line(neck, second_neck + perpendicular * 3.0 * visual_scale, color, maxf(1.0, 1.5 * visual_scale))
		draw_line(neck, second_neck - perpendicular * 3.0 * visual_scale, color, maxf(1.0, 1.5 * visual_scale))
	if is_flow:
		draw_line(tail - direction * 3.0 * visual_scale, tail + direction * visual_scale, color, stroke)


func get_surface_data() -> Dictionary:
	return {
		"type": surface_type,
		"deceleration": deceleration,
		"acceleration": acceleration,
		"minimum_flow_speed": minimum_flow_speed,
		"maximum_flow_speed": maximum_flow_speed,
		"flow_alignment_rate": flow_alignment_rate,
		"flow_centering_strength": flow_centering_strength,
		"center": global_position,
	}


func contains_global_point(point: Vector2) -> bool:
	var rect := Rect2(-zone_size * 0.5, zone_size)
	point = to_local(point)
	return rect.has_point(point)
