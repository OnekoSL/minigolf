class_name EditorDocument
extends RefCounted

signal changed()

const GROUPS := ["walls", "wall_tiles", "surfaces", "arrow_tiles", "obstacles", "triggers", "cannons", "tunnels", "pipe_systems", "boundary_arcs"]
var hole: HoleDefinition
var selection: Array[String] = []
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var saved_text := ""
var _before := {}


func _init(source: HoleDefinition = null, make_copy := false) -> void:
	if source == null:
		hole = HoleDefinition.new()
		hole.hole_id = EditorCodec.new_id()
		hole.display_name = "Meine Bahn"
		hole.par = 2
		hole.theme = load("res://data/themes/stadtpark.tres")
		hole.lane_outline = LaneOutlineDefinition.new()
		hole.lane_outline.use_normalized_walls = true
		hole.lane_outline.points = PackedVector2Array([Vector2(184, 24), Vector2(616, 24), Vector2(616, 328), Vector2(184, 328)])
		hole.tee_position = Vector2(232, 280)
		hole.hole_position = Vector2(568, 72)
	else:
		hole = source.duplicate(true)
		if make_copy:
			hole.hole_id = EditorCodec.new_id()
			hole.display_name += " – Kopie"
		hole.category = HoleDefinition.HoleCategory.COURSE
	ensure_ids()
	mark_saved()
	if source == null or make_copy:
		saved_text = ""


func items(group: String) -> Array:
	if group == "boundary_arcs":
		return hole.lane_outline.boundary_arcs if hole.lane_outline != null else []
	return hole.get(group)


func ensure_ids() -> void:
	var seen := {}
	for group in GROUPS:
		for resource in items(group):
			var id := String(resource.get_meta("editor_id", ""))
			if id.is_empty() or seen.has(id):
				id = EditorCodec.new_id("e_")
				resource.set_meta("editor_id", id)
			seen[id] = true


func text() -> String:
	return JSON.stringify(EditorCodec.encode(hole), "", true, true)


func dirty() -> bool:
	return text() != saved_text


func mark_saved() -> void:
	saved_text = text()


func begin() -> void:
	if _before.is_empty():
		_before = _snapshot()


func commit() -> void:
	ensure_ids()
	if not _before.is_empty() and JSON.stringify(EditorCodec.encode(_before.hole)) != JSON.stringify(EditorCodec.encode(hole)):
		undo_stack.append(_before)
		if undo_stack.size() > 100:
			undo_stack.pop_front()
		redo_stack.clear()
	_before = {}
	changed.emit()


func cancel() -> void:
	if not _before.is_empty():
		_restore(_before)
	_before = {}
	changed.emit()


func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(_snapshot())
	_restore(undo_stack.pop_back())
	changed.emit()


func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(_snapshot())
	_restore(redo_stack.pop_back())
	changed.emit()


func _restore(state: Dictionary) -> void:
	hole = state.hole.duplicate(true)
	selection.assign(state.selection)


func _snapshot() -> Dictionary:
	# History contains trusted in-memory drafts, including temporarily invalid geometry.
	return {"hole": hole.duplicate(true), "selection": selection.duplicate()}


func find(id: String) -> Resource:
	for group in GROUPS:
		for resource in items(group):
			if resource.get_meta("editor_id", "") == id:
				return resource
	return null


func group_of(resource: Resource) -> String:
	for group in GROUPS:
		for item in items(group):
			if item == resource:
				return group
	return ""


static func position_of(resource: Resource) -> Vector2:
	if resource is WallTileDefinition:
		return resource.get_cell_rect().get_center()
	if resource is ArrowTileDefinition:
		return resource.get_rect().get_center()
	if resource is WallDefinition:
		return resource.center
	if resource is SurfaceDefinition:
		return resource.rect.get_center()
	if resource is TunnelDefinition:
		return resource.endpoint_a
	if resource is PipeSystemDefinition:
		return resource.entrance
	return resource.position


static func translate(resource: Resource, offset: Vector2) -> void:
	if resource is WallTileDefinition or resource is ArrowTileDefinition:
		resource.grid_cell += Vector2i((offset / 16.0).round())
	elif resource is WallDefinition:
		resource.center += offset
	elif resource is SurfaceDefinition:
		resource.rect.position += offset
	elif resource is TunnelDefinition:
		resource.endpoint_a += offset
		resource.endpoint_b += offset
	elif resource is PipeSystemDefinition:
		resource.entrance += offset
		for index in range(resource.exits.size()):
			resource.exits[index] += offset
	else:
		resource.position += offset
		if resource is CannonDefinition:
			resource.landing_position += offset


