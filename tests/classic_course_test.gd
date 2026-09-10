extends "res://tests/test_support.gd"


func _test_classic_nine_course() -> void:
	print("\n[Kurs: Klassische Neun]")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	var course := courses.get_course(&"classic_nine_course")
	_check(course != null, "Klassische Neun wird als eigener Kurs geladen")
	if course == null:
		return
	_check(course.hole_ids.size() == 9, "Klassische Neun enthaelt neun geordnete Bahnen")
	_check(course.get_total_par(holes) == 19, "Klassische Neun besitzt Gesamt-Par 19")
	var par_counts := {1: 0, 2: 0, 3: 0}
	var compact_count := 0
	var wide_count := 0
	var circle_count := 0
	var arc_count := 0
	var arrow_count := 0
	var arrow_hole_counts := {}
	var outline_signatures := {}
	var legacy_rectangle_count := 0
	for hole_id in course.hole_ids:
		var definition := holes.get_hole(hole_id)
		_check(definition != null and definition.is_course_hole(), "%s ist eine gueltige Kursbahn" % hole_id)
		if definition == null:
			continue
		par_counts[definition.par] = int(par_counts.get(definition.par, 0)) + 1
		_check(
			definition.lane_outline != null
				and definition.lane_outline.use_normalized_walls
				and is_equal_approx(definition.lane_outline.wall_thickness, 4.0),
			"%s besitzt eine geschlossene Kontur aus vier Pixel starken Normwaenden" % hole_id
		)
		var outline_signature := ""
		for point in definition.lane_outline.points:
			outline_signature += "%s;" % point
		outline_signatures[outline_signature] = true
		_check(
			definition.surfaces.is_empty()
				and definition.obstacles.is_empty()
				and definition.triggers.is_empty()
				and definition.cannons.is_empty(),
			"%s bleibt ohne Legacy-Flaechen und dynamische Mechaniken" % hole_id
		)
		if definition.course_rect == Rect2(176, 16, 448, 328) and definition.camera_center_bounds.size == Vector2.ZERO:
			compact_count += 1
		elif definition.course_rect == Rect2(176, 16, 832, 328) and definition.camera_center_bounds == Rect2(320, 180, 376, 0):
			wide_count += 1
		for wall in definition.walls:
			if wall.wall_type == WallDefinition.WallType.CIRCLE:
				circle_count += 1
			elif wall.wall_type == WallDefinition.WallType.ARC:
				arc_count += 1
				_check(is_equal_approx(wall.thickness, 4.0), "%s verwendet vier Pixel starke Kreisboegen" % hole_id)
			else:
				legacy_rectangle_count += 1
		for arc in definition.lane_outline.boundary_arcs:
			arc_count += 1
			_check(arc.wall_type == WallDefinition.WallType.ARC and is_equal_approx(arc.thickness, 4.0), "%s verwendet vier Pixel starke echte Aussenboegen" % hole_id)
		for tile in definition.wall_tiles:
			_check(tile != null and tile.validate("Klassik-Wand", definition.grid_spacing).is_empty(), "%s verwendet nur atomare Normwandbausteine" % hole_id)
		for tile in definition.arrow_tiles:
			arrow_count += 1
			_check(
				tile.cell_size == 16
					and tile.slope_grade == SurfaceZone.SlopeGrade.SHALLOW
					and is_equal_approx(tile.deceleration, 30.0)
					and is_zero_approx(tile.minimum_flow_speed)
					and is_zero_approx(tile.maximum_flow_speed)
					and is_zero_approx(tile.flow_alignment_rate)
					and is_zero_approx(tile.flow_centering_strength),
				"%s verwendet nur atomare flache Pfeile ohne Flow-Assistenz" % hole_id
			)
		if not definition.arrow_tiles.is_empty():
			arrow_hole_counts[hole_id] = definition.arrow_tiles.size()
	_check(par_counts == {1: 3, 2: 3, 3: 2, 4: 1}, "Par-Verteilung folgt der festgelegten Folge von eins bis vier Schlaegen")
	_check(compact_count == 6 and wide_count == 3, "Sechs Bahnen sind kompakt und drei scrollen horizontal")
	_check(outline_signatures.size() == 9, "Alle neun Bahnen besitzen eine eigene geschlossene Silhouette")
	_check(legacy_rectangle_count == 0, "Klassische Neun enthaelt keine freien rechteckigen Legacy-Waende")
	_check(circle_count == 8 and arc_count == 7, "Kurs bewahrt exakt acht Kreisbumper und sieben Kreisboegen")
	_check(
		arrow_count == 36
			and arrow_hole_counts == {&"classic_nine_03": 12, &"classic_nine_06": 12, &"classic_nine_08": 12},
		"Nur Bogenschuss, Engstelle und Kreisallee besitzen je ein kleines Pfeilfeld"
	)
	var expected_arrow_shapes := {
		&"classic_nine_03": [4, 3, SurfaceZone.SlopeDirection.UP_RIGHT],
		&"classic_nine_06": [3, 4, SurfaceZone.SlopeDirection.UP_RIGHT],
		&"classic_nine_08": [4, 3, SurfaceZone.SlopeDirection.RIGHT],
	}
	for hole_id in expected_arrow_shapes:
		var definition := holes.get_hole(hole_id)
		var x_cells := {}
		var y_cells := {}
		var expected: Array = expected_arrow_shapes[hole_id]
		var directions_match := true
		for tile in definition.arrow_tiles:
			x_cells[tile.grid_cell.x] = true
			y_cells[tile.grid_cell.y] = true
			if tile.direction != expected[2]:
				directions_match = false
		_check(x_cells.size() == expected[0] and y_cells.size() == expected[1] and directions_match, "%s besitzt das festgelegte zusammenhaengende Pfeilraster" % hole_id)

	var horseshoe := holes.get_hole(&"classic_nine_04")
	_check(horseshoe.walls.is_empty() and horseshoe.wall_tiles.is_empty() and horseshoe.lane_outline.boundary_arcs.size() == 1, "Das Hufeisen bildet eine echte runde Zielkammer statt eines Bogens vor einer zweiten Aussenwand")
	var zigzag := holes.get_hole(&"classic_nine_07")
	var diagonal_down_count := zigzag.wall_tiles.filter(func(tile): return tile.variant == WallTileDefinition.Variant.DIAGONAL_DOWN).size()
	var diagonal_up_count := zigzag.wall_tiles.filter(func(tile): return tile.variant == WallTileDefinition.Variant.DIAGONAL_UP).size()
	var first_baffle_is_anchored := zigzag.wall_tiles.any(func(tile): return tile.grid_cell == Vector2i(23, 3) and tile.variant == WallTileDefinition.Variant.DIAGONAL_DOWN)
	var second_baffle_is_anchored := zigzag.wall_tiles.any(func(tile): return tile.grid_cell == Vector2i(42, 18) and tile.variant == WallTileDefinition.Variant.DIAGONAL_UP)
	_check(
		diagonal_down_count == 10 and diagonal_up_count == 10 and first_baffle_is_anchored and second_baffle_is_anchored,
		"Der Zickzack-Weg verbindet zwei kurze gegensinnige Diagonalbaender abwechselnd mit der Aussenwand"
	)
	_check(
		zigzag.tee_position == Vector2(220, 72)
			and zigzag.hole_position == Vector2(960, 280)
			and zigzag.initial_aim_offset == Vector2(94, 28),
		"Der Zickzack-Weg fuehrt vom oberen linken Start zum unteren rechten Loch"
	)
	var homecoming := holes.get_hole(&"classic_nine_09")
	var homecoming_arcs := homecoming.lane_outline.boundary_arcs
	_check(
		homecoming_arcs.size() == 2
			and homecoming_arcs.all(func(wall): return wall.center == Vector2(856, 168) and is_equal_approx(absf(wall.arc_sweep_degrees), 180.0))
			and homecoming.walls.is_empty() and homecoming.wall_tiles.is_empty()
			and homecoming.par == 4
			and homecoming.hole_position == Vector2(220, 56),
		"Die Heimkehr bildet einen echten gleichmaessigen Haarnadelkanal ohne doppelten Rahmen oder Wandstummel"
	)

	var safe_routes := {
		&"classic_nine_01": [[0.0, 292.0]],
		&"classic_nine_02": [[-12.0, 408.0]],
		&"classic_nine_03": [[-36.0, 250.0], [Vector2(575, 74), 180.0]],
		&"classic_nine_04": [[0.0, 244.0]],
		&"classic_nine_05": [[-32.35, 387.5]],
		&"classic_nine_06": [[-24.0, 280.0], [Vector2(575, 72), 115.0]],
		&"classic_nine_07": [[Vector2(600, 270), 300.0], [Vector2(850, 100), 270.0], [Vector2(960, 280), 240.0]],
		&"classic_nine_08": [[-24.0, 420.0], [-28.5, 340.0], [Vector2(960, 72), 185.0]],
		&"classic_nine_09": [[Vector2(600, 280), 300.0], [Vector2(1000, 280), 300.0], [Vector2(960, 72), 220.0], [Vector2(220, 56), 420.0]],
	}
	for hole_id in course.hole_ids:
		_check(safe_routes[hole_id].size() <= holes.get_hole(hole_id).par, "%s PAR-Route verwendet nicht mehr Schlaege als erlaubt" % hole_id)
		_check(safe_routes[hole_id].all(func(shot): return shot[1] >= 78 and shot[1] <= 420), "%s PAR-Route liegt im spielbaren Kraftbereich" % hole_id)
		var completed := await _simulate_hole_route(hole_id, safe_routes[hole_id])
		_check(completed, "%s endet reproduzierbar innerhalb seines Pars" % hole_id)

	var risk_routes := {
		&"classic_nine_04": [[0.0, 244.0]],
		&"classic_nine_05": [[-32.35, 387.5]],
		&"classic_nine_06": [[-25.4, 406.0]],
		&"classic_nine_07": [[Vector2(600, 270), 310.0], [Vector2(960, -190), 420.0]],
		&"classic_nine_08": [[-24.0, 420.0], [-33.5, 420.0]],
		&"classic_nine_09": [[Vector2(1000, 280), 420.0], [Vector2(960, 72), 220.0], [Vector2(220, 56), 420.0]],
	}
	for hole_id in risk_routes:
		_check(risk_routes[hole_id].all(func(shot): return shot[1] >= 78 and shot[1] <= 420), "%s Risiko-Route liegt im spielbaren Kraftbereich" % hole_id)
		var completed := await _simulate_hole_route(hole_id, risk_routes[hole_id])
		_check(completed, "%s besitzt die festgelegte anspruchsvolle Abkuerzung" % hole_id)


