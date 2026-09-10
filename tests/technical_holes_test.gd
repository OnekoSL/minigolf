extends "res://tests/test_support.gd"


func _test_wall_tiles() -> void:
	print("\n[Atomare Wandbausteine]")
	var signatures: Dictionary = {}
	for variant in range(12):
		var tile := WallTileDefinition.new()
		tile.grid_cell = Vector2i(20, 10)
		tile.variant = variant
		_check(tile.validate("Test-Wandbaustein", 16).is_empty(), "Wandvariante %d ist im 16-Pixel-Raster gueltig" % variant)
		_check(tile.get_cell_rect().size == Vector2(16, 16), "Wandvariante %d belegt genau ein Kaestchen" % variant)
		var segments := tile.get_segments()
		var expected_count := 2 if variant <= WallTileDefinition.Variant.CORNER_LEFT_UP else (3 if variant >= WallTileDefinition.Variant.T_UP else 1)
		_check(segments.size() == expected_count, "Wandvariante %d besitzt die normierte Segmentzahl" % variant)
		var signature_parts := PackedStringArray()
		for segment in segments:
			_check(segment.size() == 2 and tile.get_cell_rect().grow(0.1).has_point(segment[0]) and tile.get_cell_rect().grow(0.1).has_point(segment[1]), "Wandvariante %d bleibt in ihrem Kaestchen" % variant)
			signature_parts.append("%s>%s" % [segment[0], segment[1]])
		signatures["|".join(signature_parts)] = true
	_check(signatures.size() == 12, "Alle zwoelf Wandbausteine besitzen eine eigene Geometrie")
	_check(is_equal_approx(WallTileDefinition.THICKNESS, 4.0), "Normierte Wandstaerke betraegt vier Pixel")
	var invalid := WallTileDefinition.new()
	invalid.variant = 12
	_check(not invalid.validate("Ungueltiger Wandbaustein", 16).is_empty(), "Weitere Wandvarianten werden von der Datenvalidierung abgelehnt")


func _test_hole_catalog() -> void:
	print("\n[Datengetriebener Bahnkatalog]")
	var catalog := HoleCatalog.load_default()
	_check(catalog != null, "Lochkatalog wird als typisierte Resource geladen")
	if catalog == null:
		return
	_check(catalog.holes.size() == 50, "Katalog enthaelt sechsunddreissig echte Loecher und vierzehn Testbahnen")
	_check(catalog.validate().is_empty(), "Alle Bahndefinitionen bestehen die Datenvalidierung")
	var found_ids: Dictionary = {}
	for definition in catalog.holes:
		found_ids[definition.hole_id] = true
		var runtime := HoleRuntime.new()
		runtime.configure(definition)
		get_tree().root.add_child(runtime)
		var expected_zone_count := definition.surfaces.size() + definition.arrow_tiles.size()
		for obstacle in definition.obstacles:
			if obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SEESAW:
				expected_zone_count += 1
		_check(runtime.zones.size() == expected_zone_count, "%s erzeugt alle Flaechen" % definition.hole_id)
		_check(runtime.obstacle_nodes.size() == definition.obstacles.size(), "%s erzeugt alle Hindernisse" % definition.hole_id)
		_check(runtime.trigger_nodes.size() == definition.triggers.size(), "%s erzeugt alle Trigger" % definition.hole_id)
		_check(runtime.cannon_nodes.size() == definition.cannons.size(), "%s erzeugt alle Kanonen" % definition.hole_id)
		_check(runtime.overlay != null, "%s erzeugt eine sichtbare Bahnebene" % definition.hole_id)
		if not runtime.zones.is_empty():
			_check(runtime.overlay.get_index() > runtime.zones[-1].get_index(), "%s zeichnet Banden ueber den Flaechen" % definition.hole_id)
		runtime.queue_free()
	_check(found_ids.size() == 50, "Alle Bahn-IDs sind eindeutig")
	await get_tree().process_frame


func _test_slope_test_hole() -> void:
	print("\n[Gefaelle-Testloch]")
	var test_hole := _instantiate_hole(&"slope_lab")
	await get_tree().process_frame
	_check(test_hole.zones.size() == 8, "Testloch enthaelt acht Gefaellezonen")
	var found_directions: Dictionary = {}
	for zone in test_hole.zones:
		found_directions[zone.slope_direction] = true
	_check(found_directions.size() == 8, "Testloch zeigt jede Gefaellerichtung genau einmal")
	test_hole.queue_free()
	await get_tree().process_frame


