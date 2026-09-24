class_name PipeSystemDefinition
extends Resource

const INTAKE_RADIUS := 7.0
const RIM_RADIUS := 11.0
const SLOW_THRESHOLD := 140.0
const FAST_THRESHOLD := 260.0
const TRANSPORT_SECONDS := 0.6

@export var entrance := Vector2.ZERO
# Ordered by entry speed: slow, suitable, fast. Only entrance receives balls.
@export var exits := PackedVector2Array()
@export var exit_directions := PackedVector2Array()


static func exit_index_for_speed(speed: float) -> int:
	if speed < SLOW_THRESHOLD:
		return 0
	return 1 if speed < FAST_THRESHOLD else 2


# Resource avoids a retained circular GDScript type reference to HoleDefinition,
# which itself exports an array of these definitions.
func validate(hole: Resource, issues: Array[ValidationIssue] = []) -> PackedStringArray:
	var report := ValidationReport.new(issues, self)
	var errors := PackedStringArray()
	var label := I18n.text("TEXT_HOLE_PIPE_AT") % [hole.hole_id, entrance]
	if not entrance.is_finite() or exits.size() != 3 or exit_directions.size() != 3:
		errors.append(report.message("TEXT_NEEDS_ONE_ENTRANCE_AND_EXACTLY_THREE_EXITS_WITH_DIRECTIONS", [label], null, ""))
		return errors
	var mouths := PackedVector2Array([entrance])
	mouths.append_array(exits)
	var geometry := WallJoinGeometry.build(hole) if hole.lane_outline != null and hole.lane_outline.use_normalized_walls else null
	for index in range(mouths.size()):
		var point := mouths[index]
		if not point.is_finite() or not _is_clear(hole, geometry, point, RIM_RADIUS):
			errors.append(report.message("TEXT_MOUTH_IS_NOT_CLEAR_INSIDE_THE_HOLE", [label, index], null, ""))
		for other in range(index):
			if point.distance_to(mouths[other]) <= RIM_RADIUS * 2.0:
				errors.append(report.message("TEXT_MOUTHS_OVERLAP", [label], null, ""))
		for other_pipe in hole.pipe_systems:
			if other_pipe == null or other_pipe == self:
				continue
			var other_mouths := PackedVector2Array([other_pipe.entrance])
			other_mouths.append_array(other_pipe.exits)
			for other_point in other_mouths:
				if point.distance_to(other_point) <= RIM_RADIUS * 2.0:
					errors.append(report.message("TEXT_OVERLAPS_ANOTHER_PIPE", [label], null, ""))
	for index in range(3):
		var direction := exit_directions[index]
		if not direction.is_finite() or direction.is_zero_approx() or not exits[index].is_finite():
			errors.append(report.message("TEXT_EXIT_HAS_AN_INVALID_DIRECTION", [label, index], null, ""))
			continue
		# Includes emergence and a further ball diameter of unobstructed runout.
		for step in range(24):
			var point := exits[index] + direction.normalized() * step
			if not _is_clear(hole, geometry, point, PrototypeBall.RADIUS):
				errors.append(report.message("TEXT_EXIT_HAS_NO_CLEAR_RUNOUT", [label, index], null, ""))
				break
			for other_pipe in hole.pipe_systems:
				if other_pipe != null and point.distance_to(other_pipe.entrance) <= INTAKE_RADIUS + PrototypeBall.RADIUS:
					errors.append(report.message("TEXT_EXIT_LEADS_DIRECTLY_INTO_AN_ENTRANCE", [label, index], null, ""))
	return errors