func delete_selection() -> void:
	begin()
	for group in GROUPS:
		var group_items: Array = items(group)
		for index in range(group_items.size() - 1, -1, -1):
			if String(group_items[index].get_meta("editor_id", "")) in selection:
				group_items.remove_at(index)
	_repair_links()
	selection.clear()
	commit()


func duplicate_selection() -> void:
	begin()
	var new_selection: Array[String] = []
	var trigger_ids := {}
	var cannon_ids := {}
	var clones: Array[Resource] = []
	for id in selection:
		var source := find(id)
		if source == null:
			continue
		var clone: Resource = source.duplicate(true)
		var new_id := EditorCodec.new_id("e_")
		clone.set_meta("editor_id", new_id)
		if clone is TriggerDefinition:
			trigger_ids[clone.trigger_id] = StringName(new_id)
			clone.trigger_id = new_id
		if clone is CannonDefinition:
			cannon_ids[clone.mechanism_id] = StringName(new_id)
			clone.mechanism_id = new_id
		translate(clone, Vector2(16, 16))
		items(group_of(source)).append(clone)
		clones.append(clone)
		new_selection.append(new_id)
	for clone in clones:
		if clone is TriggerDefinition:
			var targets: Array[StringName] = []
			for id in clone.target_ids:
				if cannon_ids.has(id):
					targets.append(cannon_ids[id])
			clone.target_ids = targets
		if clone is CannonDefinition:
			clone.required_trigger_id = trigger_ids.get(clone.required_trigger_id, &"")
	selection = new_selection
	commit()


func _repair_links() -> void:
	var cannons: Array[StringName] = []
	var triggers: Array[StringName] = []
	for cannon in hole.cannons:
		cannons.append(cannon.mechanism_id)
	for trigger in hole.triggers:
		triggers.append(trigger.trigger_id)
		for index in range(trigger.target_ids.size() - 1, -1, -1):
			if trigger.target_ids[index] not in cannons:
				trigger.target_ids.remove_at(index)
	for cannon in hole.cannons:
		if cannon.required_trigger_id not in triggers:
			cannon.required_trigger_id = &""


func link(trigger: TriggerDefinition, cannon: CannonDefinition) -> void:
	begin()
	for other in hole.triggers:
		other.target_ids.erase(cannon.mechanism_id)
	trigger.target_ids.append(cannon.mechanism_id)
	cannon.required_trigger_id = trigger.trigger_id
	commit()


func resize_course(size: Vector2) -> void:
	hole.course_rect.size = size.snapped(Vector2(16, 16)).max(Vector2(64, 64))
	hole.camera_center_bounds = Rect2(Vector2(320, 180), Vector2(maxf(0, hole.course_rect.end.x - 632), maxf(0, hole.course_rect.end.y - 352)))


func issues() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var limits := geometry_limit_errors()
	if not limits.is_empty():
		for message in limits:
			result.append({"message": message, "id": ""})
		return result
	for message in validation_errors():
		var id := ""
		for group in GROUPS:
			var labels := {"walls": "Bande", "wall_tiles": "Wandbaustein", "surfaces": "Flaeche", "arrow_tiles": "Pfeilzelle", "obstacles": "Hindernis", "triggers": "Trigger", "cannons": "Kanone", "tunnels": "Tunnel"}
			for index in range(items(group).size()):
				if (", %s %d" % [labels.get(group, "Rohr"), index]) in message:
					id = items(group)[index].get_meta("editor_id", "")
		result.append({"message": message, "id": id})
	if hole.par < 1 or hole.par > 20:
		result.append({"message": "PAR muss zwischen 1 und 20 liegen", "id": ""})
	if hole.lane_outline == null or not hole.lane_outline.use_normalized_walls:
		result.append({"message": "Eigene Bahnen benötigen eine geschlossene Normkontur", "id": ""})
	if hole.lane_outline != null and hole.lane_outline.validate("Kontur").is_empty():
		for marker in ["tee", "hole"]:
			var point := hole.tee_position if marker == "tee" else hole.hole_position
			if not clear_position(point):
				result.append({"message": "Abschlag ist blockiert" if marker == "tee" else "Zielloch ist blockiert", "id": marker})
	for group in ["walls", "boundary_arcs", "obstacles"]:
		for resource in items(group):
			var bounds := element_bounds(resource)
			if bounds.has_area() and not hole.course_rect.grow(0.1).encloses(bounds):
				result.append({"message": "Bauteil oder Bewegungsbereich ragt über den sichtbaren Bahnbereich hinaus", "id": resource.get_meta("editor_id", ""), "severity": "warning"})
	return result


