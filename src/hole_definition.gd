class_name HoleDefinition
extends Resource

enum HoleCategory { COURSE, TECHNICAL }

@export var hole_id := &"unnamed"
@export var display_name := "UNBENANNTE BAHN"
@export var category := HoleCategory.COURSE
@export_range(1, 20, 1) var par := 4
@export var course_rect := Rect2(176.0, 16.0, 448.0, 328.0)
@export var lane_outline: LaneOutlineDefinition
@export var garden_presentation := false
@export var theme: CourseTheme
@export_enum("Gruen:-1", "Beton:3") var base_surface: int = -1
@export var pipe_systems: Array[PipeSystemDefinition] = []
@export var tee_position := Vector2(220.0, 305.0)
@export var hole_position := Vector2(575.0, 55.0)
@export var initial_aim_offset := Vector2(60.0, 0.0)
@export var camera_center_bounds := Rect2(Vector2(320.0, 180.0), Vector2.ZERO)
@export var grid_spacing := 16
@export var walls: Array[WallDefinition] = []
@export var wall_tiles: Array[WallTileDefinition] = []
@export var surfaces: Array[SurfaceDefinition] = []
@export var arrow_tiles: Array[ArrowTileDefinition] = []
@export var obstacles: Array[ObstacleDefinition] = []
@export var triggers: Array[TriggerDefinition] = []
@export var cannons: Array[CannonDefinition] = []
@export var tunnels: Array[TunnelDefinition] = []


