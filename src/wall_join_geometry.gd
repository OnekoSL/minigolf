class_name WallJoinGeometry
extends RefCounted

# The same joined region supplies the wall fill, its visible outside edges and
# the static collision edges. Internal caps never become ball contacts.
const EPSILON := 0.001
const SAMPLE_DISTANCE := 0.01
const BUCKET_SIZE := 32.0
const MITER_LIMIT := 4.0

var polygons: Array[PackedVector2Array] = []
var boundary_segments := PackedVector2Array()
var pieces: Array[Dictionary] = []
var _regions: Array[Dictionary] = []
var _junctions: Dictionary = {}
var _buckets: Dictionary = {}


static func build(definition: HoleDefinition) -> WallJoinGeometry:
	var geometry := WallJoinGeometry.new()
	for piece in definition.get_normalized_wall_network():
		var owner := geometry._add_piece({
			"wall_type": &"normalized_lane_boundary" if piece["is_boundary"] else &"wall_tile",
			"variant": piece["variant"],
			"is_boundary": piece["is_boundary"],
			"is_internal": piece["is_internal"],
		})
		for segment in piece["segments"]:
			geometry._add_stroke(segment[0], segment[1], WallTileDefinition.THICKNESS, owner)
	for wall in definition.walls:
		if wall.wall_type != WallDefinition.WallType.CIRCLE:
			geometry._add_wall(wall, false)
	if definition.lane_outline != null:
		for wall in definition.lane_outline.boundary_arcs:
			geometry._add_wall(wall, true, _boundary_arc_anchors(definition.lane_outline, wall))
	geometry._add_junctions()
	geometry._build_boundary()
	return geometry


func contains_point(point: Vector2) -> bool:
	for region in _regions:
		if region["bounds"].grow(EPSILON).has_point(point) and Geometry2D.is_point_in_polygon(point, region["polygon"]):
			return true
	return false


func _add_piece(metadata: Dictionary) -> int:
	metadata["collision_segments"] = PackedVector2Array()
	pieces.append(metadata)
	return pieces.size() - 1


func _add_stroke(start: Vector2, end: Vector2, width: float, owner: int) -> void:
	if start.distance_to(end) <= EPSILON:
		return
	var direction := start.direction_to(end)
	var normal := Vector2(-direction.y, direction.x) * width * 0.5
	_add_region(PackedVector2Array([start + normal, end + normal, end - normal, start - normal]), owner)
	_register_endpoint(start, direction, width, owner)
	_register_endpoint(end, -direction, width, owner)


func _add_wall(wall: WallDefinition, is_boundary: bool, anchors := PackedVector2Array()) -> void:
	var owner := _add_piece({
		"wall_type": wall.wall_type,
		"variant": -1,
		"is_boundary": is_boundary,
		"is_internal": not is_boundary,
		"is_legacy_definition": true,
	})
	var transform := Transform2D(deg_to_rad(wall.rotation_degrees), wall.center)
	if wall.wall_type == WallDefinition.WallType.RECTANGLE:
		var half := wall.size * 0.5
		_add_region(transform * PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y),
		]), owner)
	elif wall.wall_type == WallDefinition.WallType.ARC:
		var start_angle := deg_to_rad(wall.arc_start_degrees)
		var end_angle := deg_to_rad(wall.arc_start_degrees + wall.arc_sweep_degrees)
		var start_radial := Vector2.from_angle(start_angle)
		var end_radial := Vector2.from_angle(end_angle)
		var sweep_sign := signf(wall.arc_sweep_degrees)
		var start_tangent := Vector2(-start_radial.y, start_radial.x) * sweep_sign
		var end_tangent := Vector2(end_radial.y, -end_radial.x) * sweep_sign
		var start_point := transform * (start_radial * wall.radius)
		var end_point := transform * (end_radial * wall.radius)
		var polygon := transform * wall.get_arc_polygon()
		if anchors.size() == 2:
			# Outline validation accepts small anchor deviations. Snap both edges
			# of each end cap, not just the centerline used by junction matching.
			var start_correction := anchors[0] - start_point
			var end_correction := anchors[1] - end_point
			polygon[0] += start_correction
			polygon[polygon.size() - 1] += start_correction
			polygon[wall.arc_segments] += end_correction
			polygon[wall.arc_segments + 1] += end_correction
			start_point = anchors[0]
			end_point = anchors[1]
		_add_region(polygon, owner)
		_register_endpoint(start_point, start_tangent.rotated(transform.get_rotation()), wall.thickness, owner)
		_register_endpoint(end_point, end_tangent.rotated(transform.get_rotation()), wall.thickness, owner)