static func _is_clear(hole: Resource, geometry: WallJoinGeometry, point: Vector2, radius: float) -> bool:
	if not hole.course_rect.has_point(point) or hole.lane_outline == null or not hole.lane_outline.contains_point(point):
		return false
	if point.distance_to(hole.hole_position) <= radius + PrototypeBall.HOLE_RADIUS:
		return false
	var floor_points: PackedVector2Array = hole.lane_outline.get_floor_points()
	for index in range(floor_points.size()):
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, floor_points[index], floor_points[(index + 1) % floor_points.size()])) <= radius + hole.lane_outline.wall_thickness * 0.5:
			return false
	if geometry != null:
		if geometry.contains_point(point):
			return false
		for piece in geometry.pieces:
			var segments: PackedVector2Array = piece["collision_segments"]
			for index in range(0, segments.size(), 2):
				if point.distance_to(Geometry2D.get_closest_point_to_segment(point, segments[index], segments[index + 1])) <= radius:
					return false
	for wall in hole.walls:
		if wall == null:
			continue
		if wall.wall_type == WallDefinition.WallType.CIRCLE and point.distance_to(wall.center) <= wall.radius + radius:
			return false
		if wall.wall_type == WallDefinition.WallType.RECTANGLE and Rect2(-wall.size * 0.5, wall.size).grow(radius).has_point((point - wall.center).rotated(-deg_to_rad(wall.rotation_degrees))):
			return false
	for tunnel in hole.tunnels:
		if tunnel != null and minf(point.distance_to(tunnel.endpoint_a), point.distance_to(tunnel.endpoint_b)) <= radius + TunnelDefinition.HOLE_RADIUS:
			return false
	for surface in hole.surfaces:
		if surface != null and surface.surface_type == SurfaceZone.SurfaceType.WATER:
			var local: Vector2 = (point - surface.rect.get_center()).rotated(-deg_to_rad(surface.rotation_degrees))
			if Rect2(-surface.rect.size * 0.5, surface.rect.size).grow(radius).has_point(local):
				return false
	for obstacle in hole.obstacles:
		if obstacle == null:
			continue
		if obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE:
			var swept: Rect2 = Rect2(-obstacle.gate_size * 0.5, obstacle.gate_size)
			swept = swept.merge(Rect2(swept.position + obstacle.open_offset, swept.size)).grow(radius)
			if swept.has_point((point - obstacle.position).rotated(-deg_to_rad(obstacle.start_rotation_degrees))):
				return false
		elif obstacle.obstacle_type == ObstacleDefinition.ObstacleType.ROTATING_BLADE:
			if point.distance_to(obstacle.position) <= obstacle.blade_size.length() * 0.5 + radius:
				return false
		elif obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SEESAW:
			if Rect2(-obstacle.seesaw_size * 0.5, obstacle.seesaw_size).grow(radius).has_point((point - obstacle.position).rotated(-deg_to_rad(obstacle.start_rotation_degrees))):
				return false
	return true


func draw_mouths(canvas: Node2D) -> void:
	# A flush round intake and raised, directed outlet sleeves; no route markings.
	canvas.draw_circle(entrance + Vector2(1, 2), RIM_RADIUS + 1, Color("#3c4144"))
	canvas.draw_circle(entrance, RIM_RADIUS, Color("#ee913b"))
	canvas.draw_circle(entrance, INTAKE_RADIUS, Color("#171c20"))
	canvas.draw_arc(entrance, 9, PI, TAU, 16, Color("#ffbd70"), 1)
	for index in range(exits.size()):
		canvas.draw_set_transform(exits[index], exit_directions[index].angle(), Vector2.ONE)
		canvas.draw_rect(Rect2(-16, -10, 17, 20), Color("#854d31"))
		canvas.draw_rect(Rect2(-15, -9, 15, 17), Color("#db7630"))
		canvas.draw_line(Vector2(-13, -6), Vector2(-2, -6), Color("#ffbd70"), 2)
		canvas.draw_circle(Vector2.ZERO, RIM_RADIUS, Color("#ee913b"))
		canvas.draw_circle(Vector2.ZERO, INTAKE_RADIUS, Color("#171c20"))
		canvas.draw_arc(Vector2.ZERO, 9, -PI * 0.5, PI * 0.5, 16, Color("#ffbd70"), 1)
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