func validate(issues: Array[ValidationIssue] = []) -> PackedStringArray:
	var report := ValidationReport.new(issues, self)
	var errors := PackedStringArray()
	if base_surface not in [-1, SurfaceZone.SurfaceType.CONCRETE]:
		errors.append(report.message("TEXT_HOLE_HAS_AN_UNKNOWN_BASE_SURFACE", [hole_id], null, ""))
	for pipe in pipe_systems:
		if pipe == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_PIPE_SYSTEM", [hole_id], null, ""))
		else:
			errors.append_array(pipe.validate(self, issues))
	if hole_id == &"" or hole_id == &"unnamed":
		errors.append(report.message("TEXT_HOLE_HAS_NO_UNIQUE_ID", [], null, ""))
	if display_name.strip_edges().is_empty():
		errors.append(report.message("TEXT_HOLE_HAS_NO_DISPLAY_NAME", [hole_id], null, ""))
	if course_rect.size.x <= 0.0 or course_rect.size.y <= 0.0:
		errors.append(report.message("TEXT_HOLE_HAS_AN_INVALID_PLAY_AREA", [hole_id], null, ""))
	if lane_outline != null:
		errors.append_array(lane_outline.validate(I18n.text("TEXT_HOLE_OUTLINE") % hole_id, issues))
		for point in lane_outline.get_floor_points():
			if not course_rect.grow(0.1).has_point(point):
				errors.append(report.message("TEXT_HOLE_OUTLINE_POINT_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id], null, ""))
				break
		if lane_outline.use_normalized_walls:
			for tile in lane_outline.get_normalized_wall_tiles():
				errors.append_array(tile.validate(I18n.text("TEXT_HOLE_BOUNDARY_WALL_TILE") % [hole_id, tile.grid_cell], grid_spacing, issues))
				if not course_rect.encloses(tile.get_cell_rect()):
					errors.append(report.message("TEXT_HOLE_BOUNDARY_WALL_TILE_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id, tile.grid_cell], null, ""))
			for piece in lane_outline.get_normalized_wall_pieces():
				for segment in piece["segments"]:
					for endpoint in segment:
						if not course_rect.grow(0.1).has_point(endpoint):
							errors.append(report.message("TEXT_HOLE_STANDARD_WALL_SEGMENT_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id], null, ""))
							break
	if not course_rect.has_point(tee_position):
		errors.append(report.message("TEXT_HOLE_TEE_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id], null, "tee"))
	if not course_rect.has_point(hole_position):
		errors.append(report.message("TEXT_HOLE_TARGET_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id], null, "hole"))
	if lane_outline != null and lane_outline.points.size() >= 3:
		if not lane_outline.contains_point(tee_position):
			errors.append(report.message("TEXT_HOLE_TEE_LIES_OUTSIDE_THE_OUTLINE", [hole_id], null, "tee"))
		if not lane_outline.contains_point(hole_position):
			errors.append(report.message("TEXT_HOLE_TARGET_LIES_OUTSIDE_THE_OUTLINE", [hole_id], null, "hole"))
	if camera_center_bounds.size.x < 0.0 or camera_center_bounds.size.y < 0.0:
		errors.append(report.message("TEXT_HOLE_HAS_NEGATIVE_CAMERA_BOUNDS", [hole_id], null, ""))
	var expected_camera_end := Vector2(
		maxf(320.0, course_rect.end.x + 8.0 - 320.0),
		maxf(180.0, course_rect.end.y + 8.0 - 180.0)
	)
	if not camera_center_bounds.position.is_equal_approx(Vector2(320.0, 180.0)) \
		or not camera_center_bounds.end.is_equal_approx(expected_camera_end):
		errors.append(report.message("TEXT_HOLE_CAMERA_BOUNDS_HIDE_PARTS_OF_THE_BOUNDARY_WALLS", [hole_id], null, ""))
	for index in range(walls.size()):
		if walls[index] == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_WALL", [hole_id], null, ""))
			continue
		errors.append_array(walls[index].validate(I18n.text("TEXT_HOLE_WALL") % [hole_id, index], issues))
		if not course_rect.grow(16.0).has_point(walls[index].center):
			errors.append(report.message("TEXT_HOLE_WALL_LIES_OUTSIDE_THE_HOLE", [hole_id, index], walls[index], ""))
	var wall_tile_rects: Array[Rect2] = []
	for index in range(wall_tiles.size()):
		var tile := wall_tiles[index]
		if tile == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_WALL_TILE", [hole_id], null, ""))
			continue
		errors.append_array(tile.validate(I18n.text("TEXT_HOLE_WALL_TILE") % [hole_id, index], grid_spacing, issues))
		var tile_rect := tile.get_cell_rect()
		if not course_rect.encloses(tile_rect):
			errors.append(report.message("TEXT_HOLE_WALL_TILE_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id, index], wall_tiles[index], ""))
		if lane_outline != null:
			for segment in tile.get_segments():
				for point in segment:
					if not lane_outline.contains_point(point):
						errors.append(report.message("TEXT_HOLE_WALL_TILE_IS_NOT_FULLY_INSIDE_THE_OUTLINE", [hole_id, index], wall_tiles[index], ""))
						break
		for previous_rect in wall_tile_rects:
			if tile_rect.intersects(previous_rect):
				errors.append(report.message("TEXT_HOLE_WALL_TILE_OCCUPIES_AN_ALREADY_USED_CELL", [hole_id, index], wall_tiles[index], ""))
				break
		wall_tile_rects.append(tile_rect)
	for index in range(surfaces.size()):
		if surfaces[index] == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_SURFACE", [hole_id], null, ""))
			continue
		errors.append_array(surfaces[index].validate(I18n.text("TEXT_HOLE_SURFACE") % [hole_id, index], issues))
		for corner in surfaces[index].get_rotated_corners():
			if not course_rect.has_point(corner):
				errors.append(report.message("TEXT_HOLE_SURFACE_LIES_OUTSIDE_THE_HOLE", [hole_id, index], surfaces[index], ""))
				break
	var arrow_rects: Array[Rect2] = []
	for index in range(arrow_tiles.size()):
		var tile := arrow_tiles[index]
		if tile == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_ARROW_TILE", [hole_id], null, ""))
			continue
		errors.append_array(tile.validate(I18n.text("TEXT_HOLE_ARROW_TILE") % [hole_id, index], grid_spacing, issues))
		var tile_rect := tile.get_rect()
		if not course_rect.encloses(tile_rect):
			errors.append(report.message("TEXT_HOLE_ARROW_TILE_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id, index], arrow_tiles[index], ""))
		if lane_outline != null:
			for corner in tile.get_inset_corners():
				if not lane_outline.contains_point(corner):
					errors.append(report.message("TEXT_HOLE_ARROW_TILE_IS_NOT_FULLY_INSIDE_THE_OUTLINE", [hole_id, index], arrow_tiles[index], ""))
					break
		for previous_rect in arrow_rects:
			if tile_rect.intersects(previous_rect):
				errors.append(report.message("TEXT_HOLE_ARROW_TILE_OVERLAPS_ANOTHER_ARROW_TILE", [hole_id, index], arrow_tiles[index], ""))
				break
		arrow_rects.append(tile_rect)
	for index in range(obstacles.size()):
		if obstacles[index] == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_OBSTACLE", [hole_id], null, ""))
			continue
		errors.append_array(obstacles[index].validate(I18n.text("TEXT_HOLE_OBSTACLE") % [hole_id, index], issues))
		if not course_rect.has_point(obstacles[index].position):
			errors.append(report.message("TEXT_HOLE_OBSTACLE_LIES_OUTSIDE_THE_HOLE", [hole_id, index], obstacles[index], ""))
	var trigger_ids: Dictionary = {}
	for index in range(triggers.size()):
		var trigger := triggers[index]
		if trigger == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_TRIGGER", [hole_id], null, ""))
			continue
		errors.append_array(trigger.validate(I18n.text("TEXT_HOLE_TRIGGER") % [hole_id, index], issues))
		if trigger_ids.has(trigger.trigger_id):
			errors.append(report.message("TEXT_HOLE_HAS_DUPLICATE_TRIGGER_ID", [hole_id, trigger.trigger_id], trigger, ""))
		trigger_ids[trigger.trigger_id] = true
		if not course_rect.has_point(trigger.position):
			errors.append(report.message("TEXT_HOLE_TRIGGER_LIES_OUTSIDE_THE_HOLE", [hole_id, index], trigger, ""))
	var cannon_ids: Dictionary = {}
	for index in range(cannons.size()):
		var cannon := cannons[index]
		if cannon == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_CANNON", [hole_id], null, ""))
			continue
		errors.append_array(cannon.validate(I18n.text("TEXT_HOLE_CANNON") % [hole_id, index], issues))
		if cannon_ids.has(cannon.mechanism_id):
			errors.append(report.message("TEXT_HOLE_HAS_DUPLICATE_MECHANISM_ID", [hole_id, cannon.mechanism_id], cannon, ""))
		cannon_ids[cannon.mechanism_id] = true
		if not course_rect.has_point(cannon.position):
			errors.append(report.message("TEXT_HOLE_CANNON_LIES_OUTSIDE_THE_HOLE", [hole_id, index], cannon, ""))
		if not course_rect.has_point(cannon.landing_position):
			errors.append(report.message("TEXT_HOLE_CANNON_LANDS_OUTSIDE_THE_HOLE", [hole_id, index], cannon, ""))
	for trigger in triggers:
		if trigger == null:
			continue
		for target_id in trigger.target_ids:
			if not cannon_ids.has(target_id):
				errors.append(report.message("TEXT_HOLE_TRIGGER_REFERS_TO_UNKNOWN_TARGET", [hole_id, trigger.trigger_id, target_id], trigger, ""))
	for cannon in cannons:
		if cannon == null or cannon.required_trigger_id == &"":
			continue
		if not trigger_ids.has(cannon.required_trigger_id):
			errors.append(report.message("TEXT_HOLE_CANNON_REQUIRES_UNKNOWN_TRIGGER", [hole_id, cannon.mechanism_id, cannon.required_trigger_id], cannon, ""))
		else:
			var linked := false
			for trigger in triggers:
				if trigger != null and trigger.trigger_id == cannon.required_trigger_id and cannon.mechanism_id in trigger.target_ids:
					linked = true
					break
			if not linked:
				errors.append(report.message("TEXT_HOLE_CANNON_IS_NOT_A_TARGET_OF_ITS_TRIGGER", [hole_id, cannon.mechanism_id], cannon, ""))
	var tunnel_endpoints: Array[Vector2] = []
	for index in range(tunnels.size()):
		var tunnel := tunnels[index]
		if tunnel == null:
			errors.append(report.message("TEXT_HOLE_CONTAINS_AN_EMPTY_TUNNEL", [hole_id], null, ""))
			continue
		errors.append_array(tunnel.validate(I18n.text("TEXT_HOLE_TUNNEL") % [hole_id, index], issues))
		for endpoint in [tunnel.endpoint_a, tunnel.endpoint_b]:
			if not course_rect.has_point(endpoint):
				errors.append(report.message("TEXT_HOLE_TUNNEL_LIES_OUTSIDE_THE_PLAY_AREA", [hole_id, index], tunnel, ""))
			elif lane_outline != null and lane_outline.points.size() >= 3 and not lane_outline.contains_point(endpoint):
				errors.append(report.message("TEXT_HOLE_TUNNEL_LIES_OUTSIDE_THE_OUTLINE", [hole_id, index], tunnel, ""))
			if endpoint.distance_to(hole_position) <= TunnelDefinition.HOLE_RADIUS * 2.0:
				errors.append(report.message("TEXT_HOLE_TUNNEL_OVERLAPS_THE_TARGET_HOLE", [hole_id, index], tunnel, ""))
			for previous_endpoint in tunnel_endpoints:
				if endpoint.distance_to(previous_endpoint) <= TunnelDefinition.HOLE_RADIUS * 2.0:
					errors.append(report.message("TEXT_HOLE_TUNNEL_OVERLAPS_ANOTHER_TUNNEL_ENTRANCE", [hole_id, index], tunnel, ""))
					break
			tunnel_endpoints.append(endpoint)
	return errors


func is_course_hole() -> bool:
	return category == HoleCategory.COURSE


func get_normalized_wall_network() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	if lane_outline == null or not lane_outline.use_normalized_walls:
		return pieces
	var boundary_tiles := lane_outline.get_normalized_wall_tiles()
	if boundary_tiles.is_empty():
		for boundary_piece in lane_outline.get_normalized_wall_pieces():
			pieces.append({
				"grid_cell": Vector2i(-1, -1),
				"variant": boundary_piece["variant"],
				"segments": boundary_piece["segments"],
				"is_boundary": true,
				"is_internal": false,
			})
		for wall_tile in wall_tiles:
			if wall_tile != null:
				pieces.append(_wall_network_piece(wall_tile, false, true))
		return pieces

	var cells: Dictionary = {}
	var cell_order: Array[Vector2i] = []
	for boundary_tile in boundary_tiles:
		_merge_wall_network_tile(cells, cell_order, boundary_tile, true, false)
	for wall_tile in wall_tiles:
		if wall_tile != null:
			_merge_wall_network_tile(cells, cell_order, wall_tile, false, true)

	var directions := [
		{"step": Vector2i.UP, "bit": 1, "opposite": 4},
		{"step": Vector2i.RIGHT, "bit": 2, "opposite": 8},
		{"step": Vector2i.DOWN, "bit": 4, "opposite": 1},
		{"step": Vector2i.LEFT, "bit": 8, "opposite": 2},
	]
	for cell in cell_order:
		var source: Dictionary = cells[cell]
		if not source["is_internal"]:
			continue
		var source_mask: int = source["cardinal_mask"]
		for direction in directions:
			if not source_mask & int(direction["bit"]):
				continue
			var neighbor_cell: Vector2i = cell + direction["step"]
			if not cells.has(neighbor_cell):
				continue
			var neighbor: Dictionary = cells[neighbor_cell]
			if not neighbor["is_boundary"] or int(neighbor["cardinal_mask"]) == 0:
				continue
			neighbor["cardinal_mask"] = int(neighbor["cardinal_mask"]) | int(direction["opposite"])
			cells[neighbor_cell] = neighbor
		var diagonal_connections: Array[Dictionary] = []
		match int(source["variant"]):
			WallTileDefinition.Variant.DIAGONAL_DOWN:
				diagonal_connections = [
					{"step": Vector2i(-1, -1), "endpoint": source["segments"][0][0]},
					{"step": Vector2i(1, 1), "endpoint": source["segments"][0][1]},
				]
			WallTileDefinition.Variant.DIAGONAL_UP:
				diagonal_connections = [
					{"step": Vector2i(-1, 1), "endpoint": source["segments"][0][0]},
					{"step": Vector2i(1, -1), "endpoint": source["segments"][0][1]},
				]
		for connection in diagonal_connections:
			var neighbor_cell: Vector2i = cell + connection["step"]
			if not cells.has(neighbor_cell):
				continue
			var neighbor: Dictionary = cells[neighbor_cell]
			if not neighbor["is_boundary"]:
				continue
			var boundary_center := Rect2(
				Vector2(neighbor_cell * WallTileDefinition.CELL_SIZE),
				Vector2(WallTileDefinition.CELL_SIZE, WallTileDefinition.CELL_SIZE)
			).get_center()
			var extra_segments: Array = neighbor["extra_segments"]
			extra_segments.append(PackedVector2Array([boundary_center, connection["endpoint"]]))
			neighbor["extra_segments"] = extra_segments
			cells[neighbor_cell] = neighbor

	for cell in cell_order:
		var piece: Dictionary = cells[cell]
		var mask: int = piece["cardinal_mask"]
		if mask != 0:
			var variant := WallTileDefinition.variant_from_cardinal_mask(mask)
			piece["variant"] = variant
			if variant >= 0:
				var normalized_tile := WallTileDefinition.new()
				normalized_tile.grid_cell = cell
				normalized_tile.variant = variant
				piece["segments"] = normalized_tile.get_segments()
			else:
				piece["segments"] = WallTileDefinition.segments_from_cardinal_mask(cell, mask)
			piece["segments"].append_array(piece["extra_segments"])
		else:
			piece["segments"] = piece["extra_segments"]
		pieces.append(piece)
	return pieces


func _merge_wall_network_tile(
	cells: Dictionary,
	cell_order: Array[Vector2i],
	tile: WallTileDefinition,
	is_boundary: bool,
	is_internal: bool
) -> void:
	var cell := tile.grid_cell
	var incoming := _wall_network_piece(tile, is_boundary, is_internal)
	if not cells.has(cell):
		cells[cell] = incoming
		cell_order.append(cell)
		return
	var existing: Dictionary = cells[cell]
	existing["is_boundary"] = existing["is_boundary"] or is_boundary
	existing["is_internal"] = existing["is_internal"] or is_internal
	var existing_mask: int = existing["cardinal_mask"]
	var incoming_mask: int = incoming["cardinal_mask"]
	existing["cardinal_mask"] = existing_mask | incoming_mask
	var extra_segments: Array = existing["extra_segments"]
	extra_segments.append_array(incoming["extra_segments"])
	existing["extra_segments"] = extra_segments
	cells[cell] = existing


func _wall_network_piece(tile: WallTileDefinition, is_boundary: bool, is_internal: bool) -> Dictionary:
	return {
		"grid_cell": tile.grid_cell,
		"variant": tile.variant,
		"segments": tile.get_segments(),
		"cardinal_mask": WallTileDefinition.get_cardinal_mask(tile.variant),
		"extra_segments": [] if WallTileDefinition.get_cardinal_mask(tile.variant) != 0 else tile.get_segments(),
		"is_boundary": is_boundary,
		"is_internal": is_internal,
	}
