class_name EditorCanvas
extends Control

signal selection_changed()
signal hint_changed(message: String)

var document: EditorDocument
var tool := "select"
var variant := 6
var arrow_direction := 2
var arrow_grade := 0
var zoom := 1.5
var pan := Vector2(-160, 20)
var show_helpers := true
var viewport: SubViewport
var picture: TextureRect
var runtime: HoleRuntime
var _dragging := false
var _panning := false
var _drag_start := Vector2.ZERO
var _last_world := Vector2.ZERO
var _box_select := false
var _mouse := Vector2.ZERO
var _painted := {}
var _link_source: TriggerDefinition
var _handle := {}


func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	viewport = SubViewport.new()
	viewport.world_2d = World2D.new()
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.transparent_bg = true
	add_child(viewport)
	picture = TextureRect.new()
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.show_behind_parent = true
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(picture)
	picture.texture = viewport.get_texture()
	resized.connect(_resize)
	_resize()


func configure(value: EditorDocument) -> void:
	if document != null and document.changed.is_connected(rebuild):
		document.changed.disconnect(rebuild)
	document = value
	document.changed.connect(rebuild)
	if is_node_ready():
		rebuild()


func _resize() -> void:
	viewport.size = Vector2i(size.max(Vector2.ONE))
	_update_transform()


func _update_transform() -> void:
	viewport.canvas_transform = Transform2D(0.0, Vector2.ONE * zoom, 0.0, pan)
	queue_redraw()


func fit() -> void:
	zoom = clampf(minf((size.x - 64) / maxf(1, document.hole.course_rect.size.x), (size.y - 64) / maxf(1, document.hole.course_rect.size.y)), 0.04, 4.0)
	pan = size * 0.5 - document.hole.course_rect.get_center() * zoom
	_update_transform()


func world(point: Vector2) -> Vector2:
	return (point - pan) / zoom


func screen(point: Vector2) -> Vector2:
	return point * zoom + pan


func snap(point: Vector2) -> Vector2:
	return point.snapped(Vector2(16, 16))


func contour_snap(point: Vector2) -> Vector2:
	var origin := Vector2(8, 8)
	if document.hole.lane_outline != null and document.hole.lane_outline._uses_diagonal_grid():
		origin = Vector2.ZERO
	return (point - origin).snapped(Vector2(16, 16)) + origin


func rebuild() -> void:
	if viewport == null:
		return
	if is_instance_valid(runtime):
		viewport.remove_child(runtime)
		runtime.queue_free()
	runtime = null
	var hole := document.hole
	# Invalid drafts stay editable. Only instantiate definitions safe for runtime builders.
	if document.validation_errors().is_empty():
		runtime = HoleRuntime.new()
		runtime.configure(hole.duplicate(true))
		runtime.process_mode = Node.PROCESS_MODE_DISABLED
		viewport.add_child(runtime)
	queue_redraw()


func set_tool(value: String, subtype := 0) -> void:
	if _dragging:
		document.cancel()
	_dragging = false
	tool = value
	variant = subtype
	_link_source = null
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if document == null:
		return
	if event is InputEventMouseMotion:
		_mouse = event.position
		if _panning:
			pan += event.relative
			_update_transform()
		elif _dragging:
			_drag(world(event.position))
		queue_redraw()
	if event is InputEventMouseButton:
		_mouse = event.position
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
			accept_event()
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var before := world(event.position)
			zoom = clampf(zoom * (1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8), 0.04, 4.0)
			pan = event.position - before * zoom
			_update_transform()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			if event.pressed:
				_press(world(event.position), event.shift_pressed)
			else:
				_release(world(event.position))
			accept_event()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			document.cancel()
			_dragging = false
			_box_select = false
			_link_source = null
			accept_event()
		elif event.keycode == KEY_DELETE:
			delete_selected()
			accept_event()


