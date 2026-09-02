class_name HoleRuntime
extends Node2D

var definition: HoleDefinition
var zones: Array[SurfaceZone] = []
var obstacle_nodes: Array[Node2D] = []
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


func reset_obstacles() -> void:
	for obstacle in obstacle_nodes:
		if obstacle is MovingObstacle:
			obstacle.reset_motion()


func _ready() -> void:
	_build_from_definition()


func _build_from_definition() -> void:
	if definition == null:
		push_error("HoleRuntime wurde ohne HoleDefinition gestartet")
		return
	for child in get_children():
		child.queue_free()
	zones.clear()
	obstacle_nodes.clear()
	for wall in definition.walls:
		_add_wall(wall)
	for surface in definition.surfaces:
		var zone := surface.instantiate_zone()
		zones.append(zone)
		add_child(zone)
	for obstacle_definition in definition.obstacles:
		var obstacle := obstacle_definition.instantiate_obstacle()
		obstacle_nodes.append(obstacle)
		add_child(obstacle)
	overlay = HoleOverlay.new()
	overlay.configure(definition)
	add_child(overlay)
	queue_redraw()


func _add_wall(wall: WallDefinition) -> void:
	var body := StaticBody2D.new()
	body.position = wall.center
	body.rotation = deg_to_rad(wall.rotation_degrees)
	body.collision_layer = 2
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall.size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _draw() -> void:
	if definition == null:
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
