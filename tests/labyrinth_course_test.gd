extends "res://tests/test_support.gd"


func _test_labyrinth_nine_course() -> void:
	print("\n[Kurs: Labyrinth-Neun]")
	var holes := LegacyCourseFixtures.holes()
	var courses := LegacyCourseFixtures.courses()
	var course := courses.get_course(&"labyrinth_nine_course")
	_check(course != null, "Labyrinth-Neun wird als eigener Kurs geladen")
	if course == null:
		return
	_check(course.hole_ids.size() == 9, "Labyrinth-Neun enthaelt neun geordnete Bahnen")
	_check(course.get_total_par(holes) == 50, "Labyrinth-Neun besitzt Gesamt-Par 50")
	var layout_signatures := {}
	var obstacle_types := {}
	var obstacle_count := 0
	var diagonal_wall_count := 0
	for hole_id in course.hole_ids:
		var definition := holes.get_hole(hole_id)
		_check(definition != null and definition.is_course_hole(), "%s ist eine gueltige Kursbahn" % hole_id)
		if definition == null:
			continue
		_check(definition.lane_outline != null and definition.lane_outline.use_normalized_walls and definition.course_rect == Rect2(176, 16, 960, 336), "%s verwendet die grosse normierte Labyrinth-Grundflaeche" % hole_id)
		_check(definition.walls.is_empty() and definition.wall_tiles.size() >= 24, "%s baut sein Labyrinth aus mindestens 24 atomaren Wandkaestchen" % hole_id)
		_check(definition.obstacles.size() >= 2 and definition.obstacles.size() <= 3, "%s kombiniert zwei oder drei bewegliche Hindernisse" % hole_id)
		var signature := ""
		for tile in definition.wall_tiles:
			signature += "%s:%d;" % [tile.grid_cell, tile.variant]
			if tile.variant == WallTileDefinition.Variant.DIAGONAL_DOWN or tile.variant == WallTileDefinition.Variant.DIAGONAL_UP:
				diagonal_wall_count += 1
		layout_signatures[signature] = true
		for obstacle in definition.obstacles:
			obstacle_types[obstacle.obstacle_type] = true
			obstacle_count += 1
	_check(layout_signatures.size() == 9, "Alle neun Labyrinthbahnen besitzen einen eigenen Wandverlauf")
	_check(obstacle_count == 26, "Der Kurs verteilt insgesamt 26 bewegliche Hindernisse")
	_check(obstacle_types.size() == 3, "Labyrinth-Neun verwendet Rotoren, Schiebetore und Wippen")
	_check(diagonal_wall_count >= 30, "Zwei Labyrinthe verwenden zusammen mindestens dreissig Diagonalwaende")
	var diagonal_trap := holes.get_hole(&"labyrinth_nine_05")
	var lower_trap_diagonals := 0
	for tile in diagonal_trap.wall_tiles:
		if tile.grid_cell.y >= 12 and (tile.variant == WallTileDefinition.Variant.DIAGONAL_DOWN or tile.variant == WallTileDefinition.Variant.DIAGONAL_UP):
			lower_trap_diagonals += 1
	_check(lower_trap_diagonals == 22 and diagonal_trap.wall_tiles.size() == 64, "Diagonalfalle besitzt drei vollstaendig geschlossene, versetzte Dreiecke")
	var diagonal_boundary_connections := 0
	for piece in diagonal_trap.get_normalized_wall_network():
		if piece["is_boundary"] and not piece["extra_segments"].is_empty():
			diagonal_boundary_connections += 1
	_check(diagonal_boundary_connections == 6, "Alle sechs aeusseren Diagonalen der Diagonalfalle schliessen lueckenlos an die Aussenwand an")
	_check(
		diagonal_trap.obstacles[1].position == Vector2(752, 144)
			and is_equal_approx(diagonal_trap.obstacles[1].start_rotation_degrees, 90.0),
		"Der mittlere Dreher kontrolliert die versetzte Engstelle der Diagonalfalle"
	)
	var seesaw_labyrinth := holes.get_hole(&"labyrinth_nine_03")
	var labyrinth_seesaw: ObstacleDefinition = seesaw_labyrinth.obstacles.filter(func(obstacle): return obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SEESAW)[0]
	_check(
		labyrinth_seesaw.position == Vector2(456, 216)
			and is_equal_approx(labyrinth_seesaw.start_rotation_degrees, 270.0)
			and is_equal_approx(labyrinth_seesaw.seesaw_preferred_tilt, -1.0),
		"Wippen-Labyrinth richtet die abgesenkte Vorderseite nach unten zum ankommenden Ball aus"
	)
	var closing_cells := [Vector2i(22, 16), Vector2i(23, 16), Vector2i(24, 16), Vector2i(25, 16), Vector2i(31, 16), Vector2i(32, 16), Vector2i(33, 16), Vector2i(34, 16)]
	var closing_tiles := seesaw_labyrinth.wall_tiles.filter(func(tile): return tile.grid_cell in closing_cells)
	_check(
		closing_tiles.size() == closing_cells.size()
			and closing_tiles.any(func(tile): return tile.grid_cell == Vector2i(22, 16) and tile.variant == WallTileDefinition.Variant.T_RIGHT)
			and closing_tiles.any(func(tile): return tile.grid_cell == Vector2i(34, 16) and tile.variant == WallTileDefinition.Variant.T_LEFT),
		"Normwaende schliessen beide Seiten der gedrehten Wippe lueckenlos"
	)
	var crossways := holes.get_hole(&"labyrinth_nine_07")
	var crossways_seesaw: ObstacleDefinition = crossways.obstacles.filter(func(obstacle): return obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SEESAW)[0]
	_check(crossways_seesaw.position == Vector2(1024, 168) and crossways_seesaw.seesaw_size == Vector2(96, 80), "Kreuzwege setzt seine Wippe als Bruecke in die letzte Wandoeffnung")
	var t_piece_count := 0
	var boundary_t_piece_count := 0
	for hole_id in course.hole_ids:
		var definition := holes.get_hole(hole_id)
		for tile in definition.wall_tiles:
			if tile.variant >= WallTileDefinition.Variant.T_UP:
				t_piece_count += 1
		for piece in definition.get_normalized_wall_network():
			if piece["is_boundary"] and piece["variant"] >= WallTileDefinition.Variant.T_UP:
				boundary_t_piece_count += 1
	_check(t_piece_count >= 8, "T-Stuecke schliessen mindestens acht Wand- und Hindernisuebergaenge")
	_check(boundary_t_piece_count >= 24, "Aussen- und Innenwaende bilden an mindestens vierundzwanzig Anschluessen gemeinsame T-Stuecke")
	var first_network := holes.get_hole(&"labyrinth_nine_01").get_normalized_wall_network()
	var first_outer_junction: Dictionary = {}
	for piece in first_network:
		if piece["grid_cell"] == Vector2i(22, 1):
			first_outer_junction = piece
			break
	_check(
		not first_outer_junction.is_empty()
			and first_outer_junction["is_boundary"]
			and first_outer_junction["variant"] == WallTileDefinition.Variant.T_DOWN
			and first_outer_junction["segments"].size() == 3,
		"Eine von oben anschliessende Innenwand ersetzt das Aussenwandkaestchen durch ein lueckenloses T-Stueck"
	)

	var routes := LabyrinthRoutes.geometry_routes()
	for hole_id in course.hole_ids:
		var completed := await _simulate_hole_route(hole_id, routes[hole_id], &"labyrinth_geometry")
		_check(completed, "%s besitzt eine vereinfachte Geometrieroute; aktive Hindernisse sind damit nicht nachgewiesen" % hole_id)