func _press(point: Vector2, additive: bool) -> void:
	_drag_start = point
	_last_world = point
	_painted.clear()
	_box_select = false
	_handle = {}
	if tool == "link":
		var resource := document.find(hit(point))
		if resource is TriggerDefinition:
			_link_source = resource
			hint_changed.emit("Jetzt die Zielkanone anklicken")
		elif resource is CannonDefinition and _link_source != null:
			document.link(_link_source, resource)
			_link_source = null
			selection_changed.emit()
		return
	document.begin()
	_dragging = true
	if tool == "select":
		_handle = _handle_at(point)
		if not _handle.is_empty():
			return
		var id := hit(point)
		if id.is_empty():
			if not additive:
				document.selection.clear()
			_box_select = true
		elif additive:
			if id in document.selection:
				document.selection.erase(id)
			else:
				document.selection.append(id)
		elif id not in document.selection:
			document.selection = [id]
		selection_changed.emit()
	elif tool == "contour":
		var outline := document.hole.lane_outline
		if outline == null:
			outline = LaneOutlineDefinition.new()
			outline.use_normalized_walls = true
			document.hole.lane_outline = outline
		var vertex := _vertex_at(point)
		if vertex < 0:
			if outline.points.size() >= 512:
				hint_changed.emit("Höchstens 512 Konturpunkte erlaubt")
				return
			var edge := _edge_at(point)
			vertex = edge + 1 if edge >= 0 else outline.points.size()
			outline.points.insert(vertex, contour_snap(point))
		document.selection = ["vertex:%d" % vertex]
	elif tool == "boundary_arc":
		var edge := _edge_at(point)
		if edge >= 0:
			var outline := document.hole.lane_outline
			var start := outline.points[edge]
			var end := outline.points[(edge + 1) % outline.points.size()]
			var arc := WallDefinition.new()
			arc.wall_type = WallDefinition.WallType.ARC
			arc.center = (start + end) * 0.5
			arc.radius = start.distance_to(end) * 0.5
			arc.thickness = 4
			arc.arc_start_degrees = rad_to_deg((start - arc.center).angle())
			arc.arc_sweep_degrees = 180
			for index in range(outline.boundary_arcs.size() - 1, -1, -1):
				if outline._arc_matches_edge(outline.boundary_arcs[index], edge):
					outline.boundary_arcs.remove_at(index)
			outline.boundary_arcs.append(arc)
			arc.set_meta("editor_id", EditorCodec.new_id("e_"))
			document.selection = [String(arc.get_meta("editor_id"))]
	elif tool in ["tee", "hole", "aim"]:
		document.selection = [tool]
		_move_marker(tool, point.snapped(Vector2(8, 8)))
	elif tool in ["wall", "arrow"]:
		_paint(point)
	elif tool == "arrow_rect":
		pass
	else:
		_place(point)
	queue_redraw()


func _drag(point: Vector2) -> void:
	if not _handle.is_empty():
		var resource: Resource = _handle.resource
		if _handle.get("translate_pair", false):
			EditorDocument.translate(resource, snap(point) - snap(_last_world))
			_last_world = point
			queue_redraw()
			return
		var value := point.snapped(Vector2(8, 8))
		if _handle.get("local", false):
			value = (value - resource.position).rotated(-deg_to_rad(resource.start_rotation_degrees))
		if _handle.has("direction_origin"):
			value = (point - _handle.direction_origin).normalized()
		if _handle.has("index"):
			var array: PackedVector2Array = resource.get(_handle.key)
			array[_handle.index] = value
			resource.set(_handle.key, array)
		else:
			resource.set(_handle.key, value)
	elif tool in ["wall", "arrow"]:
		# A line drag fills every crossed cell, even between sparse mouse events.
		var steps := maxi(1, ceili(_last_world.distance_to(point) / 4))
		for index in range(steps + 1):
			_paint(_last_world.lerp(point, float(index) / steps))
	elif tool == "surface":
		var resource := document.find(document.selection[0]) if not document.selection.is_empty() else null
		if resource is SurfaceDefinition:
			resource.rect = Rect2(snap(_drag_start), snap(point) - snap(_drag_start)).abs()
			resource.rect.size = resource.rect.size.max(Vector2(16, 16))
	elif not _box_select and tool in ["select", "contour", "tee", "hole", "aim", "tunnel"]:
		var delta := snap(point) - snap(_last_world)
		for id in document.selection:
			if id.begins_with("vertex:"):
				document.hole.lane_outline.points[int(id.get_slice(":", 1))] = contour_snap(point)
			elif id in ["tee", "hole", "aim"]:
				_move_marker(id, _marker_position(id) + delta)
			else:
				var resource := document.find(id)
				if resource != null:
					EditorDocument.translate(resource, delta)
	_last_world = point
	queue_redraw()