func blocking_issues() -> Array[Dictionary]:
	return issues().filter(func(issue: Dictionary): return issue.get("severity", "error") == "error")


static func arc_points(wall: WallDefinition) -> PackedVector2Array:
	if wall.arc_segments < 4 or wall.arc_segments > 128 or not is_finite(wall.radius) or wall.radius <= 0 or wall.radius > 4096:
		return PackedVector2Array()
	var points := wall.get_arc_centerline()
	for index in range(points.size()):
		points[index] = wall.center + points[index].rotated(deg_to_rad(wall.rotation_degrees))
	return points


static func element_bounds(resource: Resource) -> Rect2:
	var points := PackedVector2Array()
	if resource is WallDefinition:
		if resource.wall_type == WallDefinition.WallType.CIRCLE:
			return Rect2(resource.center - Vector2.ONE * resource.radius, Vector2.ONE * resource.radius * 2)
		if resource.wall_type == WallDefinition.WallType.ARC:
			points = arc_points(resource)
	elif resource is ObstacleDefinition:
		var rect := Rect2()
		match resource.obstacle_type:
			ObstacleDefinition.ObstacleType.ROTATING_BLADE:
				var radius: float = resource.blade_size.length() * 0.5
				return Rect2(resource.position - Vector2.ONE * radius, Vector2.ONE * radius * 2)
			ObstacleDefinition.ObstacleType.TUNNEL_GEAR:
				return Rect2(resource.position - Vector2.ONE * TunnelGear.OUTER_RADIUS, Vector2.ONE * TunnelGear.OUTER_RADIUS * 2)
			ObstacleDefinition.ObstacleType.SLIDING_GATE:
				rect = Rect2(-resource.gate_size * 0.5, resource.gate_size)
				rect = rect.merge(Rect2(rect.position + resource.open_offset, rect.size))
			ObstacleDefinition.ObstacleType.SEESAW:
				rect = Rect2(-resource.seesaw_size * 0.5, resource.seesaw_size)
			ObstacleDefinition.ObstacleType.ELEPHANT:
				rect = Rect2(resource.elephant_intake - resource.elephant_gate_size, resource.elephant_gate_size * 2)
				rect = rect.merge(Rect2(resource.elephant_exit - resource.elephant_gate_size, resource.elephant_gate_size * 2))
		for corner in [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]:
			points.append(resource.position + corner.rotated(deg_to_rad(resource.start_rotation_degrees)))
	if points.is_empty():
		return Rect2()
	var result := Rect2(points[0], Vector2.ZERO)
	for point in points:
		result = result.expand(point)
	return result


func validation_errors() -> PackedStringArray:
	var limits := geometry_limit_errors()
	return limits if not limits.is_empty() else hole.validate()


func geometry_limit_errors() -> PackedStringArray:
	# Bound expansion before calling the normalized-wall tessellator or O(n²) validators.
	if hole.course_rect.size.x > 8192 or hole.course_rect.size.y > 8192:
		return PackedStringArray(["Bahngröße darf höchstens 8192 × 8192 Pixel betragen"])
	if hole.lane_outline != null:
		if hole.lane_outline.points.size() > 512:
			return PackedStringArray(["Höchstens 512 Konturpunkte erlaubt"])
		for point in hole.lane_outline.points:
			if not point.is_finite() or absf(point.x) > 16384 or absf(point.y) > 16384:
				return PackedStringArray(["Konturpunkt liegt außerhalb des unterstützten Arbeitsbereichs"])
	for group in GROUPS:
		if items(group).size() > EditorCodec.MAX_ITEMS:
			return PackedStringArray(["Zu viele Bauteile"])
	for group in ["walls", "boundary_arcs"]:
		for wall in items(group):
			if wall.arc_segments < 4 or wall.arc_segments > 128 or wall.radius > 4096:
				return PackedStringArray(["Bögen benötigen 4 bis 128 Segmente und höchstens 4096 Pixel Radius"])
	return PackedStringArray()