func _test_flow_test_hole() -> void:
	print("\n[U-Flussbahn]")
	var test_hole := _instantiate_hole(&"flow_test")
	await get_tree().process_frame
	_check(test_hole.zones.size() == 5, "U-Bahn besteht aus fuenf lueckenlosen Richtungssegmenten")
	var required_directions := {
		SurfaceZone.SlopeDirection.DOWN: true,
		SurfaceZone.SlopeDirection.DOWN_RIGHT: true,
		SurfaceZone.SlopeDirection.RIGHT: true,
		SurfaceZone.SlopeDirection.UP_RIGHT: true,
		SurfaceZone.SlopeDirection.UP: true,
	}
	for zone in test_hole.zones:
		required_directions.erase(zone.slope_direction)
	_check(required_directions.is_empty(), "U-Bahn besitzt beide Kurven und alle drei Geraden")
	var flow_zone: SurfaceZone = test_hole.zones[0]
	var assisted := PrototypeBall.apply_flow_assist(
		Vector2.ZERO, Vector2.DOWN, flow_zone.minimum_flow_speed,
		flow_zone.maximum_flow_speed, flow_zone.flow_alignment_rate, 1.0 / 60.0
	)
	_check(
		assisted.is_equal_approx(Vector2.DOWN * flow_zone.minimum_flow_speed),
		"Flussbahn setzt einen bewegten, fast stehenden Ball wieder auf Mindesttempo"
	)
	var fast_sideways := PrototypeBall.apply_flow_assist(
		Vector2.RIGHT * 420.0, Vector2.DOWN, flow_zone.minimum_flow_speed,
		flow_zone.maximum_flow_speed, flow_zone.flow_alignment_rate, 1.0 / 60.0
	)
	_check(
		fast_sideways.length() < 420.0 and fast_sideways.length() > flow_zone.maximum_flow_speed,
		"Flussbahn reduziert zu schnelle Einfahrten allmaehlich statt sofort"
	)
	_check(fast_sideways.y > 0.0, "Flussbahn richtet seitliche Einfahrten zum naechsten Segment aus")
	var opposing := PrototypeBall.apply_flow_assist(
		Vector2.UP * 120.0, Vector2.DOWN, flow_zone.minimum_flow_speed,
		flow_zone.maximum_flow_speed, flow_zone.flow_alignment_rate, 1.0 / 60.0
	)
	_check(opposing.is_equal_approx(Vector2.UP * 120.0), "Flussbahn ueberschreibt einen Schlag gegen die Pfeilrichtung nicht")
	var reverse_ball := PrototypeBall.new()
	get_tree().root.add_child(reverse_ball)
	reverse_ball.set_physics_process(false)
	reverse_ball.position = test_hole.get_tee_position()
	reverse_ball.configure_environment(test_hole.zones, test_hole.get_hole_position())
	reverse_ball.launch(Vector2.UP, 120.0, 1)
	for _step in range(5):
		reverse_ball._physics_process(1.0 / 60.0)
	_check(
		reverse_ball.position.y < test_hole.get_tee_position().y and reverse_ball.velocity.y < 0.0,
		"Ball kann am U-Bahn-Abschlag sichtbar nach oben gespielt werden"
	)
	reverse_ball.free()
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = test_hole.get_tee_position()
	ball.configure_environment(test_hole.zones, test_hole.get_hole_position())
	var completed := {"value": false}
	ball.holed.connect(func(_strokes): completed["value"] = true)
	ball.launch(Vector2.RIGHT, 60.0, 1)
	for _step in range(1200):
		ball._physics_process(1.0 / 60.0)
		if completed["value"] or not ball.moving:
			break
	if not completed["value"] and ball.position.is_equal_approx(test_hole.get_hole_position()):
		await get_tree().create_timer(0.4).timeout
	_check(
		completed["value"],
		"Ball durchlaeuft die komplette U-Bahn ohne weiteren Schlag (Position %s, Tempo %.1f)" % [
			ball.position, ball.velocity.length()
		]
	)
	ball.free()
	test_hole.queue_free()
	await get_tree().process_frame