func _release(point: Vector2) -> void:
	if not _dragging:
		return
	if tool == "arrow_rect":
		var first := Vector2i((_drag_start / 16).floor())
		var last := Vector2i((point / 16).floor())
		if (absi(last.x - first.x) + 1) * (absi(last.y - first.y) + 1) <= EditorCodec.MAX_ITEMS:
			for x in range(mini(first.x, last.x), maxi(first.x, last.x) + 1):
				for y in range(mini(first.y, last.y), maxi(first.y, last.y) + 1):
					_paint(Vector2(x * 16 + 8, y * 16 + 8))
		else:
			hint_changed.emit("Pfeilfeld ist zu groß")
	if _box_select:
		var rect := Rect2(_drag_start, point - _drag_start).abs()
		for group in EditorDocument.GROUPS:
			for resource in document.items(group):
				var id := String(resource.get_meta("editor_id", ""))
				if rect.has_point(EditorDocument.position_of(resource)) and id not in document.selection:
					document.selection.append(id)
	_dragging = false
	_box_select = false
	_handle = {}
	document.commit()
	if tool == "tunnel":
		set_tool("select")
		hint_changed.emit("Auswahl: Tunnelenden einzeln ziehen · mittlerer Griff verschiebt das Paar · Tunnelpaar legt ein weiteres an")
	selection_changed.emit()


func _paint(point: Vector2) -> void:
	var cell := Vector2i((point / 16).floor())
	if _painted.has(cell):
		return
	_painted[cell] = true
	var group := "wall_tiles" if tool == "wall" else "arrow_tiles"
	var items: Array = document.items(group)
	for index in range(items.size() - 1, -1, -1):
		if items[index].grid_cell == cell:
			items.remove_at(index)
	var resource: Resource
	if tool == "wall":
		var tile := WallTileDefinition.new()
		tile.grid_cell = cell
		tile.variant = variant
		resource = tile
	else:
		var arrow := ArrowTileDefinition.new()
		arrow.grid_cell = cell
		arrow.direction = arrow_direction
		arrow.slope_grade = arrow_grade
		var outline := document.hole.lane_outline
		if outline != null and outline.validate("Kontur").is_empty():
			var rect := arrow.get_rect()
			var square := PackedVector2Array([rect.position, rect.position + Vector2(16, 0), rect.end, rect.position + Vector2(0, 16)])
			var pieces := Geometry2D.intersect_polygons(square, outline.get_floor_points())
			if pieces.size() != 1 or pieces[0].size() < 3:
				return
			if not _same_square(pieces[0], square):
				for vertex in pieces[0]:
					arrow.clip_polygon.append(vertex - rect.position)
		resource = arrow
	resource.set_meta("editor_id", EditorCodec.new_id("e_"))
	items.append(resource)


func _same_square(polygon: PackedVector2Array, square: PackedVector2Array) -> bool:
	if polygon.size() != 4:
		return false
	for point in polygon:
		var found := false
		for corner in square:
			found = found or point.is_equal_approx(corner)
		if not found:
			return false
	return true


