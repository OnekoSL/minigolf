class_name SurfaceZone
extends Area2D

enum SurfaceType { SAND, SLOPE, WATER }
enum SlopeDirection { UP, UP_RIGHT, RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT }

const DEFAULT_SLOPE_ACCELERATION := 90.0

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
			var background := Color("#3f8e5a") if is_flow else (Color("#48965b") if is_strong else Color("#4c9960"))
			draw_rect(rect, background, true)
			if is_flow:
				draw_rect(rect.grow(-1.0), Color("#a8d98d"), false, 2.0)
			var direction := acceleration.rotated(-rotation).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.UP
			var spacing := 20 if is_strong else 24
			for x in range(int(rect.position.x) + int(spacing / 2), int(rect.end.x), spacing):
				for y in range(int(rect.position.y) + int(spacing / 2), int(rect.end.y), spacing):
					var center := Vector2(x, y)
					var color := Color("#d5e8a4")
					var perpendicular := direction.orthogonal()
					var tail := center - direction * 7.0
					var neck := center + direction * 2.0
					var tip := center + direction * 8.0
					draw_line(tail, neck, color, 2.0)
					draw_line(tip, neck + perpendicular * 4.0, color, 2.0)
					draw_line(tip, neck - perpendicular * 4.0, color, 2.0)
					if is_strong:
						var second_neck := neck - direction * 5.0
						draw_line(neck, second_neck + perpendicular * 3.0, color, 1.5)
						draw_line(neck, second_neck - perpendicular * 3.0, color, 1.5)
					if is_flow:
						draw_line(tail - direction * 3.0, tail + direction, color, 2.0)
		SurfaceType.WATER:
			draw_rect(rect, Color("#2877a8"), true)
			for y in range(int(rect.position.y) + 7, int(rect.end.y), 12):
				draw_line(Vector2(rect.position.x + 4, y), Vector2(rect.end.x - 4, y), Color("#6ec5d9"), 1.0)


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