func boundary_edge(arc: WallDefinition) -> int:
	if hole.lane_outline != null:
		for index in range(hole.lane_outline.points.size()):
			if hole.lane_outline._arc_matches_edge(arc, index):
				return index
	return -1


func boundary_bulge(arc: WallDefinition) -> float:
	var edge := boundary_edge(arc)
	if edge < 0:
		return 16
	var points := hole.lane_outline.points
	var start := points[edge]
	var end := points[(edge + 1) % points.size()]
	var tangent := start.direction_to(end)
	var normal := Vector2(-tangent.y, tangent.x)
	var mid_angle := deg_to_rad(arc.arc_start_degrees + arc.arc_sweep_degrees * 0.5)
	return (arc.center + Vector2.from_angle(mid_angle) * arc.radius - (start + end) * 0.5).dot(normal)


func set_boundary_bulge(arc: WallDefinition, height: float) -> void:
	var edge := boundary_edge(arc)
	if edge < 0:
		return
	height = maxf(4, absf(height)) * (-1.0 if height < 0 else 1.0)
	var points := hole.lane_outline.points
	var start := points[edge]
	var end := points[(edge + 1) % points.size()]
	var midpoint := (start + end) * 0.5
	var tangent := start.direction_to(end)
	var normal := Vector2(-tangent.y, tangent.x)
	arc.center = midpoint + normal * (height * 0.5 - start.distance_squared_to(end) / (8.0 * height))
	arc.radius = start.distance_to(arc.center)
	var start_angle := (start - arc.center).angle()
	var sweep := fposmod((end - arc.center).angle() - start_angle, TAU)
	if fposmod((midpoint + normal * height - arc.center).angle() - start_angle, TAU) > sweep:
		sweep -= TAU
	arc.arc_start_degrees = rad_to_deg(start_angle)
	arc.arc_sweep_degrees = rad_to_deg(sweep)
	arc.rotation_degrees = 0


func clear_position(point: Vector2, include_dynamic := true) -> bool:
	if hole.lane_outline == null or not hole.lane_outline.contains_point(point):
		return false
	var radius := PrototypeBall.RADIUS
	var boundary := hole.lane_outline.get_floor_points()
	for index in range(boundary.size()):
		if Geometry2D.get_closest_point_to_segment(point, boundary[index], boundary[(index + 1) % boundary.size()]).distance_to(point) <= radius + 2:
			return false
	for tile in hole.wall_tiles:
		for segment in tile.get_segments():
			if Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1]).distance_to(point) <= radius + 2:
				return false
	for wall in hole.walls:
		if wall.wall_type == WallDefinition.WallType.CIRCLE and point.distance_to(wall.center) <= wall.radius + radius:
			return false
		if wall.wall_type == WallDefinition.WallType.ARC:
			var points := arc_points(wall)
			for index in range(points.size() - 1):
				if Geometry2D.get_closest_point_to_segment(point, points[index], points[index + 1]).distance_to(point) <= radius + wall.thickness * 0.5:
					return false
	for surface in hole.surfaces:
		if surface.surface_type == SurfaceZone.SurfaceType.WATER and Geometry2D.is_point_in_polygon(point, surface.get_rotated_corners()):
			return false
	for obstacle in hole.obstacles:
		if not include_dynamic:
			break
		var local := (point - obstacle.position).rotated(-deg_to_rad(obstacle.start_rotation_degrees))
		if obstacle.obstacle_type == ObstacleDefinition.ObstacleType.ROTATING_BLADE:
			if Rect2(-obstacle.blade_size * 0.5, obstacle.blade_size).grow(radius).has_point(local):
				return false
		elif obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE:
			var open := TimedSlidingGate.openness_at_time(obstacle.phase_offset_seconds, obstacle.cycle_seconds, obstacle.transition_seconds, obstacle.open_hold_seconds)
			if Rect2(-obstacle.gate_size * 0.5, obstacle.gate_size).grow(radius).has_point(local - obstacle.open_offset * open):
				return false
	for cannon in hole.cannons:
		if not include_dynamic:
			break
		if Rect2(cannon.position - cannon.capture_size * 0.5, cannon.capture_size).grow(radius).has_point(point):
			return false
	return true