func _place(point: Vector2) -> void:
	point = snap(point)
	var resource: Resource
	var group := ""
	match tool:
		"circle", "arc":
			var wall := WallDefinition.new()
			wall.wall_type = WallDefinition.WallType.CIRCLE if tool == "circle" else WallDefinition.WallType.ARC
			wall.center = point
			wall.thickness = 4
			wall.radius = 24 if tool == "circle" else 48
			resource = wall
			group = "walls"
		"surface":
			var surface := SurfaceDefinition.new()
			surface.rect = Rect2(point, Vector2(64, 32))
			surface.surface_type = variant
			surface.deceleration = 260 if variant == SurfaceZone.SurfaceType.SAND else (20 if variant == SurfaceZone.SurfaceType.ICE else 80)
			resource = surface
			group = "surfaces"
		"obstacle":
			var obstacle := ObstacleDefinition.new()
			obstacle.position = point
			obstacle.obstacle_type = variant
			if variant == ObstacleDefinition.ObstacleType.TUNNEL_GEAR:
				obstacle.seconds_per_revolution = 16
			resource = obstacle
			group = "obstacles"
		"tunnel":
			var tunnel := TunnelDefinition.new()
			tunnel.endpoint_a = point
			tunnel.endpoint_b = point + Vector2(96, 0)
			resource = tunnel
			group = "tunnels"
		"pipe":
			var pipe := PipeSystemDefinition.new()
			pipe.entrance = point
			pipe.exits = PackedVector2Array([point + Vector2(96, -48), point + Vector2(96, 0), point + Vector2(96, 48)])
			pipe.exit_directions = PackedVector2Array([Vector2.RIGHT, Vector2.RIGHT, Vector2.RIGHT])
			resource = pipe
			group = "pipe_systems"
		"trigger":
			var trigger := TriggerDefinition.new()
			trigger.position = point
			trigger.trigger_id = EditorCodec.new_id("switch_")
			resource = trigger
			group = "triggers"
		"cannon":
			var cannon := CannonDefinition.new()
			cannon.position = point
			cannon.landing_position = point + Vector2(96, 0)
			cannon.mechanism_id = EditorCodec.new_id("cannon_")
			resource = cannon
			group = "cannons"
	if resource != null:
		var id := EditorCodec.new_id("e_")
		resource.set_meta("editor_id", id)
		document.items(group).append(resource)
		document.selection = [id]


func _marker_position(id: String) -> Vector2:
	if id == "tee":
		return document.hole.tee_position
	if id == "hole":
		return document.hole.hole_position
	return document.hole.tee_position + document.hole.initial_aim_offset


func _move_marker(id: String, point: Vector2) -> void:
	if id == "tee":
		document.hole.tee_position = point
	elif id == "hole":
		document.hole.hole_position = point
	else:
		document.hole.initial_aim_offset = point - document.hole.tee_position


func _vertex_at(point: Vector2) -> int:
	if document.hole.lane_outline != null:
		for index in range(document.hole.lane_outline.points.size()):
			if point.distance_to(document.hole.lane_outline.points[index]) < 10 / zoom:
				return index
	return -1


func _edge_at(point: Vector2) -> int:
	if document.hole.lane_outline != null:
		var points := document.hole.lane_outline.points
		for index in range(points.size()):
			if Geometry2D.get_closest_point_to_segment(point, points[index], points[(index + 1) % points.size()]).distance_to(point) < 12 / zoom:
				return index
	return -1


func hit(point: Vector2) -> String:
	for id in ["tee", "hole", "aim"]:
		if point.distance_to(_marker_position(id)) < 10 / zoom:
			return id
	var best := ""
	var distance := 24 / zoom
	for group in EditorDocument.GROUPS:
		for resource in document.items(group):
			var measure := point.distance_to(EditorDocument.position_of(resource))
			if resource is WallTileDefinition:
				for segment in resource.get_segments():
					measure = minf(measure, Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1]).distance_to(point))
			if resource is WallDefinition and resource.wall_type == WallDefinition.WallType.CIRCLE:
				measure = maxf(0, point.distance_to(resource.center) - resource.radius)
			if resource is WallDefinition and resource.wall_type == WallDefinition.WallType.ARC:
				var points: PackedVector2Array = EditorDocument.arc_points(resource)
				for index in range(points.size() - 1):
					measure = minf(measure, Geometry2D.get_closest_point_to_segment(point, points[index], points[index + 1]).distance_to(point))
			if resource is TunnelDefinition:
				measure = minf(measure, point.distance_to(resource.endpoint_b))
			if resource is PipeSystemDefinition:
				for exit_point in resource.exits:
					measure = minf(measure, point.distance_to(exit_point))
			if resource is SurfaceDefinition and Geometry2D.is_point_in_polygon(point, resource.get_rotated_corners()):
				measure = minf(measure, 22 / zoom)
			if measure < distance:
				distance = measure
				best = resource.get_meta("editor_id", "")
	return best


