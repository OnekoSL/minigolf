class_name HoleOverlay
extends Node2D

var definition: HoleDefinition


func configure(hole_definition: HoleDefinition) -> void:
	definition = hole_definition
	queue_redraw()


func _draw() -> void:
	if definition == null:
		return
	if definition.lane_outline != null:
		if definition.lane_outline.use_normalized_walls:
			for piece in definition.lane_outline.get_normalized_wall_pieces():
				_draw_wall_segments(piece["segments"])
		else:
			draw_polyline(
				definition.lane_outline.get_closed_points(),
				Color("#dad1af"),
				definition.lane_outline.wall_thickness,
				true
			)
	for wall in definition.walls:
		draw_set_transform(wall.center, deg_to_rad(wall.rotation_degrees), Vector2.ONE)
		match wall.wall_type:
			WallDefinition.WallType.RECTANGLE:
				var local_rect := Rect2(-wall.size * 0.5, wall.size)
				draw_rect(local_rect, Color("#dad1af"), true)
				draw_rect(local_rect, Color("#584d43"), false, 1.0)
			WallDefinition.WallType.CIRCLE:
				draw_circle(Vector2.ZERO, wall.radius, Color("#dad1af"))
				draw_circle(Vector2.ZERO, wall.radius, Color("#584d43"), false, 1.0)
			WallDefinition.WallType.ARC:
				var polygon := wall.get_arc_polygon()
				draw_colored_polygon(polygon, Color("#dad1af"))
				var outline := polygon.duplicate()
				if not outline.is_empty():
					outline.append(outline[0])
					draw_polyline(outline, Color("#584d43"), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for wall_tile in definition.wall_tiles:
		_draw_wall_tile(wall_tile)
	for obstacle in definition.obstacles:
		if obstacle.obstacle_type != ObstacleDefinition.ObstacleType.SLIDING_GATE:
			continue
		var closed := obstacle.position
		var opened := obstacle.position + obstacle.open_offset
		draw_line(closed, opened, Color("#8bc9d1"), 1.0)
		draw_rect(Rect2(opened - obstacle.gate_size * 0.5, obstacle.gate_size), Color(0.55, 0.79, 0.82, 0.32), false, 1.0)
		draw_circle(opened, 2.0, Color("#d7e7df"))
	for trigger in definition.triggers:
		for target_id in trigger.target_ids:
			for cannon in definition.cannons:
				if cannon.mechanism_id == target_id:
					draw_dashed_line(trigger.position, cannon.position, Color("#d99555"), 1.0, 5.0)
	for cannon in definition.cannons:
		draw_dashed_line(cannon.position, cannon.landing_position, Color(0.92, 0.83, 0.46, 0.48), 1.0, 8.0)
		draw_circle(cannon.landing_position, 12.0, Color(0.92, 0.83, 0.46, 0.25), false, 1.0)
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


func _draw_wall_tile(wall_tile: WallTileDefinition) -> void:
	_draw_wall_segments(wall_tile.get_segments())


func _draw_wall_segments(segments: Array) -> void:
	for segment in segments:
		draw_line(segment[0], segment[1], Color("#584d43"), WallTileDefinition.THICKNESS + 2.0, false)
	for segment in segments:
		draw_line(segment[0], segment[1], Color("#dad1af"), WallTileDefinition.THICKNESS, false)