func _test_scroll_test_hole() -> void:
	print("\n[Scroll-Testbahn]")
	var test_hole := _instantiate_hole(&"scroll_test")
	await get_tree().process_frame
	_check(test_hole.get_course_rect().size.x > 640.0, "Scrollbahn ist breiter als der interne Bildschirm")
	_check(test_hole.get_course_rect().size.y > 360.0, "Scrollbahn ist hoeher als der interne Bildschirm")
	var bounds := test_hole.get_camera_center_bounds()
	_check(bounds.size.x > 0.0 and bounds.size.y > 0.0, "Scrollbahn erlaubt horizontale und vertikale Kamerafahrt")
	_check(bounds.end.is_equal_approx(Vector2(952.0, 532.0)), "Kameragrenze schliesst rechte und untere Aussenwand vollstaendig ein")
	_check(
		CourseCamera.clamp_to_bounds(Vector2(-1000, -1000), bounds).is_equal_approx(bounds.position),
		"Kamera zeigt am Bahnanfang nicht ueber den Rand hinaus"
	)
	_check(
		CourseCamera.clamp_to_bounds(Vector2(9999, 9999), bounds).is_equal_approx(bounds.end),
		"Kamera zeigt am Bahnende nicht ueber den Rand hinaus"
	)
	var deadzone := Rect2(220.0, 52.0, 360.0, 256.0)
	var resting_camera := CourseCamera.position_for_deadzone(
		Vector2(320, 180), Vector2(500, 180), bounds, Vector2(640, 360), deadzone
	)
	_check(resting_camera.is_equal_approx(Vector2(320, 180)), "Zielkreuz innerhalb des Ruhebereichs bewegt die Kamera nicht")
	var shifted_camera := CourseCamera.position_for_deadzone(
		Vector2(320, 180), Vector2(620, 180), bounds, Vector2(640, 360), deadzone
	)
	_check(shifted_camera.is_equal_approx(Vector2(360, 180)), "Zielkreuz am rechten Rand schiebt die Kamera nur um den Ueberstand")
	var lookahead := CourseCamera.lookahead_for_velocity(Vector2(600, 0), 0.12, 48.0)
	_check(lookahead.is_equal_approx(Vector2(48, 0)), "Ballvorlauf folgt der Bewegungsrichtung und bleibt auf 48 Pixel begrenzt")
	var gentle_lookahead := CourseCamera.lookahead_for_velocity(Vector2(100, -50), 0.12, 48.0)
	_check(gentle_lookahead.is_equal_approx(Vector2(12, -6)), "Ballvorlauf skaliert bei langsamem Rollen weich mit dem Tempo")
	var no_impact := CourseCamera.impact_for_collision(Vector2.LEFT, 100.0, 220.0, 520.0, 2.0)
	_check(no_impact == Vector2.ZERO, "Leichte Bandenkontakte bewegen die Kamera nicht")
	var maximum_impact := CourseCamera.impact_for_collision(Vector2.LEFT, 520.0, 220.0, 520.0, 2.0)
	_check(maximum_impact.is_equal_approx(Vector2(-2, 0)), "Kameraimpuls bleibt auf zwei interne Pixel begrenzt")
	var camera := CourseCamera.new()
	var target := Node2D.new()
	get_tree().root.add_child(target)
	get_tree().root.add_child(camera)
	target.position = test_hole.get_tee_position()
	camera.configure(target, bounds)
	camera.add_impact(Vector2.LEFT, 520.0)
	camera._process(camera.impact_decay_seconds)
	_check(camera.impact_offset.is_zero_approx(), "Kameraimpuls klingt innerhalb von 0,12 Sekunden vollstaendig aus")
	camera.set_focus_position(test_hole.get_hole_position())
	camera.snap_to_target()
	_check(camera.position.is_equal_approx(bounds.end.round()), "Zielkreuz fuehrt die Kamera pixelgenau zur rechten unteren Scrollgrenze")
	camera.queue_free()
	target.queue_free()
	test_hole.queue_free()
	await get_tree().process_frame