func _handles(resource: Resource) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if resource is TunnelDefinition:
		for key in ["endpoint_a", "endpoint_b"]:
			result.append({"resource": resource, "key": key, "point": resource.get(key)})
		result.append({"resource": resource, "translate_pair": true, "point": (resource.endpoint_a + resource.endpoint_b) * 0.5})
	elif resource is PipeSystemDefinition:
		result.append({"resource": resource, "key": "entrance", "point": resource.entrance})
		for index in range(resource.exits.size()):
			result.append({"resource": resource, "key": "exits", "index": index, "point": resource.exits[index]})
			result.append({"resource": resource, "key": "exit_directions", "index": index, "direction_origin": resource.exits[index], "point": resource.exits[index] + resource.exit_directions[index].normalized() * 24})
	elif resource is CannonDefinition:
		result.append({"resource": resource, "key": "landing_position", "point": resource.landing_position})
		result.append({"resource": resource, "key": "entry_direction", "direction_origin": resource.position, "point": resource.position + resource.entry_direction.normalized() * 32})
	elif resource is ObstacleDefinition:
		var keys: Array[String] = []
		if resource.obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE:
			keys = ["open_offset"]
		elif resource.obstacle_type == ObstacleDefinition.ObstacleType.ELEPHANT:
			keys = ["elephant_intake", "elephant_exit"]
		for key in keys:
			result.append({"resource": resource, "key": key, "local": true, "point": resource.position + resource.get(key).rotated(deg_to_rad(resource.start_rotation_degrees))})
	return result


func _handle_at(point: Vector2) -> Dictionary:
	for id in document.selection:
		var resource := document.find(id)
		if resource != null:
			for handle in _handles(resource):
				if point.distance_to(handle.point) <= 9 / zoom:
					return handle
	return {}


func delete_selected() -> void:
	if document.selection.size() == 1 and document.selection[0].begins_with("vertex:"):
		document.begin()
		document.hole.lane_outline.points.remove_at(int(document.selection[0].get_slice(":", 1)))
		document.selection.clear()
		document.commit()
	elif document.selection.size() == 1 and document.selection[0].begins_with("boundary:"):
		document.begin()
		document.hole.lane_outline.boundary_arcs.remove_at(int(document.selection[0].get_slice(":", 1)))
		document.selection.clear()
		document.commit()
	else:
		document.delete_selection()
	selection_changed.emit()


