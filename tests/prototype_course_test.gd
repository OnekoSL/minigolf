extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Prototypkurs: gestaltete Kursfassungen]")
	var catalog := LegacyCourseFixtures.holes()
	var course := LegacyCourseFixtures.courses().get_course(&"prototype_course_03")
	for hole_id in course.hole_ids:
		var hole := catalog.get_hole(hole_id)
		check.call(hole.is_course_hole() and hole.garden_presentation and hole.lane_outline.use_normalized_walls, "%s besitzt Kursstatus, Gartenoptik und Normkontur" % hole_id)
	for hole_id in [&"allround_test", &"slope_lab", &"flow_test", &"scroll_test", &"curve_lab"]:
		check.call(not catalog.get_hole(hole_id).is_course_hole() and not hole_id in course.hole_ids, "%s bleibt als separates Techniklabor erhalten" % hole_id)
	var routes := {
		&"prototype_04": [[Vector2(368,280),230.0],[Vector2(544,280),268.0],[Vector2(552,88),220.0]],
		&"prototype_05": [[Vector2(568,176),262.0],[Vector2(840,176),230.0],[Vector2(936,176),146.0]],
		&"prototype_06": [[Vector2(264,264),228.0],[Vector2(552,264),262.0],[Vector2(552,88),162.0]],
		&"prototype_07": [[Vector2(416,112),274.0],[Vector2(416,272),260.0],[Vector2(784,272),270.0],[Vector2(784,120),190.0],[Vector2(1064,120),256.0]],
		&"prototype_08": [[Vector2(275,264),204.0],[Vector2(408,344),192.0],[Vector2(552,264),198.0],[Vector2(552,88),202.0]],
	}
	for hole_id in routes:
		var hole := catalog.get_hole(hole_id)
		check.call(hole.validate().is_empty() and hole.walls.is_empty() and hole.wall_tiles.is_empty(), "%s: geschlossene Kontur ersetzt alte Rechteckbanden" % hole_id)
		check.call(hole.surfaces.all(func(surface): return surface.surface_type != SurfaceZone.SurfaceType.SLOPE), "%s verwendet keine alten Gefaelleflaechen" % hole_id)
		check.call(hole.arrow_tiles.all(func(tile): return tile.cell_size == 16 and tile.deceleration == 30 and tile.minimum_flow_speed == 0 and tile.maximum_flow_speed == 0 and tile.flow_alignment_rate == 0 and tile.flow_centering_strength == 0), "%s verwendet ausschliesslich reine atomare Pfeilphysik" % hole_id)
		for deviation in [-0.3,0.0,0.3]:
			check.call(await _play(host, hole, routes[hole_id], deviation), "%s: PAR-Route mit %+.1f Grad Anspielabweichung" % [hole_id,deviation])
	var hill := catalog.get_hole(&"prototype_05")
	check.call(_covers(hill, Rect2(360,136,64,80)) and _covers(hill, Rect2(680,136,64,80)), "Beide Huegel reichen ohne neutralen Randstreifen von Bande zu Bande")
	var river := catalog.get_hole(&"prototype_06")
	check.call(_covers(river, Rect2(216,136,96,48)) and _covers(river, Rect2(504,136,96,48)), "Beide Uferkehren-Felder fuellen den jeweiligen Kanal")
	var panorama := catalog.get_hole(&"prototype_07")
	check.call(_covers(panorama, Rect2(536,216,48,112)), "Panorama-Pflichtfeld fuellt den einzigen Querdurchgang")
	var curve := catalog.get_hole(&"prototype_08")
	check.call(curve.lane_outline.boundary_arcs.size() == 2 and curve.lane_outline.contains_point(Vector2(408,344)) and not curve.lane_outline.contains_point(Vector2(408,248)), "Bogenpromenade hat einen echten konzentrischen Wendekanal")


static func _covers(hole: HoleDefinition, rect: Rect2) -> bool:
	# Ball-centre sampling includes the narrow strips adjacent to both walls.
	for x in range(int(rect.position.x)+3,int(rect.end.x)-2,2):
		for y in range(int(rect.position.y)+3,int(rect.end.y)-2,2):
			if not hole.arrow_tiles.any(func(tile): return tile.get_rect().has_point(Vector2(x,y))):
				return false
	return true


static func _play(host: Node, hole: HoleDefinition, shots: Array, deviation: float) -> bool:
	var runtime := HoleRuntime.new()
	runtime.configure(hole)
	host.get_tree().root.add_child(runtime)
	await host.get_tree().physics_frame
	var ball := PrototypeBall.new()
	host.get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.configure_environment(runtime.zones, hole.hole_position)
	ball.position = hole.tee_position
	var state := {"holed":false,"hazard":false}
	ball.holed.connect(func(_count): state["holed"] = true)
	ball.hazard_entered.connect(func(_kind): state["hazard"] = true)
	var legal := shots.size() <= hole.par
	for index in range(shots.size()):
		var direction := ball.position.direction_to(shots[index][0])
		if index == 0: direction = direction.rotated(deg_to_rad(deviation))
		var speed: float = shots[index][1]
		legal = legal and speed >= 78 and speed <= 420
		ball.launch(direction,speed,index+1)
		for _step in range(1800):
			ball._physics_process(1.0/60.0)
			legal = legal and hole.lane_outline.contains_point(ball.position)
			if not ball.moving: break
		legal = legal and not ball.moving
		if ball.position.distance_to(hole.hole_position) < 0.01:
			await host.get_tree().create_timer(0.4).timeout
			break
	if not state["holed"]: print("  ",hole.hole_id," deviation=",deviation," stopped=",ball.position)
	ball.free()
	runtime.free()
	return legal and state["holed"] and not state["hazard"]