static func _boundary_arc_anchors(outline: LaneOutlineDefinition, wall: WallDefinition) -> PackedVector2Array:
	for index in range(outline.points.size()):
		if outline.get_boundary_arc(index) != wall:
			continue
		var start := outline.points[index]
		var end := outline.points[(index + 1) % outline.points.size()]
		var arc_start := wall.center + (Vector2.from_angle(deg_to_rad(wall.arc_start_degrees)) * wall.radius).rotated(deg_to_rad(wall.rotation_degrees))
		return PackedVector2Array([start, end] if arc_start.distance_to(start) < arc_start.distance_to(end) else [end, start])
	return PackedVector2Array()


func _register_endpoint(point: Vector2, direction: Vector2, width: float, owner: int) -> void:
	var key := _point_key(point)
	if not _junctions.has(key):
		_junctions[key] = []
	_junctions[key].append({"point": point, "direction": direction, "half_width": width * 0.5, "owner": owner})


func _add_junctions() -> void:
	for endpoints in _junctions.values():
		for first_index in range(endpoints.size()):
			for second_index in range(first_index + 1, endpoints.size()):
				var first: Dictionary = endpoints[first_index]
				var second: Dictionary = endpoints[second_index]
				var first_direction: Vector2 = first["direction"]
				var second_direction: Vector2 = second["direction"]
				var turn := first_direction.cross(second_direction)
				if absf(turn) < EPSILON:
					continue
				var center: Vector2 = (first["point"] + second["point"]) * 0.5
				var first_normal := Vector2(-first_direction.y, first_direction.x)
				var second_normal := Vector2(-second_direction.y, second_direction.x)
				var first_outer: Vector2 = center - first_normal * signf(turn) * float(first["half_width"])
				var second_outer: Vector2 = center + second_normal * signf(turn) * float(second["half_width"])
				var intersection = Geometry2D.line_intersects_line(first_outer, first_direction, second_outer, second_direction)
				var polygon := PackedVector2Array([center, first_outer])
				# Acute junctions use a bevel rather than a long protruding spike.
				if intersection != null and center.distance_to(intersection) <= MITER_LIMIT * maxf(first["half_width"], second["half_width"]):
					polygon.append(intersection)
				polygon.append(second_outer)
				_add_region(polygon, first["owner"])


func _add_region(polygon: PackedVector2Array, owner: int) -> void:
	if polygon.size() < 3:
		return
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	polygons.append(polygon)
	var region_index := _regions.size()
	_regions.append({"polygon": polygon, "bounds": bounds, "owner": owner})
	for cell in _cells_for_rect(bounds.grow(SAMPLE_DISTANCE)):
		if not _buckets.has(cell):
			_buckets[cell] = []
		_buckets[cell].append(region_index)


