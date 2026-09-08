extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Nahtlose Wandanschluesse]")
	var rectangle := _outline(PackedVector2Array([Vector2(8, 8), Vector2(104, 8), Vector2(104, 104), Vector2(8, 104)]))
	var geometry := WallJoinGeometry.build(rectangle)
	check.call(geometry.contains_point(Vector2(6.5, 6.5)), "Rechtwinklige Bande besitzt eine echte geschlossene Aussengehrung")
	check.call(geometry.contains_point(Vector2(50, 9.9)) and not geometry.contains_point(Vector2(50, 10.1)), "Normbanden behalten ihre tatsaechliche Breite von vier Pixeln")
	check.call(not _has_boundary_at(geometry, Vector2(24, 8)), "Benachbarte Normsegmente enthalten weder sichtbare noch kollidierende innere Stirnnaehte")
	check.call(_edges_match_region(geometry), "Jede sichtbare Wandkante begrenzt dieselbe zusammenhaengende Kollisionsregion")

	var diagonal := _outline(PackedVector2Array([Vector2(8, 24), Vector2(24, 8), Vector2(88, 8), Vector2(104, 24), Vector2(104, 104), Vector2(8, 104)]))
	var diagonal_geometry := WallJoinGeometry.build(diagonal)
	check.call(diagonal_geometry.contains_point(Vector2(23.5, 6.5)), "45-Grad-Uebergang schliesst seine keilfoermige Luecke geometrisch")
	check.call(not _has_boundary_at(diagonal_geometry, Vector2(24, 8)), "45-Grad-Uebergang hat keine innere Abschlusskante")
	check.call(_edges_match_region(diagonal_geometry), "Diagonale Gehrungen zeichnen und kollidieren auf derselben Kontur")

	var tee := WallTileDefinition.new()
	tee.grid_cell = Vector2i(3, 0)
	tee.variant = WallTileDefinition.Variant.T_DOWN
	rectangle.wall_tiles.append(tee)
	var tee_geometry := WallJoinGeometry.build(rectangle)
	check.call(not _has_boundary_at(tee_geometry, Vector2(56, 9)), "T-Anschluss zur Aussenwand hat keine versteckte Fangnaht")
	check.call(tee_geometry.contains_point(Vector2(56, 14)), "T-Anschluss bleibt Teil der physischen Wand")

	var curved := _outline(PackedVector2Array([Vector2(8, 40), Vector2(88, 40), Vector2(136, 88), Vector2(136, 184), Vector2(8, 184)]))
	var arc := WallDefinition.new()
	arc.wall_type = WallDefinition.WallType.ARC
	arc.center = Vector2(88, 88)
	arc.radius = 48
	arc.thickness = 4
	arc.arc_start_degrees = -90
	arc.arc_sweep_degrees = 90
	arc.arc_segments = 24
	curved.lane_outline.boundary_arcs.append(arc)
	var curved_geometry := WallJoinGeometry.build(curved)
	check.call(not _has_boundary_at(curved_geometry, Vector2(88, 40)) and not _has_boundary_at(curved_geometry, Vector2(136, 88)), "Bogen und Normwand teilen lueckenlose Anschluesse ohne doppelte Stirnlinien")
	check.call(_edges_match_region(curved_geometry), "Bogenanschluesse verwenden dieselbe sichtbare und physische Kontur")

	arc.center.x += 0.005
	var offset_geometry := WallJoinGeometry.build(curved)
	check.call(
		curved.lane_outline.get_boundary_arc(1) == arc and offset_geometry.contains_point(Vector2(88.0025, 40)),
		"Gueltige Bogenabweichung von 0,005 Pixel wird am Konturanker lueckenlos geschlossen"
	)
	check.call(
		not _has_boundary_at(offset_geometry, Vector2(88, 40)) and not _has_boundary_at(offset_geometry, Vector2(136, 88)) and _edges_match_region(offset_geometry),
		"Beide Polygonkanten des versetzten Bogens enden ohne innere Naht an den exakten Wandankern"
	)
	arc.center = Vector2(88, 87.995)
	arc.rotation_degrees = 90
	arc.arc_start_degrees = -90
	arc.arc_sweep_degrees = -90
	var reversed_geometry := WallJoinGeometry.build(curved)
	check.call(
		curved.lane_outline.get_boundary_arc(1) == arc and reversed_geometry.contains_point(Vector2(136, 87.9975)),
		"Gedrehter Bogen mit negativem Winkelverlauf schliesst ebenfalls seine tolerierte Ankerabweichung"
	)
	check.call(
		not _has_boundary_at(reversed_geometry, Vector2(88, 40)) and not _has_boundary_at(reversed_geometry, Vector2(136, 88)) and _edges_match_region(reversed_geometry),
		"Umgekehrte Bogenrichtung behaelt nahtfreie sichtbare und physische Anschluesse"
	)

	var runtime := HoleRuntime.new()
	runtime.configure(diagonal)
	host.get_tree().root.add_child(runtime)
	var ball := PrototypeBall.new()
	host.get_tree().root.add_child(ball)
	await host.get_tree().physics_frame
	ball.set_physics_process(false)
	ball.configure_environment([], Vector2(10000, 10000))
	ball.position = Vector2(35, 35)
	var feedback := {"hit": false}
	ball.wall_hit.connect(func(_speed, _point, _normal, _kind): feedback["hit"] = true)
	ball.launch(Vector2(-1, -1), 520, 1)
	for _step in range(8):
		ball._physics_process(1.0 / 60.0)
	check.call(feedback["hit"] and diagonal.lane_outline.contains_point(ball.position), "Schneller Ball prallt am verbundenen Diagonalanschluss ab und bleibt auf der Bahn")
	check.call(runtime.overlay.wall_geometry == runtime.wall_geometry, "Overlay und Laufzeit teilen genau dieselbe vorberechnete Wandgeometrie")
	ball.free()
	runtime.free()


static func _outline(points: PackedVector2Array) -> HoleDefinition:
	var definition := HoleDefinition.new()
	definition.course_rect = Rect2(-16, -16, 240, 240)
	definition.tee_position = Vector2(40, 80)
	definition.hole_position = Vector2(80, 80)
	definition.lane_outline = LaneOutlineDefinition.new()
	definition.lane_outline.use_normalized_walls = true
	definition.lane_outline.points = points
	return definition


static func _has_boundary_at(geometry: WallJoinGeometry, point: Vector2) -> bool:
	for index in range(0, geometry.boundary_segments.size(), 2):
		if Geometry2D.get_closest_point_to_segment(point, geometry.boundary_segments[index], geometry.boundary_segments[index + 1]).distance_to(point) < 0.001:
			return true
	return false


static func _edges_match_region(geometry: WallJoinGeometry) -> bool:
	for index in range(0, geometry.boundary_segments.size(), 2):
		var start := geometry.boundary_segments[index]
		var end := geometry.boundary_segments[index + 1]
		var edge := end - start
		var midpoint := (start + end) * 0.5
		var normal := Vector2(-edge.y, edge.x).normalized() * 0.01
		if geometry.contains_point(midpoint + normal) == geometry.contains_point(midpoint - normal):
			return false
	return true