func _test_curve_lab() -> void:
	print("\n[Kurven-Labor]")
	var arc := WallDefinition.new()
	arc.wall_type = WallDefinition.WallType.ARC
	arc.radius = 64.0
	arc.thickness = 8.0
	arc.arc_start_degrees = 20.0
	arc.arc_sweep_degrees = 140.0
	arc.arc_segments = 20
	_check(arc.validate("Testbogen").is_empty(), "Gueltiger Kreisbogen besteht die Wandvalidierung")
	_check(arc.get_arc_polygon().size() == 42, "Bogen erzeugt eine geschlossene Kontur aus festen Segmenten")
	_check(arc.get_arc_centerline().size() == 21, "Darstellung und Kollision verwenden dieselbe Bogenaufloesung")
	var invalid_arc := WallDefinition.new()
	invalid_arc.wall_type = WallDefinition.WallType.ARC
	invalid_arc.radius = 4.0
	invalid_arc.thickness = 8.0
	_check(not invalid_arc.validate("Enger Bogen").is_empty(), "Zu enger Bogenradius wird abgelehnt")

	var test_hole := _instantiate_hole(&"curve_lab")
	await get_tree().process_frame
	var circles := 0
	var arcs := 0
	for wall in test_hole.definition.walls:
		if wall.wall_type == WallDefinition.WallType.CIRCLE:
			circles += 1
		elif wall.wall_type == WallDefinition.WallType.ARC:
			arcs += 1
	_check(test_hole.definition.category == HoleDefinition.HoleCategory.TECHNICAL, "Kurven-Labor bleibt eine technische Testbahn")
	_check(circles == 3 and arcs == 4, "Kurven-Labor kombiniert drei Kreise und vier Kreisboegen")
	_check(test_hole.definition.surfaces.is_empty() and test_hole.definition.obstacles.is_empty(), "Kurventest isoliert die neue Wandgeometrie")
	var circle_collisions := 0
	var arc_collisions := 0
	for child in test_hole.get_children():
		if child is not StaticBody2D:
			continue
		for collision in child.get_children():
			if collision is CollisionShape2D and collision.shape is CircleShape2D:
				circle_collisions += 1
			elif collision is CollisionPolygon2D:
				arc_collisions += 1
	_check(circle_collisions == circles, "Runde Bumper verwenden echte Kreiskollisionen")
	_check(arc_collisions == arcs, "Kreisboegen werden als zusammenhaengende Kollisionsbaender erzeugt")

	var ball := PrototypeBall.new()
	ball.position = Vector2(340, 180)
	get_tree().root.add_child(ball)
	await get_tree().physics_frame
	ball.launch(Vector2.RIGHT, 240.0, 1)
	var bounced := false
	for _step in range(45):
		await get_tree().physics_frame
		if ball.velocity.x < 0.0:
			bounced = true
			break
	_check(bounced, "Zentraler Kreisbumper reflektiert einen realen Ballkontakt")
	ball.queue_free()
	var arc_ball := PrototypeBall.new()
	get_tree().root.add_child(arc_ball)
	await get_tree().physics_frame
	var first_arc_hit := await _simulate_arc_hit(arc_ball)
	var second_arc_hit := await _simulate_arc_hit(arc_ball)
	_check(bool(first_arc_hit.get("hit", false)), "Unterer Kreisbogen reflektiert einen realen Ballkontakt")
	_check(
		Vector2(first_arc_hit.get("position", Vector2.ZERO)).distance_to(Vector2(second_arc_hit.get("position", Vector2.ZERO))) <= 0.1,
		"Identischer Bogentreffer bleibt bis auf 0,1 Pixel reproduzierbar"
	)
	_check(
		Vector2(first_arc_hit.get("velocity", Vector2.ZERO)).distance_to(Vector2(second_arc_hit.get("velocity", Vector2.ZERO))) <= 0.1,
		"Bogenreflexion liefert reproduzierbare Geschwindigkeit"
	)
	arc_ball.queue_free()
	test_hole.queue_free()
	await get_tree().process_frame


