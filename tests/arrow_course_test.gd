extends "res://tests/test_support.gd"


func _test_arrow_armageddon_course() -> void:
	print("\n[Kurs: Pfeil-Armageddon]")
	var holes := LegacyCourseFixtures.holes()
	var courses := LegacyCourseFixtures.courses()
	var course := courses.get_course(&"arrow_armageddon_course")
	_check(course != null, "Pfeil-Armageddon wird als eigener Kurs geladen")
	if course == null:
		return
	_check(course.hole_ids.size() == 9, "Pfeil-Armageddon enthaelt neun geordnete Bahnen")
	_check(course.get_total_par(holes) == 27, "Pfeil-Armageddon besitzt Gesamt-Par 27")
	var par_counts := {2: 0, 3: 0, 4: 0}
	var compact_count := 0
	var wide_count := 0
	var long_count := 0
	var arrow_count := 0
	var grade_counts := {0: 0, 1: 0, 2: 0}
	var sand_count := 0
	var water_count := 0
	var tunnel_count := 0
	var directions: Dictionary = {}
	var outline_signatures: Dictionary = {}
	# Field dimensions and continuous mandatory cuts are verified by the
	# dedicated course-design regressions, not inferred from cell counts.

	for hole_id in course.hole_ids:
		var definition := holes.get_hole(hole_id)
		_check(definition != null and definition.is_course_hole(), "%s ist eine gueltige Kursbahn" % hole_id)
		if definition == null:
			continue
		par_counts[definition.par] = int(par_counts.get(definition.par, 0)) + 1
		_check(definition.obstacles.is_empty() and definition.triggers.is_empty() and definition.cannons.is_empty(), "%s besitzt keine zeitabhaengige Mechanik" % hole_id)
		_check(definition.lane_outline != null and definition.lane_outline.use_normalized_walls, "%s besitzt eine eigene geschlossene Normwandkontur" % hole_id)
		_check(definition.walls.is_empty(), "%s verwendet keine freien Legacy-Banden" % hole_id)
		outline_signatures[str(definition.lane_outline.points)] = true
		tunnel_count += definition.tunnels.size()
		if definition.course_rect == Rect2(176, 16, 448, 328) and definition.camera_center_bounds.size == Vector2.ZERO:
			compact_count += 1
		elif definition.course_rect == Rect2(176, 16, 832, 328) and definition.camera_center_bounds == Rect2(320, 180, 376, 0):
			wide_count += 1
		elif definition.course_rect == Rect2(176, 16, 960, 328) and definition.camera_center_bounds == Rect2(320, 180, 504, 0):
			long_count += 1
		for surface in definition.surfaces:
			match surface.surface_type:
				SurfaceZone.SurfaceType.SAND:
					sand_count += 1
				SurfaceZone.SurfaceType.WATER:
					water_count += 1
				SurfaceZone.SurfaceType.SLOPE:
					_check(false, "%s verwendet keine Legacy-Gefaelleflaeche" % hole_id)
		for tile in definition.arrow_tiles:
			arrow_count += 1
			grade_counts[tile.slope_grade] = int(grade_counts.get(tile.slope_grade, 0)) + 1
			directions[tile.direction] = true
			_check(
				tile.cell_size == 16
					and is_equal_approx(tile.deceleration, 30.0)
					and is_zero_approx(tile.minimum_flow_speed)
					and is_zero_approx(tile.maximum_flow_speed)
					and is_zero_approx(tile.flow_alignment_rate)
					and is_zero_approx(tile.flow_centering_strength),
				"%s Pfeilzelle %s ist atomar und verwendet reines Gefaelle" % [hole_id, tile.grid_cell]
			)
		var hole_number := int(String(hole_id).get_slice("_", 2))
		if hole_number <= 3:
			_check(definition.arrow_tiles.all(func(tile): return tile.slope_grade == SurfaceZone.SlopeGrade.SHALLOW), "%s lehrt ausschliesslich flache gruene Pfeile" % hole_id)
		elif hole_number <= 6:
			_check(definition.arrow_tiles.any(func(tile): return tile.slope_grade == SurfaceZone.SlopeGrade.MEDIUM) and definition.arrow_tiles.all(func(tile): return tile.slope_grade != SurfaceZone.SlopeGrade.STEEP), "%s kombiniert mittlere Pfeile ohne steile rote Felder" % hole_id)
		else:
			_check(definition.arrow_tiles.any(func(tile): return tile.slope_grade == SurfaceZone.SlopeGrade.STEEP), "%s verwendet steile rote Pfeile als Hauptgefahr" % hole_id)
	_check(par_counts == {2: 3, 3: 3, 4: 3}, "Par-Verteilung besteht aus dreimal zwei, drei und vier")
	_check(compact_count == 5 and wide_count == 3 and long_count == 1, "Fuenf Bahnen sind kompakt und vier scrollen horizontal")
	_check(arrow_count == 834 and grade_counts.values().all(func(count): return count > 0), "Der ueberarbeitete Kurs verteilt 834 atomare Pfeilzellen auf alle drei Wirkungsstufen")
	print("Pfeilbestand: ", arrow_count, " Zellen, Stufen ", grade_counts)
	_check(sand_count == 1 and water_count == 2, "Nur eine Sand- und zwei Wasserflaechen ergaenzen die Pfeile")
	_check(tunnel_count == 1, "Nur die Pfeilspirale besitzt ein verborgenes Tunnelpaar")
	_check(directions.size() == 8, "Der Kurs verwendet alle acht Pfeilrichtungen")
	_check(outline_signatures.size() == 9, "Alle neun Bahnen besitzen eine eigenstaendige geschlossene Silhouette")
	var spiral := holes.get_hole(&"arrow_armageddon_06")
	_check(
		spiral.wall_tiles.size() == 101
			and spiral.lane_outline.points.has(Vector2(248, 88))
			and spiral.lane_outline.points.has(Vector2(840, 88))
			and spiral.wall_tiles.any(func(tile): return tile.variant >= WallTileDefinition.Variant.T_UP),
		"Die Pfeilspirale verbindet ihre Konturecken und inneren T-Anschluesse ohne doppelte Restflaechenwaende"
	)
	_check(
		spiral.tunnels.size() == 1
			and spiral.tunnels[0].endpoint_a == Vector2(808, 100)
			and spiral.tunnels[0].endpoint_b == Vector2(872, 100),
		"Das innere Sackgassenloch fuehrt verborgen in die geschlossene Zielkammer"
	)

	var water_guard := holes.get_hole(&"arrow_armageddon_08")
	var water_guard_red_tiles := water_guard.arrow_tiles.filter(
		func(tile): return tile.slope_grade == SurfaceZone.SlopeGrade.STEEP
	)
	var water_guard_points_inward := water_guard_red_tiles.size() == 48
	for tile in water_guard_red_tiles:
		if tile.grid_cell.y == 9:
			water_guard_points_inward = water_guard_points_inward and tile.direction == SurfaceZone.SlopeDirection.DOWN
		elif tile.grid_cell.y == 10:
			water_guard_points_inward = water_guard_points_inward and tile.direction == SurfaceZone.SlopeDirection.DOWN_LEFT
		elif tile.grid_cell.y == 11:
			water_guard_points_inward = water_guard_points_inward and tile.direction == SurfaceZone.SlopeDirection.UP_LEFT
		elif tile.grid_cell.y == 12:
			water_guard_points_inward = water_guard_points_inward and tile.direction == SurfaceZone.SlopeDirection.UP
		else:
			water_guard_points_inward = false
	_check(
		water_guard_points_inward,
		"Die roten Pfeile zeigen vom Wasser zur Mitte und die inneren Reihen zusaetzlich nach links"
	)
	var water_guard_runtime := _instantiate_hole(&"arrow_armageddon_08")
	await get_tree().physics_frame
	var center_release_ball := PrototypeBall.new()
	get_tree().root.add_child(center_release_ball)
	center_release_ball.set_physics_process(false)
	center_release_ball.position = Vector2(656, 176)
	center_release_ball.configure_environment(
		water_guard_runtime.zones,
		water_guard_runtime.get_hole_position(),
		water_guard_runtime.get_tunnels()
	)
	center_release_ball.launch(Vector2.RIGHT, 30.0, 1)
	for _step in range(600):
		center_release_ball._physics_process(1.0 / 60.0)
		if not center_release_ball.moving:
			break
	_check(
		center_release_ball.position.x < 552.0,
		"Ein langsamer Ball verlaesst die rote Mittellinie nach links statt dort festzuhaengen"
	)
	center_release_ball.free()
	water_guard_runtime.free()

	var routes := {
		&"arrow_armageddon_01": [[Vector2(490, 180), 250.0], [Vector2(580, 100), 180.0]],
		&"arrow_armageddon_02": [[Vector2(575, 70), 420.0], [Vector2(575, 70), 135.0]],
		&"arrow_armageddon_03": [[Vector2(475, 165), 290.0], [Vector2(580, 180), 130.0]],
		&"arrow_armageddon_04": [[Vector2(350, 235), 245.0], [Vector2(580, 180), 110.0], [Vector2(580, 180), 78.0]],
		&"arrow_armageddon_05": [[Vector2(395, 180), 230.0], [Vector2(575, 95), 225.0], [Vector2(575, 70), 100.0]],
		&"arrow_armageddon_06": [[-2.0, 360.0], [-180.0, 280.0], [-156.0, 370.0]],
		&"arrow_armageddon_07": [[Vector2(430, 235), 180.0], [Vector2(740, 160), 200.0], [Vector2(880, 130), 160.0], [Vector2(960, 70), 100.0]],
		&"arrow_armageddon_08": [[Vector2(540, 176), 280.0], [Vector2(800, 176), 360.0], [Vector2(900, 260), 180.0], [Vector2(960, 286), 140.0]],
		&"arrow_armageddon_09": [[-8.0, 340.0], [10.7078454479826, 200.0], [-6.42677758312242, 400.0]],
	}
	for hole_id in course.hole_ids:
		var shots: Array = routes[hole_id]
		_check(shots.size() <= holes.get_hole(hole_id).par and shots.all(func(shot): return shot[1] >= 78.0 and shot[1] <= 420.0), "%s verwendet nur legale Schlagstaerken innerhalb PAR" % hole_id)
		var completed := await _simulate_hole_route(hole_id, shots)
		_check(completed, "%s endet reproduzierbar innerhalb seines Pars" % hole_id)


