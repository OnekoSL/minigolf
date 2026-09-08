class_name HoleRuntime
extends Node2D

signal mechanism_feedback(kind: StringName, world_position: Vector2, direction: Vector2)

var definition: HoleDefinition
var zones: Array[SurfaceZone] = []
var lane_boundary_nodes: Array[StaticBody2D] = []
var wall_tile_nodes: Array[StaticBody2D] = []
var obstacle_nodes: Array[Node2D] = []
var trigger_nodes: Array[BallSwitch] = []
var cannon_nodes: Array[AdventureCannon] = []
var overlay: HoleOverlay
var wall_geometry: WallJoinGeometry


func configure(hole_definition: HoleDefinition) -> void:
	definition = hole_definition
	if is_inside_tree():
		_build_from_definition()


func get_course_rect() -> Rect2:
	return definition.course_rect


func get_tee_position() -> Vector2:
	return definition.tee_position


func get_hole_position() -> Vector2:
	return definition.hole_position


func get_par() -> int:
	return definition.par


func get_display_name() -> String:
	return definition.display_name


func get_initial_aim_offset() -> Vector2:
	return definition.initial_aim_offset


func get_camera_center_bounds() -> Rect2:
	return definition.camera_center_bounds


func get_tunnels() -> Array[TunnelDefinition]:
	return definition.tunnels


func reset_obstacles() -> void:
	reset_mechanisms()


func reset_mechanisms() -> void:
	for obstacle in obstacle_nodes:
		if obstacle is MovingObstacle:
			obstacle.reset_motion()
		elif obstacle.has_method("reset_motion"):
			obstacle.reset_motion()
	for trigger in trigger_nodes:
		trigger.reset_state()
	for cannon in cannon_nodes:
		cannon.reset_state()


func _ready() -> void:
	_build_from_definition()


func _build_from_definition() -> void:
	if definition == null:
		push_error("HoleRuntime wurde ohne HoleDefinition gestartet")
		return
	for child in get_children():
		child.queue_free()
	zones.clear()
	lane_boundary_nodes.clear()
	wall_tile_nodes.clear()
	obstacle_nodes.clear()
	trigger_nodes.clear()
	cannon_nodes.clear()
	wall_geometry = null
	var uses_wall_network := definition.lane_outline != null and definition.lane_outline.use_normalized_walls
	if uses_wall_network:
		wall_geometry = WallJoinGeometry.build(definition)
		_add_joined_wall_network()
	elif definition.lane_outline != null:
		_add_lane_boundaries(definition.lane_outline)
	for wall in definition.walls:
		if not uses_wall_network or wall.wall_type == WallDefinition.WallType.CIRCLE:
			_add_wall(wall)
	if not uses_wall_network:
		for wall_tile in definition.wall_tiles:
			_add_wall_tile(wall_tile)
	for surface in definition.surfaces:
		var zone := surface.instantiate_zone()
		zones.append(zone)
		add_child(zone)
	for arrow_tile in definition.arrow_tiles:
		var arrow_zone := arrow_tile.instantiate_zone()
		zones.append(arrow_zone)
		add_child(arrow_zone)
	for obstacle_definition in definition.obstacles:
		var obstacle := obstacle_definition.instantiate_obstacle()
		obstacle_nodes.append(obstacle)
		if obstacle is SurfaceZone:
			zones.append(obstacle)
		add_child(obstacle)
	for cannon_definition in definition.cannons:
		var cannon := cannon_definition.instantiate_cannon()
		cannon_nodes.append(cannon)
		add_child(cannon)
	for trigger_definition in definition.triggers:
		var trigger := trigger_definition.instantiate_trigger()
		trigger.activated.connect(_on_trigger_activated)
		trigger_nodes.append(trigger)
		add_child(trigger)
	overlay = HoleOverlay.new()
	overlay.configure(definition, wall_geometry)
	add_child(overlay)
	queue_redraw()


func _on_trigger_activated(trigger_id: StringName, world_position: Vector2) -> void:
	var direction_sum := Vector2.ZERO
	for trigger_definition in definition.triggers:
		if trigger_definition.trigger_id != trigger_id:
			continue
		for target_id in trigger_definition.target_ids:
			for cannon in cannon_nodes:
				if cannon.mechanism_id == target_id:
					cannon.set_enabled(true)
					direction_sum += (cannon.global_position - world_position).normalized()
		break
	mechanism_feedback.emit(&"switch", world_position, direction_sum.normalized())


func _add_wall(wall: WallDefinition) -> void:
	var body := StaticBody2D.new()
	body.position = wall.center
	body.rotation = deg_to_rad(wall.rotation_degrees)
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("wall_type", wall.wall_type)
	match wall.wall_type:
		WallDefinition.WallType.RECTANGLE:
			var collision := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = wall.size
			collision.shape = shape
			body.add_child(collision)
		WallDefinition.WallType.CIRCLE:
			var collision := CollisionShape2D.new()
			var shape := CircleShape2D.new()
			shape.radius = wall.radius
			collision.shape = shape
			body.add_child(collision)
		WallDefinition.WallType.ARC:
			var collision := CollisionPolygon2D.new()
			collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
			collision.polygon = wall.get_arc_polygon()
			body.add_child(collision)
	add_child(body)


func _add_wall_tile(tile: WallTileDefinition) -> void:
	var body := _create_wall_tile_body(tile, &"wall_tile")
	wall_tile_nodes.append(body)
	add_child(body)