func _test_real_lane_references() -> void:
	print("\n[Reale Bahnkonturen und atomare Pfeilzellen]")
	var ids := [&"reference_gate_lane", &"reference_angle_lane", &"reference_mos_lane"]
	for hole_id in ids:
		var runtime := _instantiate_hole(hole_id)
		await get_tree().process_frame
		var definition := runtime.definition
		_check(definition.category == HoleDefinition.HoleCategory.TECHNICAL, "%s bleibt eine technische Referenzbahn" % hole_id)
		_check(definition.lane_outline != null, "%s besitzt eine eigene spielbare Bahnkontur" % hole_id)
		_check(definition.lane_outline.contains_point(definition.tee_position), "%s umfasst den Abschlag" % hole_id)
		_check(definition.lane_outline.contains_point(definition.hole_position), "%s umfasst das Zielloch" % hole_id)
		_check(definition.lane_outline.use_normalized_walls, "%s verwendet fuer die Aussenkontur Normwaende" % hole_id)
		var normalized_pieces := definition.lane_outline.get_normalized_wall_pieces()
		_check(not normalized_pieces.is_empty() and runtime.lane_boundary_nodes.size() == normalized_pieces.size(), "%s erzeugt fuer jedes Aussenwandstueck genau einen Kollisionskoerper" % hole_id)
		var boundaries_are_normalized := true
		for body in runtime.lane_boundary_nodes:
			if body.get_meta("wall_type", &"") != &"normalized_lane_boundary" or body.get_child_count() < 1:
				boundaries_are_normalized = false
				break
			for child in body.get_children():
				var collision := child as CollisionShape2D
				var joined_shape := collision.shape as ConcavePolygonShape2D if collision != null else null
				if joined_shape == null or joined_shape.segments.is_empty() or not is_equal_approx(body.get_meta("wall_thickness", 0.0), WallTileDefinition.THICKNESS):
					boundaries_are_normalized = false
					break
		_check(boundaries_are_normalized, "%s baut vier Pixel starke Normbanden mit ausschliesslich aeusseren Kollisionskanten" % hole_id)
		runtime.queue_free()
	await get_tree().process_frame

	var gate := HoleCatalog.load_default().get_hole(&"reference_gate_lane")
	_check(gate.par == 1 and gate.walls.is_empty() and gate.wall_tiles.size() == 2, "Tor-Gerade verwendet zwei normierte Wandkaestchen")
	_check(gate.wall_tiles[0].variant == WallTileDefinition.Variant.DIAGONAL_DOWN and gate.wall_tiles[1].variant == WallTileDefinition.Variant.DIAGONAL_UP, "Tor-Gerade verwendet beide diagonal gespiegelten Torstuecke")
	var gate_boundary_variants: Dictionary = {}
	for piece in gate.lane_outline.get_normalized_wall_pieces():
		gate_boundary_variants[piece["variant"]] = true
	_check(gate_boundary_variants.has(WallTileDefinition.Variant.DIAGONAL_DOWN) and gate_boundary_variants.has(WallTileDefinition.Variant.DIAGONAL_UP), "Tor-Gerade ersetzt die vier Zielstufen durch echte Diagonalwaende")
	var gate_is_symmetric := true
	for point in gate.lane_outline.points:
		if not gate.lane_outline.points.has(Vector2(point.x, 352.0 - point.y)):
			gate_is_symmetric = false
			break
	_check(gate_is_symmetric and is_equal_approx(gate.tee_position.y, 176.0) and is_equal_approx(gate.hole_position.y, 176.0), "Tor-Gerade ist um ihre horizontale Spielachse gespiegelt")
	var gate_runtime := _instantiate_hole(&"reference_gate_lane")
	await get_tree().process_frame
	_check(gate_runtime.wall_tile_nodes.size() == 2 and gate_runtime.wall_tile_nodes[0].get_child_count() == 1, "Tor-Gerade erzeugt fuer jeden Wandbaustein genau eine Kollision")
	gate_runtime.queue_free()
	await get_tree().process_frame
	var gate_completed := await _simulate_hole_route(&"reference_gate_lane", [
		[Vector2(554, 180), 282.0],
	])
	_check(gate_completed, "Tor-Gerade endet reproduzierbar mit einem Schlag")

	var angle := HoleCatalog.load_default().get_hole(&"reference_angle_lane")
	_check(angle.par == 2 and angle.walls.is_empty(), "Winkelbahn erzeugt ihre Aufgabe allein aus der Aussenkontur")
	_check(is_equal_approx(angle.lane_outline.points[5].x - angle.lane_outline.points[1].x, 144.0), "Winkelbahn besitzt einen auf 144 Pixel verschmaelerten Mittelteil")
	var angle_is_symmetric := true
	for point in angle.lane_outline.points:
		if not angle.lane_outline.points.has(Vector2(800.0 - point.x, 416.0 - point.y)):
			angle_is_symmetric = false
			break
	_check(angle_is_symmetric and angle.tee_position + angle.hole_position == Vector2(800, 416), "Winkelbahn ist samt Abschlag und Loch punktsymmetrisch")
	var angle_completed := await _simulate_hole_route(&"reference_angle_lane", [
		[Vector2(350, 260), 180.0],
		[Vector2(568, 144), 250.0],
	])
	_check(angle_completed, "Winkelbahn endet reproduzierbar mit zwei Schlaegen")

	var mos := HoleCatalog.load_default().get_hole(&"reference_mos_lane")
	_check(mos.par == 3 and mos.obstacles.size() == 1, "MOS-Kurve kombiniert diagonale Kontur und eine berechenbare Mechanik")
	var mos_is_horizontally_symmetric := true
	var mos_is_vertically_symmetric := true
	for point in mos.lane_outline.points:
		mos_is_horizontally_symmetric = mos_is_horizontally_symmetric and mos.lane_outline.points.has(Vector2(point.x, 416.0 - point.y))
		mos_is_vertically_symmetric = mos_is_vertically_symmetric and mos.lane_outline.points.has(Vector2(736.0 - point.x, point.y))
	_check(mos_is_horizontally_symmetric, "MOS-Kurve ist um ihre horizontale Spielachse gespiegelt")
	_check(mos_is_vertically_symmetric and mos.tee_position + mos.hole_position == Vector2(736, 416), "MOS-Kurve ist samt Abschlag und Loch vertikal gespiegelt")
	var mos_boundary_variants: Dictionary = {}
	for piece in mos.lane_outline.get_normalized_wall_pieces():
		mos_boundary_variants[piece["variant"]] = true
	_check(mos_boundary_variants.has(WallTileDefinition.Variant.DIAGONAL_DOWN), "MOS-Kurve verwendet abwaerts gerichtete Diagonalwaende")
	_check(mos_boundary_variants.has(WallTileDefinition.Variant.DIAGONAL_UP), "MOS-Kurve verwendet aufwaerts gerichtete Diagonalwaende")
	_check(mos.arrow_tiles.size() == 16, "MOS-Kurve besitzt ein 4-x-4-Pfeilfeld aus sechzehn atomaren Zellen")
	var used_grades: Dictionary = {}
	for index in range(mos.arrow_tiles.size()):
		var tile := mos.arrow_tiles[index]
		var rect := tile.get_rect()
		_check(is_equal_approx(rect.size.x, rect.size.y), "Pfeilzelle %d ist quadratisch" % index)
		_check(tile.cell_size == ArrowTileDefinition.CELL_SIZE and tile.cell_size == 16, "Pfeilzelle %d besitzt exakt 16 Pixel Seitenlaenge" % index)
		_check(int(rect.position.x) % tile.cell_size == 0 and int(rect.position.y) % tile.cell_size == 0, "Pfeilzelle %d liegt achsenparallel im Raster" % index)
		_check(tile.direction >= 0 and tile.direction < 8, "Pfeilzelle %d verwendet eine der acht Richtungen" % index)
		_check(is_equal_approx(tile.get_strength(), SurfaceZone.slope_strength_for_grade(tile.slope_grade as SurfaceZone.SlopeGrade)), "Pfeilzelle %d leitet ihre Kraft aus der Steigungsstufe ab" % index)
		used_grades[tile.slope_grade] = true
	_check(used_grades.size() == 3, "MOS-Pfeilfeld zeigt flache, mittlere und steile Zellen")
	_check(SurfaceZone.slope_color_for_grade(SurfaceZone.SlopeGrade.SHALLOW) == Color("#245537"), "Flache Pfeilzellen sind dunkelgruen")
	_check(SurfaceZone.slope_color_for_grade(SurfaceZone.SlopeGrade.MEDIUM) == Color("#244c70"), "Mittlere Pfeilzellen sind dunkelblau")
	_check(SurfaceZone.slope_color_for_grade(SurfaceZone.SlopeGrade.STEEP) == Color("#71343a"), "Steile Pfeilzellen sind dunkelrot")
	_check(SurfaceZone.slope_grade_from_strength(24.0) == SurfaceZone.SlopeGrade.SHALLOW, "Bestehende schwache Gefaelle werden als flach dargestellt")
	_check(SurfaceZone.slope_grade_from_strength(90.0) == SurfaceZone.SlopeGrade.MEDIUM, "Bestehende normale Gefaelle werden als mittel dargestellt")
	_check(SurfaceZone.slope_grade_from_strength(150.0) == SurfaceZone.SlopeGrade.STEEP, "Bestehende starke Gefaelle werden als steil dargestellt")
	var mos_runtime := _instantiate_hole(&"reference_mos_lane")
	await get_tree().process_frame
	for index in range(mos_runtime.zones.size()):
		var zone := mos_runtime.zones[index]
		var tile := mos.arrow_tiles[index]
		_check(zone.is_atomic_arrow_tile and is_zero_approx(zone.rotation), "MOS-Pfeilzelle wird ungedreht und mit genau einem Pfeil erzeugt")
		_check(zone.arrow_tile_grade == tile.slope_grade and is_equal_approx(zone.acceleration.length(), tile.get_strength()), "MOS-Pfeilzelle uebertraegt Steigungsstufe und Kraft in die Physik")
	mos_runtime.queue_free()
	await get_tree().process_frame
	var invalid_tile := ArrowTileDefinition.new()
	invalid_tile.cell_size = 32
	_check(not invalid_tile.validate("Ungueltige Testzelle", 16).is_empty(), "Pfeilzellen mit alter 32-Pixel-Seitenlaenge werden abgelehnt")
	var crossing_outline := LaneOutlineDefinition.new()
	crossing_outline.points = PackedVector2Array([Vector2(0, 0), Vector2(64, 64), Vector2(0, 64), Vector2(64, 0)])
	_check(not crossing_outline.validate("Kreuzende Testkontur").is_empty(), "Selbstueberschneidende Bahnkonturen werden abgelehnt")
	var mos_completed := await _simulate_hole_route(&"reference_mos_lane", [
		[Vector2(350, 240), 190.0],
		[Vector2(470, 188), 190.0],
		[Vector2(520, 220), 170.0],
	], &"reference_open")
	_check(mos_completed, "MOS-Kurve endet reproduzierbar innerhalb von drei Schlaegen")