func _draw() -> void:
	if document == null:
		return
	var hole := document.hole
	if show_helpers:
		var first := Vector2i((world(Vector2.ZERO) / 16).floor())
		var last := Vector2i((world(size) / 16).ceil())
		for x in range(first.x, last.x + 1):
			draw_line(screen(Vector2(x * 16, first.y * 16)), screen(Vector2(x * 16, last.y * 16)), Color(0.6, 0.8, 0.8, 0.10))
		for y in range(first.y, last.y + 1):
			draw_line(screen(Vector2(first.x * 16, y * 16)), screen(Vector2(last.x * 16, y * 16)), Color(0.6, 0.8, 0.8, 0.10))
	if hole.lane_outline != null and (show_helpers or runtime == null):
		var points := hole.lane_outline.points
		for index in range(points.size()):
			draw_line(screen(points[index]), screen(points[(index + 1) % points.size()]), Color("63b8aa"), 1)
			if tool == "contour":
				draw_rect(Rect2(screen(points[index]) - Vector2(4, 4), Vector2(8, 8)), Color("f4c96b"))
	for group in EditorDocument.GROUPS:
		for resource in document.items(group):
			var point := EditorDocument.position_of(resource)
			var selected := String(resource.get_meta("editor_id", "")) in document.selection
			if runtime == null or _dragging:
				_draw_resource(resource)
			if show_helpers or selected:
				draw_circle(screen(point), 5 if selected else 2.5, Color("f4c96b") if selected else Color("63b8aa"), false, 2)
			if selected:
				for handle in _handles(resource):
					draw_rect(Rect2(screen(handle.point) - Vector2(4, 4), Vector2(8, 8)), Color("f4c96b"))
					if handle.get("translate_pair", false):
						draw_string(ThemeDB.fallback_font, screen(handle.point) + Vector2(8, -8), "Paar verschieben", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f4c96b"))
			if show_helpers:
				_draw_links(resource)
	if show_helpers:
		for id in ["tee", "hole", "aim"]:
			var point := screen(_marker_position(id))
			draw_circle(point, 7, Color("f4c96b"), false, 1)
			draw_string(ThemeDB.fallback_font, point + Vector2(10, -5), {"tee": "Start", "hole": "Loch", "aim": "Zielrichtung"}[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff0c9"))
	if _box_select:
		draw_rect(Rect2(screen(_drag_start), _mouse - screen(_drag_start)).abs(), Color("f4c96b"), false, 1)
	if tool == "arrow_rect" and _dragging:
		draw_rect(Rect2(screen((_drag_start / 16).floor() * 16), screen((world(_mouse) / 16).ceil() * 16) - screen((_drag_start / 16).floor() * 16)).abs(), Color("f4c96b"), false, 2)
	if tool in ["wall", "arrow", "arrow_rect"]:
		var cell := (world(_mouse) / 16).floor() * 16
		draw_rect(Rect2(screen(cell), Vector2.ONE * 16 * zoom), Color(1, 0.85, 0.4, 0.65), false, 2)


func _draw_resource(resource: Resource) -> void:
	var color := Color("f4c96b")
	if resource is WallTileDefinition:
		for segment in resource.get_segments():
			draw_line(screen(segment[0]), screen(segment[1]), color, 4 * zoom)
	elif resource is WallDefinition:
		if resource.wall_type == WallDefinition.WallType.CIRCLE:
			draw_circle(screen(resource.center), maxf(0.5, resource.radius * zoom), color, false, 2)
		elif resource.wall_type == WallDefinition.WallType.ARC:
			var points: PackedVector2Array = EditorDocument.arc_points(resource)
			for index in range(points.size() - 1):
				draw_line(screen(points[index]), screen(points[index + 1]), color, 2)
	elif resource is SurfaceDefinition:
		var corners: PackedVector2Array = resource.get_rotated_corners()
		for index in range(corners.size()):
			draw_line(screen(corners[index]), screen(corners[(index + 1) % corners.size()]), color, 2)
	elif resource is ArrowTileDefinition:
		draw_rect(Rect2(screen(resource.get_rect().position), Vector2.ONE * 16 * zoom), Color(0.4, 0.8, 0.6, 0.5), false, 1)
	else:
		draw_circle(screen(EditorDocument.position_of(resource)), 12 * zoom, color, false, 2)


func _line(a: Vector2, b: Vector2, label := "") -> void:
	draw_dashed_line(screen(a), screen(b), Color("82cad9"), 1, 6)
	draw_circle(screen(b), 5, Color("82cad9"), false, 1)
	if not label.is_empty():
		draw_string(ThemeDB.fallback_font, screen(b) + Vector2(7, -5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b7e3ed"))


func _draw_links(resource: Resource) -> void:
	if resource is TunnelDefinition:
		_line(resource.endpoint_a, resource.endpoint_b, "Tunnel B")
	elif resource is PipeSystemDefinition:
		for index in range(resource.exits.size()):
			_line(resource.entrance, resource.exits[index], ["Langsam", "Passend", "Schnell"][index])
			_line(resource.exits[index], resource.exits[index] + resource.exit_directions[index].normalized() * 24)
	elif resource is CannonDefinition:
		_line(resource.position, resource.landing_position, "Landung")
	elif resource is TriggerDefinition:
		for cannon in document.hole.cannons:
			if cannon.mechanism_id in resource.target_ids:
				_line(resource.position, cannon.position, "Schalterziel")
	elif resource is ObstacleDefinition:
		match resource.obstacle_type:
			ObstacleDefinition.ObstacleType.SLIDING_GATE:
				_line(resource.position, resource.position + resource.open_offset.rotated(deg_to_rad(resource.start_rotation_degrees)), "Torweg")
			ObstacleDefinition.ObstacleType.ROTATING_BLADE:
				draw_circle(screen(resource.position), resource.blade_size.length() * 0.5 * zoom, Color("82cad9"), false, 1)
			ObstacleDefinition.ObstacleType.SEESAW:
				_line(resource.position, resource.position + Vector2(resource.seesaw_size.x * 0.5, 0).rotated(deg_to_rad(resource.start_rotation_degrees)), "Wippenachse")
			ObstacleDefinition.ObstacleType.ELEPHANT:
				_line(resource.position, resource.position + resource.elephant_intake.rotated(deg_to_rad(resource.start_rotation_degrees)), "Aufnahme")
				_line(resource.position, resource.position + resource.elephant_exit.rotated(deg_to_rad(resource.start_rotation_degrees)), "Ausgang")