func _create_wall_tile_body(tile: WallTileDefinition, wall_type: StringName) -> StaticBody2D:
	return _create_wall_piece_body(tile.get_segments(), tile.variant, wall_type)


func _create_wall_piece_body(segments: Array, variant: int, wall_type: StringName) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("wall_type", wall_type)
	body.set_meta("wall_variant", variant)
	for segment in segments:
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var edge: Vector2 = end - start
		var collision := CollisionShape2D.new()
		collision.position = (start + end) * 0.5
		collision.rotation = edge.angle()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(edge.length(), WallTileDefinition.THICKNESS)
		collision.shape = shape
		body.add_child(collision)
	return body


func _add_lane_boundaries(outline: LaneOutlineDefinition) -> void:
	for index in range(outline.points.size()):
		var start := outline.points[index]
		var end := outline.points[(index + 1) % outline.points.size()]
		var edge := end - start
		var body := StaticBody2D.new()
		body.position = (start + end) * 0.5
		body.rotation = edge.angle()
		body.collision_layer = 2
		body.collision_mask = 0
		body.set_meta("wall_type", &"lane_boundary")
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(edge.length() + outline.wall_thickness, outline.wall_thickness)
		collision.shape = shape
		body.add_child(collision)
		lane_boundary_nodes.append(body)
		add_child(body)


func _add_joined_wall_network() -> void:
	for piece in wall_geometry.pieces:
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		body.set_meta("wall_type", piece["wall_type"])
		body.set_meta("wall_variant", piece["variant"])
		body.set_meta("wall_is_boundary", piece["is_boundary"])
		body.set_meta("wall_is_internal", piece["is_internal"])
		body.set_meta("wall_thickness", WallTileDefinition.THICKNESS)
		var segments: PackedVector2Array = piece["collision_segments"]
		if not segments.is_empty():
			var shape := ConcavePolygonShape2D.new()
			shape.segments = segments
			var collision := CollisionShape2D.new()
			collision.shape = shape
			body.add_child(collision)
		if piece["is_boundary"]:
			lane_boundary_nodes.append(body)
		if piece["is_internal"] and not piece.get("is_legacy_definition", false):
			wall_tile_nodes.append(body)
		add_child(body)


func _draw() -> void:
	if definition == null:
		return
	if definition.lane_outline != null:
		draw_rect(definition.course_rect, Color("#183626"), true)
		draw_colored_polygon(definition.lane_outline.get_floor_points(), Color("#347a4a"))
		if definition.garden_presentation:
			_draw_garden()
		return
	draw_rect(definition.course_rect, Color("#347a4a"), true)
	var spacing := maxi(8, definition.grid_spacing)
	for x in range(int(definition.course_rect.position.x), int(definition.course_rect.end.x), spacing):
		draw_line(
			Vector2(x, definition.course_rect.position.y),
			Vector2(x, definition.course_rect.end.y),
			Color(0.11, 0.28, 0.18, 0.16), 1.0
		)
	if definition.course_rect.size.y > 360.0:
		for y in range(int(definition.course_rect.position.y), int(definition.course_rect.end.y), spacing):
			draw_line(
				Vector2(definition.course_rect.position.x, y),
				Vector2(definition.course_rect.end.x, y),
				Color(0.11, 0.28, 0.18, 0.10), 1.0
			)


func _draw_garden() -> void:
	var floor_points := definition.lane_outline.get_floor_points()
	var rect := definition.course_rect
	# Clip mowing stripes to the exact playable outline, including its arcs.
	for x in range(int(rect.position.x), int(rect.end.x), 48):
		var stripe := PackedVector2Array([Vector2(x,rect.position.y), Vector2(x+24,rect.position.y), Vector2(x+24,rect.end.y), Vector2(x,rect.end.y)])
		for polygon in Geometry2D.intersect_polygons(floor_points, stripe):
			draw_colored_polygon(polygon, Color(0.64,0.84,0.50,0.045))
	# Sparse planted beds sit entirely outside the playing surface.
	for y in range(int(rect.position.y)+32, int(rect.end.y)-16, 48):
		for x in range(int(rect.position.x)+32, int(rect.end.x)-16, 48):
			var point := Vector2(x,y)
			if (x / 48 + y / 48) % 3 != 0 or Geometry2D.is_point_in_polygon(point, floor_points):
				continue
			var clearance := INF
			for index in range(floor_points.size()):
				clearance = minf(clearance, point.distance_to(Geometry2D.get_closest_point_to_segment(point, floor_points[index], floor_points[(index+1) % floor_points.size()])))
			if clearance < 22:
				continue
			var mechanism_space := false
			for obstacle in definition.obstacles:
				if obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE:
					var rail := Rect2(obstacle.position - obstacle.gate_size * 0.5, obstacle.gate_size)
					rail = rail.merge(Rect2(rail.position + obstacle.open_offset, rail.size))
					mechanism_space = mechanism_space or rail.grow(16).has_point(point)
			if mechanism_space:
				continue
			draw_circle(point + Vector2(2,3), 12, Color("#112c25"))
			draw_circle(point + Vector2(-4,1), 8, Color("#244936"))
			draw_circle(point + Vector2(4,-2), 9, Color("#2c543c"))
			draw_rect(Rect2(point+Vector2(-3,-5),Vector2(3,2)), Color("#719563"))
			if (x+y) % 5 == 0:
				draw_rect(Rect2(point+Vector2(3,1),Vector2(2,2)), Color("#e5bf73"))
