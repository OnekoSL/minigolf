extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Stadtpark: roter Kreis und Gartenspirale]")
	var catalog := HoleCatalog.load_default()
	var circle := catalog.get_hole(&"classic_nine_04")
	var spiral := catalog.get_hole(&"classic_nine_06")
	var elbow := catalog.get_hole(&"stadtpark_07")
	check.call(elbow.validate().is_empty() and not elbow.lane_outline.contains_point(Vector2(436,60)) and not elbow.lane_outline.contains_point(Vector2(364,292)),
		"Parkbank: Die beiden aeusseren Umlenkecken sind diagonal abgeschnitten")
	var elbow_walls := WallJoinGeometry.build(elbow)
	check.call(elbow_walls.contains_point(Vector2(424,72)) and elbow_walls.contains_point(Vector2(376,280)) and not elbow_walls.contains_point(Vector2(400,96)) and not elbow_walls.contains_point(Vector2(400,256)),
		"Parkbank: Beide Diagonalen kollidieren, die PAR-Anspielpunkte bleiben frei")
	check.call(circle.validate().is_empty() and spiral.validate().is_empty(),"Beide Stadtpark-Umbauten erfuellen die Bahndatenregeln")
	check.call(circle.arrow_tiles.size()>100 and circle.arrow_tiles.all(func(t): return t.direction==SurfaceZone.SlopeDirection.LEFT and t.slope_grade==SurfaceZone.SlopeGrade.STEEP),
		"Der Pavillon-Kreis besteht aus roten 16-Pixel-Pfeilen nach links")
	var runtime := HoleRuntime.new()
	runtime.configure(circle)
	host.add_child(runtime)
	var cells: Dictionary = {}
	for index in range(circle.arrow_tiles.size()):
		cells[circle.arrow_tiles[index].grid_cell] = runtime.zones[index]
	var covered := true
	var samples := 0
	var center := circle.hole_position
	var radius := circle.lane_outline.boundary_arcs[0].radius-2.0
	for y in range(75,278,2):
		for x in range(363,566,2):
			var point := Vector2(x,y)
			if point.distance_to(center)>radius or not circle.lane_outline.contains_point(point):
				continue
			var zone: SurfaceZone = cells.get(Vector2i(x/16,y/16))
			covered = covered and zone != null and zone.contains_global_point(point)
			samples += 1
	check.call(covered and samples>7000,"Der gesamte befahrbare Kreis einschliesslich Rand ist ohne neutrale Streifen belegt")
	check.call(not runtime.zones.any(func(z): return z.contains_global_point(circle.tee_position)),"Der Abschlag bleibt ausserhalb des roten Gefaelles")
	var excluded := 0
	var valid_clip := true
	for index in range(circle.arrow_tiles.size()):
		var tile := circle.arrow_tiles[index]
		if tile.clip_polygon.is_empty(): continue
		for corner in [Vector2(0.1,0.1),Vector2(15.9,0.1),Vector2(15.9,15.9),Vector2(0.1,15.9)]:
			if Geometry2D.is_point_in_polygon(corner,tile.clip_polygon): continue
			excluded += 1
			valid_clip = valid_clip and not runtime.zones[index].contains_global_point(tile.get_rect().position+corner)
	check.call(valid_clip and excluded>20,"Abgeschnittene Zellbereiche erzeugen kein unsichtbares Gefaelle ausserhalb des Kreises")
	var invalid_tile := circle.arrow_tiles[0].duplicate(true) as ArrowTileDefinition
	invalid_tile.clip_polygon = PackedVector2Array([Vector2(-1,0),Vector2(16,0),Vector2(16,16)])
	check.call(not invalid_tile.validate("Randzelle",16).is_empty(),"Zellzuschnitt ausserhalb des festen 16-Pixel-Rasters wird abgewiesen")
	runtime.queue_free()
	await host.get_tree().process_frame
	check.call(spiral.hole_position.distance_to(spiral.course_rect.get_center())<20 and spiral.initial_aim_offset.y<0,
		"Gartenspirale startet nach oben und endet in der Mitte")
	check.call(spiral.arrow_tiles.is_empty() and spiral.lane_outline.boundary_arcs.size()==10,"Die Spirale besitzt zehn echte Bogenanschluesse und keine alte Gartentor-Geometrie")
	var floor_points := spiral.lane_outline.get_floor_points()
	for gate in [Rect2(396,48,8,64),Rect2(528,180,64,8),Rect2(428,256,8,64),Rect2(272,220,64,8)]:
		var cut := PackedVector2Array([gate.position,Vector2(gate.end.x,gate.position.y),gate.end,Vector2(gate.position.x,gate.end.y)])
		var shortcut := false
		for region in Geometry2D.clip_polygons(floor_points,cut):
			shortcut = shortcut or (Geometry2D.is_point_in_polygon(spiral.tee_position,region) and Geometry2D.is_point_in_polygon(spiral.hole_position,region))
		check.call(not shortcut,"Spirale erzwingt die Passage bei %s; keine direkte Aussenabkuerzung" % gate.position)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	for entry in entries:
		if entry.id not in ["classic_nine_04","classic_nine_06","stadtpark_07"]: continue
		var hole := catalog.get_hole(StringName(entry.id))
		for test_case in [[&"allrounder",0.0,1.0],[&"mara",0.0,1.0],[&"bruno",0.0,1.0],[&"nika",0.0,1.0],[&"allrounder",-0.3,1.0],[&"allrounder",0.3,1.0],[&"allrounder",0.0,0.99],[&"allrounder",0.0,1.01]]:
			var route := WorldRouteFixtures.route(entry,test_case[0],test_case[1],test_case[2])
			var result := await LiveRouteRunner.play(host,hole,route,test_case[0])
			check.call(result.within_par,"%s: PAR-Route %s, Winkel %+.1f, Kraft %.2f" % [entry.id,test_case[0],test_case[1],test_case[2]])
			if not result.within_par: print(JSON.stringify(result))
