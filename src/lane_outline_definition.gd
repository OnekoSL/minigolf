class_name LaneOutlineDefinition
extends Resource

@export var points := PackedVector2Array()
@export_range(2.0, 24.0, 0.5) var wall_thickness := 4.0
@export var use_normalized_walls := false


func validate(label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if points.size() < 3:
		errors.append("%s besitzt weniger als drei Konturpunkte" % label)
		return errors
	if wall_thickness <= 0.0:
		errors.append("%s besitzt keine gueltige Bandenstaerke" % label)
	if use_normalized_walls and not is_equal_approx(wall_thickness, WallTileDefinition.THICKNESS):
		errors.append("%s muss fuer Normwaende exakt %.0f Pixel stark sein" % [label, WallTileDefinition.THICKNESS])
	var uses_orthogonal_grid := use_normalized_walls and _uses_orthogonal_grid()
	var uses_diagonal_grid := use_normalized_walls and _uses_diagonal_grid()
	var uses_mixed_grid := use_normalized_walls and not uses_orthogonal_grid and not uses_diagonal_grid and _uses_mixed_grid()
	if use_normalized_walls and not uses_orthogonal_grid and not uses_diagonal_grid and not uses_mixed_grid:
		errors.append("%s verwendet eine Kante ausserhalb der acht Normwandrichtungen" % label)
	var signed_area := 0.0
	for index in range(points.size()):
		var next_index := (index + 1) % points.size()
		var start := points[index]
		var end := points[next_index]
		if start.distance_to(end) <= wall_thickness:
			errors.append("%s besitzt eine zu kurze Konturkante %d" % [label, index])
		if uses_orthogonal_grid:
			if not _is_cell_center(start):
				errors.append("%s: Konturpunkt %d liegt nicht im 16-Pixel-Wandzentrumraster" % [label, index])
			var edge := end - start
			if not (is_zero_approx(edge.x) != is_zero_approx(edge.y)):
				errors.append("%s: Normwandkante %d ist weder waagerecht noch senkrecht" % [label, index])
			elif int(round(maxf(absf(edge.x), absf(edge.y)))) % WallTileDefinition.CELL_SIZE != 0:
				errors.append("%s: Normwandkante %d besitzt keine ganze Kaestchenlaenge" % [label, index])
		elif uses_diagonal_grid:
			if not _is_grid_corner(start):
				errors.append("%s: Diagonalkonturpunkt %d liegt nicht auf einer 16-Pixel-Rasterecke" % [label, index])
			var edge := end - start
			if not is_equal_approx(absf(edge.x), absf(edge.y)):
				errors.append("%s: Diagonalwandkante %d besitzt keinen 45-Grad-Winkel" % [label, index])
			elif int(round(absf(edge.x))) % WallTileDefinition.CELL_SIZE != 0:
				errors.append("%s: Diagonalwandkante %d besitzt keine ganze Kaestchenlaenge" % [label, index])
		elif uses_mixed_grid:
			if not _is_cell_center(start):
				errors.append("%s: Gemischter Konturpunkt %d liegt nicht im 16-Pixel-Wandzentrumraster" % [label, index])
			var edge := end - start
			var is_cardinal := is_zero_approx(edge.x) != is_zero_approx(edge.y)
			var is_diagonal := not is_zero_approx(edge.x) and not is_zero_approx(edge.y) and is_equal_approx(absf(edge.x), absf(edge.y))
			if not is_cardinal and not is_diagonal:
				errors.append("%s: Gemischte Normwandkante %d besitzt keine gueltige Richtung" % [label, index])
			elif int(round(maxf(absf(edge.x), absf(edge.y)))) % WallTileDefinition.CELL_SIZE != 0:
				errors.append("%s: Gemischte Normwandkante %d besitzt keine ganze Kaestchenlaenge" % [label, index])
		signed_area += start.x * end.y - end.x * start.y
	if absf(signed_area) < 1.0:
		errors.append("%s besitzt keine gueltige Flaeche" % label)
	for first_index in range(points.size()):
		var first_next := (first_index + 1) % points.size()
		for second_index in range(first_index + 1, points.size()):
			var second_next := (second_index + 1) % points.size()
			if second_index == first_next or second_next == first_index:
				continue
			var intersection = Geometry2D.segment_intersects_segment(
				points[first_index], points[first_next], points[second_index], points[second_next]
			)
			if intersection != null:
				errors.append("%s ueberschneidet sich an den Kanten %d und %d" % [label, first_index, second_index])
	if use_normalized_walls:
		var used_cells: Dictionary = {}
		for tile in get_normalized_wall_tiles():
			if used_cells.has(tile.grid_cell):
				errors.append("%s verwendet Wandkaestchen %s mehrfach" % [label, tile.grid_cell])
			used_cells[tile.grid_cell] = true
	return errors


func contains_point(point: Vector2) -> bool:
	return points.size() >= 3 and Geometry2D.is_point_in_polygon(point, points)


func get_closed_points() -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func get_normalized_wall_tiles() -> Array[WallTileDefinition]:
	var tiles: Array[WallTileDefinition] = []
	if not use_normalized_walls or points.size() < 3:
		return tiles
	if _uses_diagonal_grid():
		for index in range(points.size()):
			var current := points[index]
			var next := points[(index + 1) % points.size()]
			var edge_step := _cardinal_step(next - current)
			var edge_cells := int(round(absf(next.x - current.x) / WallTileDefinition.CELL_SIZE))
			var variant := WallTileDefinition.Variant.DIAGONAL_DOWN if edge_step.x == edge_step.y else WallTileDefinition.Variant.DIAGONAL_UP
			var start_corner := Vector2i(roundi(current.x / WallTileDefinition.CELL_SIZE), roundi(current.y / WallTileDefinition.CELL_SIZE))
			for step_index in range(edge_cells):
				var corner := start_corner + edge_step * step_index
				var cell := Vector2i(
					corner.x if edge_step.x > 0 else corner.x - 1,
					corner.y if edge_step.y > 0 else corner.y - 1
				)
				tiles.append(_make_tile(cell, variant))
		return tiles
	if not _uses_orthogonal_grid():
		return tiles
	for index in range(points.size()):
		var previous := points[(index - 1 + points.size()) % points.size()]
		var current := points[index]
		var next := points[(index + 1) % points.size()]
		var toward_previous := _cardinal_step(previous - current)
		var toward_next := _cardinal_step(next - current)
		var corner_variant := _variant_for_connections(toward_previous, toward_next)
		if corner_variant >= 0:
			tiles.append(_make_tile(_point_to_cell(current), corner_variant))
		var edge := next - current
		var edge_step := _cardinal_step(edge)
		var edge_cells := int(round(maxf(absf(edge.x), absf(edge.y)) / WallTileDefinition.CELL_SIZE))
		var straight_variant := WallTileDefinition.Variant.HORIZONTAL if edge_step.x != 0 else WallTileDefinition.Variant.VERTICAL
		for step_index in range(1, edge_cells):
			tiles.append(_make_tile(_point_to_cell(current) + edge_step * step_index, straight_variant))
	return tiles


func get_normalized_wall_pieces() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	if not use_normalized_walls:
		return pieces
	var tiles := get_normalized_wall_tiles()
	if not tiles.is_empty():
		for tile in tiles:
			pieces.append({"variant": tile.variant, "segments": tile.get_segments()})
		return pieces
	if not _uses_mixed_grid():
		return pieces
	for index in range(points.size()):
		var start := points[index]
		var end := points[(index + 1) % points.size()]
		var edge := end - start
		var cell_count := int(round(maxf(absf(edge.x), absf(edge.y)) / WallTileDefinition.CELL_SIZE))
		var step := edge / float(cell_count)
		var variant := _variant_for_edge(edge)
		for step_index in range(cell_count):
			var segment_start := start + step * step_index
			var segment_end := segment_start + step
			pieces.append({
				"variant": variant,
				"segments": [_segment(segment_start, segment_end)],
			})
	return pieces


static func _is_cell_center(point: Vector2) -> bool:
	var half_cell := WallTileDefinition.CELL_SIZE * 0.5
	return is_zero_approx(fposmod(point.x - half_cell, WallTileDefinition.CELL_SIZE)) \
		and is_zero_approx(fposmod(point.y - half_cell, WallTileDefinition.CELL_SIZE))


static func _is_grid_corner(point: Vector2) -> bool:
	return is_zero_approx(fposmod(point.x, WallTileDefinition.CELL_SIZE)) \
		and is_zero_approx(fposmod(point.y, WallTileDefinition.CELL_SIZE))


func _uses_orthogonal_grid() -> bool:
	for index in range(points.size()):
		var edge := points[(index + 1) % points.size()] - points[index]
		if not (is_zero_approx(edge.x) != is_zero_approx(edge.y)):
			return false
	return true


func _uses_diagonal_grid() -> bool:
	for index in range(points.size()):
		var edge := points[(index + 1) % points.size()] - points[index]
		if is_zero_approx(edge.x) or is_zero_approx(edge.y) or not is_equal_approx(absf(edge.x), absf(edge.y)):
			return false
	return true


func _uses_mixed_grid() -> bool:
	var has_cardinal := false
	var has_diagonal := false
	for index in range(points.size()):
		if not _is_cell_center(points[index]):
			return false
		var edge := points[(index + 1) % points.size()] - points[index]
		var is_cardinal := is_zero_approx(edge.x) != is_zero_approx(edge.y)
		var is_diagonal := not is_zero_approx(edge.x) and not is_zero_approx(edge.y) and is_equal_approx(absf(edge.x), absf(edge.y))
		if not is_cardinal and not is_diagonal:
			return false
		if int(round(maxf(absf(edge.x), absf(edge.y)))) % WallTileDefinition.CELL_SIZE != 0:
			return false
		has_cardinal = has_cardinal or is_cardinal
		has_diagonal = has_diagonal or is_diagonal
	return has_cardinal and has_diagonal


static func _point_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / WallTileDefinition.CELL_SIZE), floori(point.y / WallTileDefinition.CELL_SIZE))


