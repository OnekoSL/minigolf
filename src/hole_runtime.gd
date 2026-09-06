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
	var uses_wall_network := definition.lane_outline != null and definition.lane_outline.use_normalized_walls
	if uses_wall_network:
		_add_normalized_wall_network()
	elif definition.lane_outline != null:
		_add_lane_boundaries(definition.lane_outline)
	for wall in definition.walls:
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
	overlay.configure(definition)
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


func _add_normalized_wall_network() -> void:
	for piece in definition.get_normalized_wall_network():
		var wall_type := &"normalized_lane_boundary" if piece["is_boundary"] else &"wall_tile"
		var body := _create_wall_piece_body(piece["segments"], piece["variant"], wall_type)
		body.set_meta("wall_is_boundary", piece["is_boundary"])
		body.set_meta("wall_is_internal", piece["is_internal"])
		if piece["is_boundary"]:
			lane_boundary_nodes.append(body)
		if piece["is_internal"]:
			wall_tile_nodes.append(body)
		add_child(body)


func _draw() -> void:
	if definition == null:
		return
	if definition.lane_outline != null:
		draw_rect(definition.course_rect, Color("#183626"), true)
		draw_colored_polygon(definition.lane_outline.points, Color("#347a4a"))
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