func _build_boundary() -> void:
	var seen_edges: Dictionary = {}
	for region in _regions:
		var polygon: PackedVector2Array = region["polygon"]
		for index in range(polygon.size()):
			var start := polygon[index]
			var end := polygon[(index + 1) % polygon.size()]
			var edge := end - start
			if edge.length_squared() <= EPSILON * EPSILON:
				continue
			var candidates := _regions_near(Rect2(start, Vector2.ZERO).expand(end).grow(SAMPLE_DISTANCE))
			var cuts: Array[float] = [0.0, 1.0]
			for candidate_index in candidates:
				var candidate_polygon: PackedVector2Array = _regions[candidate_index]["polygon"]
				for candidate_edge in range(candidate_polygon.size()):
					_add_edge_cuts(cuts, start, edge, candidate_polygon[candidate_edge], candidate_polygon[(candidate_edge + 1) % candidate_polygon.size()])
			cuts.sort()
			var normal := Vector2(-edge.y, edge.x).normalized() * SAMPLE_DISTANCE
			for cut_index in range(cuts.size() - 1):
				if (cuts[cut_index + 1] - cuts[cut_index]) * edge.length() <= EPSILON:
					continue
				var segment_start := start + edge * cuts[cut_index]
				var segment_end := start + edge * cuts[cut_index + 1]
				var midpoint := (segment_start + segment_end) * 0.5
				var left_inside := _contains_in_candidates(midpoint + normal, candidates)
				var right_inside := _contains_in_candidates(midpoint - normal, candidates)
				if left_inside == right_inside:
					continue
				var key := _edge_key(segment_start, segment_end)
				if seen_edges.has(key):
					continue
				seen_edges[key] = true
				boundary_segments.append(segment_start)
				boundary_segments.append(segment_end)
				var owned_segments: PackedVector2Array = pieces[region["owner"]]["collision_segments"]
				owned_segments.append(segment_start)
				owned_segments.append(segment_end)
				pieces[region["owner"]]["collision_segments"] = owned_segments


static func _add_edge_cuts(cuts: Array[float], start: Vector2, edge: Vector2, other_start: Vector2, other_end: Vector2) -> void:
	var other_edge := other_end - other_start
	var denominator := edge.cross(other_edge)
	var offset := other_start - start
	if absf(denominator) > EPSILON:
		var along := offset.cross(other_edge) / denominator
		var other_along := offset.cross(edge) / denominator
		if along >= -EPSILON and along <= 1.0 + EPSILON and other_along >= -EPSILON and other_along <= 1.0 + EPSILON:
			cuts.append(clampf(along, 0.0, 1.0))
	elif absf(offset.cross(edge)) <= EPSILON * maxf(1.0, edge.length()):
		cuts.append(clampf(offset.dot(edge) / edge.length_squared(), 0.0, 1.0))
		cuts.append(clampf((other_end - start).dot(edge) / edge.length_squared(), 0.0, 1.0))


func _contains_in_candidates(point: Vector2, candidates: Array[int]) -> bool:
	for candidate in candidates:
		var region := _regions[candidate]
		if region["bounds"].grow(EPSILON).has_point(point) and Geometry2D.is_point_in_polygon(point, region["polygon"]):
			return true
	return false


func _regions_near(bounds: Rect2) -> Array[int]:
	var found: Dictionary = {}
	var result: Array[int] = []
	for cell in _cells_for_rect(bounds):
		for index in _buckets.get(cell, []):
			if not found.has(index) and _regions[index]["bounds"].grow(SAMPLE_DISTANCE).intersects(bounds):
				found[index] = true
				result.append(index)
	return result


static func _cells_for_rect(bounds: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(floori(bounds.position.x / BUCKET_SIZE), floori(bounds.end.x / BUCKET_SIZE) + 1):
		for y in range(floori(bounds.position.y / BUCKET_SIZE), floori(bounds.end.y / BUCKET_SIZE) + 1):
			cells.append(Vector2i(x, y))
	return cells


static func _point_key(point: Vector2) -> Vector2i:
	return Vector2i(roundi(point.x / EPSILON), roundi(point.y / EPSILON))


static func _edge_key(start: Vector2, end: Vector2) -> String:
	var first := _point_key(start)
	var second := _point_key(end)
	if first.x > second.x or (first.x == second.x and first.y > second.y):
		var swap := first
		first = second
		second = swap
	return "%d,%d:%d,%d" % [first.x, first.y, second.x, second.y]