static func _cardinal_step(vector: Vector2) -> Vector2i:
	return Vector2i(signi(roundi(vector.x)), signi(roundi(vector.y)))


static func _variant_for_edge(edge: Vector2) -> int:
	if is_zero_approx(edge.y):
		return WallTileDefinition.Variant.HORIZONTAL
	if is_zero_approx(edge.x):
		return WallTileDefinition.Variant.VERTICAL
	return WallTileDefinition.Variant.DIAGONAL_DOWN if signf(edge.x) == signf(edge.y) else WallTileDefinition.Variant.DIAGONAL_UP


static func _segment(start: Vector2, end: Vector2) -> PackedVector2Array:
	return PackedVector2Array([start, end])


static func _variant_for_connections(first: Vector2i, second: Vector2i) -> int:
	var has_up := first == Vector2i.UP or second == Vector2i.UP
	var has_right := first == Vector2i.RIGHT or second == Vector2i.RIGHT
	var has_down := first == Vector2i.DOWN or second == Vector2i.DOWN
	var has_left := first == Vector2i.LEFT or second == Vector2i.LEFT
	if has_up and has_right:
		return WallTileDefinition.Variant.CORNER_UP_RIGHT
	if has_right and has_down:
		return WallTileDefinition.Variant.CORNER_RIGHT_DOWN
	if has_down and has_left:
		return WallTileDefinition.Variant.CORNER_DOWN_LEFT
	if has_left and has_up:
		return WallTileDefinition.Variant.CORNER_LEFT_UP
	if has_left and has_right:
		return WallTileDefinition.Variant.HORIZONTAL
	if has_up and has_down:
		return WallTileDefinition.Variant.VERTICAL
	return -1


static func _make_tile(cell: Vector2i, variant: int) -> WallTileDefinition:
	var tile := WallTileDefinition.new()
	tile.grid_cell = cell
	tile.variant = variant
	return tile