func _test_gate_lane_family() -> void:
	print("\n[Bahn-1-Grundform mit Hindernisvarianten]")
	var catalog := HoleCatalog.load_default()
	var base := catalog.get_hole(&"reference_gate_lane")
	var variant_ids := [&"reference_gate_bumpers", &"reference_gate_rotor", &"reference_gate_slider", &"reference_gate_seesaw", &"reference_gate_hill"]
	for hole_id in variant_ids:
		var variant := catalog.get_hole(hole_id)
		_check(variant != null and variant.lane_outline.points == base.lane_outline.points and variant.tee_position == base.tee_position and variant.hole_position == base.hole_position, "%s verwendet unveraendert die symmetrische Bahn-1-Grundform" % hole_id)
	var bumpers := catalog.get_hole(&"reference_gate_bumpers")
	_check(bumpers.walls.size() == 3 and bumpers.walls.all(func(wall): return wall.wall_type == WallDefinition.WallType.CIRCLE), "Dreifach-Bumper verwendet drei statische Kreisbarrieren")
	var rotor := catalog.get_hole(&"reference_gate_rotor")
	_check(rotor.obstacles.size() == 1 and rotor.obstacles[0].obstacle_type == ObstacleDefinition.ObstacleType.ROTATING_BLADE, "Rotor-Variante verwendet genau ein rotierendes Hindernis")
	var slider := catalog.get_hole(&"reference_gate_slider")
	_check(slider.obstacles.size() == 1 and slider.obstacles[0].obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE, "Schiebetor-Variante verwendet genau ein zeitgesteuertes Hindernis")
	var seesaw := catalog.get_hole(&"reference_gate_seesaw")
	_check(seesaw.obstacles.size() == 1 and seesaw.obstacles[0].obstacle_type == ObstacleDefinition.ObstacleType.SEESAW, "Wippen-Variante verwendet genau eine gewichtsgesteuerte Plattform")
	var seesaw_runtime := _instantiate_hole(&"reference_gate_seesaw")
	await get_tree().process_frame
	_check(seesaw_runtime.obstacle_nodes.size() == 1 and seesaw_runtime.obstacle_nodes[0] is SeesawObstacle and seesaw_runtime.zones.has(seesaw_runtime.obstacle_nodes[0]), "Wippenplattform ist als befahrbare dynamische Gefaellezone eingebunden")
	seesaw_runtime.queue_free()
	await get_tree().process_frame
	var hill := catalog.get_hole(&"reference_gate_hill")
	var hill_grades := {}
	var hill_is_mirrored := hill.arrow_tiles.size() == 48
	var hill_rect: Rect2 = hill.arrow_tiles[0].get_rect()
	var hill_bands_correct := true
	var expected_hill_grades := [
		SurfaceZone.SlopeGrade.STEEP,
		SurfaceZone.SlopeGrade.STEEP,
		SurfaceZone.SlopeGrade.MEDIUM,
		SurfaceZone.SlopeGrade.MEDIUM,
		SurfaceZone.SlopeGrade.SHALLOW,
		SurfaceZone.SlopeGrade.SHALLOW,
		SurfaceZone.SlopeGrade.SHALLOW,
		SurfaceZone.SlopeGrade.SHALLOW,
		SurfaceZone.SlopeGrade.MEDIUM,
		SurfaceZone.SlopeGrade.MEDIUM,
		SurfaceZone.SlopeGrade.STEEP,
		SurfaceZone.SlopeGrade.STEEP,
	]
	for tile in hill.arrow_tiles:
		hill_grades[tile.slope_grade] = true
		hill_rect = hill_rect.merge(tile.get_rect())
		hill_bands_correct = hill_bands_correct and tile.slope_grade == expected_hill_grades[tile.grid_cell.x - 18]
		var mirrored_cell := Vector2i(47 - tile.grid_cell.x, tile.grid_cell.y)
		var mirrored_direction := SurfaceZone.SlopeDirection.RIGHT if tile.direction == SurfaceZone.SlopeDirection.LEFT else SurfaceZone.SlopeDirection.LEFT
		hill_is_mirrored = hill_is_mirrored and hill.arrow_tiles.any(func(other): return other.grid_cell == mirrored_cell and other.slope_grade == tile.slope_grade and other.direction == mirrored_direction)
	_check(hill_is_mirrored and hill_rect.size == Vector2(192, 64) and hill_bands_correct, "Huegelpass ist 12 Pfeile lang, beginnt beidseitig steil und spiegelt sich um seine Mittelachse")
	_check(hill_grades.size() == 3, "Huegelpass verwendet flache, mittlere und steile Pfeilbloecke")
	var hill_hole := catalog.get_hole(&"reference_gate_hill_hole")
	var hill_hole_rect: Rect2 = hill_hole.arrow_tiles[0].get_rect()
	var hill_hole_points_outward := hill_hole.arrow_tiles.size() == 49
	var hill_hole_tiers_correct := true
	var hill_hole_grid_correct := true
	var hill_hole_grades := {}
	for tile in hill_hole.arrow_tiles:
		hill_hole_rect = hill_hole_rect.merge(tile.get_rect())
		var tile_center := tile.get_rect().get_center()
		var radial_direction := hill_hole.hole_position.direction_to(tile_center)
		var arrow_direction := SurfaceZone.direction_vector(tile.direction as SurfaceZone.SlopeDirection)
		if not radial_direction.is_zero_approx():
			hill_hole_points_outward = hill_hole_points_outward and radial_direction.dot(arrow_direction) > 0.7
		var ring := int(maxf(absf(tile_center.x - hill_hole.hole_position.x), absf(tile_center.y - hill_hole.hole_position.y)) / 16.0)
		var expected_grade := SurfaceZone.SlopeGrade.STEEP if ring == 3 else (SurfaceZone.SlopeGrade.MEDIUM if ring == 2 else SurfaceZone.SlopeGrade.SHALLOW)
		hill_hole_tiers_correct = hill_hole_tiers_correct and tile.slope_grade == expected_grade
		hill_hole_grid_correct = hill_hole_grid_correct and tile.grid_offset == Vector2i(0, 8)
		hill_hole_grades[tile.slope_grade] = true
	_check(hill_hole_rect.size == Vector2(112, 112) and hill_hole_rect.get_center() == hill_hole.hole_position and hill_hole_grid_correct, "Huegelloch liegt exakt im Zentrum seines versetzten 7-x-7-Pfeilfelds")
	_check(hill_hole_points_outward, "Alle Pfeile des Huegellochs zeigen von der Kuppe nach aussen")
	_check(hill_hole_grades.size() == 3 and hill_hole_tiers_correct, "Huegelloch beginnt aussen steil und wird zum Loch hin flach")
	var hill_hole_is_symmetric := true
	for point in hill_hole.lane_outline.points:
		hill_hole_is_symmetric = hill_hole_is_symmetric and hill_hole.lane_outline.points.has(Vector2(point.x, 352.0 - point.y))
	_check(hill_hole_is_symmetric and hill_hole.lane_outline.points != base.lane_outline.points, "Huegelloch erweitert den Zielraum symmetrisch fuer das 7-x-7-Feld")
	var bumpers_completed := await _simulate_hole_route(&"reference_gate_bumpers", [
		[Vector2(440, 160), 250.0],
		[Vector2(552, 176), 170.0],
	])
	_check(bumpers_completed, "Dreifach-Bumper endet reproduzierbar innerhalb von Par 2")
	var rotor_completed := await _simulate_hole_route(&"reference_gate_rotor", [
		[Vector2(450, 148), 250.0],
		[Vector2(552, 176), 170.0],
	], &"reference_open")
	_check(rotor_completed, "Rotor-Variante endet reproduzierbar innerhalb von Par 2")
	var slider_completed := await _simulate_hole_route(&"reference_gate_slider", [
		[Vector2(552, 176), 282.0],
	], &"gates_open")
	_check(slider_completed, "Schiebetor-Variante endet bei offenem Tor reproduzierbar")
	var seesaw_completed := await _simulate_hole_route(&"reference_gate_seesaw", [
		[Vector2(552, 176), 240.0],
		[Vector2(552, 176), 145.0],
	], &"seesaw_weight")
	_check(seesaw_completed, "Wippen-Variante endet reproduzierbar innerhalb von Par 2")
	var hill_completed := await _simulate_hole_route(&"reference_gate_hill", [
		[Vector2(552, 176), 282.0],
		[Vector2(552, 176), 110.0],
	])
	_check(hill_completed, "Huegelpass endet reproduzierbar innerhalb von Par 2")
	var hill_hole_completed := await _simulate_hole_route(&"reference_gate_hill_hole", [
		[Vector2(552, 176), 282.0],
	])
	_check(hill_hole_completed, "Huegelloch endet reproduzierbar innerhalb von Par 2")


func _simulate_arc_hit(ball: PrototypeBall) -> Dictionary:
	ball.reset_to(Vector2(400, 225))
	ball.launch(Vector2.DOWN, 240.0, 1)
	for _step in range(45):
		await get_tree().physics_frame
		if ball.velocity.y < 0.0:
			return {"hit": true, "position": ball.position, "velocity": ball.velocity}
	return {"hit": false, "position": ball.position, "velocity": ball.velocity}


