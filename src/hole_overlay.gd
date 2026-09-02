class_name HoleOverlay
extends Node2D

var definition: HoleDefinition


func configure(hole_definition: HoleDefinition) -> void:
	definition = hole_definition
	queue_redraw()


func _draw() -> void:
	if definition == null:
		return
	for wall in definition.walls:
		draw_set_transform(wall.center, deg_to_rad(wall.rotation_degrees), Vector2.ONE)
		var local_rect := Rect2(-wall.size * 0.5, wall.size)
		draw_rect(local_rect, Color("#dad1af"), true)
		draw_rect(local_rect, Color("#584d43"), false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for obstacle in definition.obstacles:
		if obstacle.obstacle_type != ObstacleDefinition.ObstacleType.SLIDING_GATE:
			continue
		var closed := obstacle.position
		var opened := obstacle.position + obstacle.open_offset
		draw_line(closed, opened, Color("#8bc9d1"), 1.0)
		draw_rect(Rect2(opened - obstacle.gate_size * 0.5, obstacle.gate_size), Color(0.55, 0.79, 0.82, 0.32), false, 1.0)
		draw_circle(opened, 2.0, Color("#d7e7df"))
	draw_circle(definition.tee_position, 10.0, Color(0.85, 0.95, 0.75, 0.25))
	draw_circle(definition.tee_position, 2.0, Color("#f4e9bf"))
	draw_circle(definition.hole_position, PrototypeBall.HOLE_RADIUS, Color("#111419"))
	draw_line(
		definition.hole_position + Vector2(0, -1),
		definition.hole_position + Vector2(0, -29),
		Color("#f2e7c9"), 2.0
	)
	var flag := PackedVector2Array([
		definition.hole_position + Vector2(1, -29),
		definition.hole_position + Vector2(21, -23),
		definition.hole_position + Vector2(1, -17),
	])
	draw_colored_polygon(flag, Color("#d9514e"))
