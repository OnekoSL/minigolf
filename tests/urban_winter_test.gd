extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Urban Winter: Eis, Beton und aktive Routen]")
	var catalog := HoleCatalog.load_default()
	var course := CourseCatalog.load_default().get_course(&"urban_winter_course")
	check.call(course != null and course.hole_ids.size() == 9 and course.best_score_revision == 1, "Urban Winter: neun Bahnen mit eigenem Bestwertschluessel")
	await _physics(host, check)
	await _short_putts(host, check, catalog.get_hole(&"urban_winter_07"))
	await _lifecycle(host, check, catalog.get_hole(&"urban_winter_07"))
	await _obstacles(host, check, catalog)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/urban_winter_routes.json"))
	var ice_cups := 0
	for entry in entries:
		var h := catalog.get_hole(StringName(entry.id))
		check.call(h.validate().is_empty() and h.base_surface == SurfaceZone.SurfaceType.CONCRETE, "%s: gueltige Betonbahn" % entry.id)
		check.call(h.surfaces.all(func(s): return s.surface_type == SurfaceZone.SurfaceType.ICE and not s.rect.has_point(h.tee_position)), "%s: ausschliesslich Eis-Sonderflaechen und Betonabschlag" % entry.id)
		if h.surfaces.any(func(s): return s.rect.has_point(h.hole_position)): ice_cups += 1
		check.call(_ice_is_required(h), "%s: kontinuierlicher Konturschnitt belegt Eis als Pflichtpassage" % entry.id)
		check.call(_clear_point(h,h.tee_position) and _clear_point(h,h.hole_position), "%s: Abschlag und Ziel besitzen freien Ballradius" % entry.id)
		for golfer in GolferDefinition.IDS:
			var base := WorldRouteFixtures.route(entry,golfer)
			var result := await LiveRouteRunner.play(host,h,base,golfer)
			check.call(result.within_par and result.contact_delays.all(func(t): return t == 6), "%s: aktive PAR-Route fuer %s" % [entry.id,golfer])
			if entry.id == "urban_winter_02": check.call(result.trace[0].contacts == 1, "Vereiste Kurve wird mit einem echten Bandenkontakt gespielt")
			for shot_index in range(base.size()):
				for v in [Vector2(-0.3,1),Vector2(0.3,1),Vector2(0,0.99),Vector2(0,1.01)]:
					var route := WorldRouteFixtures.route(entry,golfer)
					var origin := h.tee_position if shot_index == 0 else Vector2(result.trace[shot_index-1].position[0],result.trace[shot_index-1].position[1])
					route[shot_index].target = origin + (route[shot_index].target-origin).rotated(deg_to_rad(v.x))
					route[shot_index].speed *= v.y
					var trial := await LiveRouteRunner.play(host,h,route,golfer)
					check.call(trial.within_par, "%s %s Schlag %d: %.1f Grad / %.2f Kraft bleibt in PAR" % [entry.id,golfer,shot_index+1,v.x,v.y])
					if not trial.within_par: print("WINTER ROUTENLUECKE ",JSON.stringify(trial))
	check.call(ice_cups == 2, "Genau zwei Zielbereiche liegen auf Eis")
	var alternatives: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/urban_winter_extra_routes.json"))
	for entry in alternatives:
		for golfer in GolferDefinition.IDS:
			var result := await LiveRouteRunner.play(host,catalog.get_hole(StringName(entry.id)),WorldRouteFixtures.route(entry,golfer),golfer)
			check.call(result.holed and result.within_limit, "%s %s: %s vollstaendig bis zum Ziel" % [entry.id,golfer,entry.purpose])
			if entry.purpose == "Hinderniskontakt": check.call(result.trace[0].contacts > 0, "Fehlversuch beruehrt das aktive Hindernis und kommt zum Stillstand")


static func _ice(rect: Rect2) -> SurfaceDefinition:
	var s := SurfaceDefinition.new()
	s.rect = rect
	s.surface_type = SurfaceZone.SurfaceType.ICE
	s.deceleration = SurfaceZone.ICE_DECELERATION
	return s


static func _physics(host: Node, check: Callable) -> void:
	var ball := PrototypeBall.new()
	host.add_child(ball)
	ball.set_physics_process(false)
	var zone := _ice(Rect2(2900,2900,5000,400)).instantiate_zone()
	host.add_child(zone)
	var distances: Array[float] = []
	for ground in [-1,SurfaceZone.SurfaceType.CONCRETE,SurfaceZone.SurfaceType.ICE]:
		var zones: Array[SurfaceZone] = []
		if ground == SurfaceZone.SurfaceType.ICE: zones.append(zone)
		ball.configure_environment(zones,Vector2(20000,20000),[],[],SurfaceZone.SurfaceType.CONCRETE if ground != -1 else -1)
		ball.reset_to(Vector2(3000,3000))
		ball.launch(Vector2.RIGHT,240,1)
		check.call(ball.velocity.is_equal_approx(Vector2(240,0)), "Belag %d behaelt dieselbe Startgeschwindigkeit" % ground)
		for tick in range(1600): ball._physics_process(1.0/60.0)
		distances.append(ball.position.x-3000)
		check.call(not ball.moving and ball.visible and ball.current_stroke_count == 1, "Belag %d kommt ohne Strafschlag oder Ruecksetzung zur Ruhe" % ground)
	# The fixed-step integrator adds roughly half a movement tick to each roll.
	check.call(absf(distances[2]/distances[1]-4.0) < 0.04 and absf(distances[2]/distances[0]-6.0) < 0.06, "Eis rollt rund viermal so weit wie Beton und sechsmal so weit wie Gruen (1 Prozent Integratortoleranz)")
	print("Rollweiten Gruen / Beton / Eis: ",distances)
	zone.free()
	zone = _ice(Rect2(3100,2900,32,400)).instantiate_zone()
	host.add_child(zone)
	ball.configure_environment([zone],Vector2(20000,20000),[],[],SurfaceZone.SurfaceType.CONCRETE)
	for speed in [100.0,520.0]:
		for angle in [0.0,25.0,-25.0]:
			var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
			ball.reset_to(Vector2(3090,3000))
			ball.launch(direction,speed,1)
			var seen_ice := false
			var returned := false
			var correct := true
			for tick in range(1600):
				var previous := ball.velocity.length()
				ball._physics_process(1.0/60.0)
				seen_ice = seen_ice or ball.current_surface_type == SurfaceZone.SurfaceType.ICE
				returned = returned or (seen_ice and ball.current_surface_type == SurfaceZone.SurfaceType.CONCRETE)
				if ball.moving and ball.velocity.length() > 3:
					correct = correct and ball.velocity.length() <= previous + 0.001 and ball.velocity.normalized().dot(direction) > 0.99999
				if not ball.moving: break
			check.call(seen_ice and returned and correct and not ball.moving, "Beton-Eis-Beton bei %.0f px/s und %.0f Grad: keine Spruenge, Richtungsfehler oder uebersprungene Eiszone" % [speed,angle])
	var invalid := _ice(Rect2(0,0,32,32))
	invalid.acceleration = Vector2.RIGHT
	check.call(not invalid.validate("Eis").is_empty(), "Eisvalidator verhindert versteckte Zusatzbeschleunigung")
	invalid.acceleration = Vector2.ZERO
	invalid.deceleration = 0
	check.call(not invalid.validate("Eis").is_empty(), "Eisvalidator verhindert reibungslose Dauergleitflaechen")
	zone.free()
	ball.free()


static func _short_putts(host: Node, check: Callable, original: HoleDefinition) -> void:
	for golfer in GolferDefinition.IDS:
		for distance in [8.0,16.0,32.0,64.0,100.0]:
			var h := original.duplicate(true) as HoleDefinition
			h.tee_position = h.hole_position-Vector2(distance,0)
			var route: Array[RouteShot] = [RouteShot.new(h.hole_position,maxf(ShotController.MINIMUM_BALL_SPEED,sqrt(distance*40+20*20)))]
			var result := await LiveRouteRunner.play(host,h,route,golfer)
			check.call(result.holed and result.strokes == 1, "%s: erneutes Abschlagen auf Eis und Korrekturputt aus %.0f px" % [golfer,distance])


static func _lifecycle(host: Node, check: Callable, h: HoleDefinition) -> void:
	var game := (load("res://scenes/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	game.configure_attempt(h,PlayerProfile.create(1,"EISTEST",0),true,1,9,0,true)
	host.add_child(game)
	await host.get_tree().physics_frame
	game.ball.reset_to(Vector2(360,184))
	game.ball.launch(Vector2.RIGHT,80,1)
	game.set_external_paused(true)
	host.get_tree().paused = true
	var p := game.ball.position
	var velocity := game.ball.velocity
	for tick in range(15): await host.get_tree().physics_frame
	check.call(game.ball.position == p and game.ball.velocity == velocity, "Pause friert das Gleiten auf Eis ein")
	host.get_tree().paused = false
	game.set_external_paused(false)
	game.restart_hole()
	for tick in range(4): await host.get_tree().physics_frame
	check.call(game.ball.position == h.tee_position and not game.ball.moving and game.ball.current_surface_type == SurfaceZone.SurfaceType.CONCRETE, "Neustart verwirft Eisbewegung und setzt auf Beton zurueck")
	game.ball.reset_to(Vector2(360,184))
	game.ball.launch(Vector2.RIGHT,80,1)
	game.switch_test_hole()
	check.call(not game.ball.moving and game.ball.position == game.hole.get_tee_position(), "Bahnwechsel verwirft das Gleiten")
	game.queue_free()
	await host.get_tree().process_frame
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	host.add_child(app)
	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.FREE_PLAY
	config.hole_ids = [h.hole_id]
	config.players = [PlayerProfile.create(1,"EINS",0),PlayerProfile.create(2,"ZWEI",1)]
	app._start_round(config)
	var old_ball := app.gameplay.ball
	old_ball.reset_to(Vector2(360,184))
	old_ball.launch(Vector2.RIGHT,80,1)
	app._on_attempt_finished(1,false)
	await host.get_tree().process_frame
	app._start_current_attempt()
	await host.get_tree().physics_frame
	check.call(not is_instance_valid(old_ball) and app.session.current_player_index == 1 and app.gameplay.ball.position == h.tee_position and not app.gameplay.ball.moving and not app.gameplay.input_enabled, "Spielerwechsel verwirft alte Eisbewegung und sperrt gehaltene Eingaben")
	app.queue_free()
	await host.get_tree().process_frame


static func _obstacles(host: Node, check: Callable, catalog: HoleCatalog) -> void:
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/urban_winter_routes.json"))
	for number in [4,5,8,9]:
		var h := catalog.get_hole(StringName("urban_winter_%02d" % number))
		for obstacle in h.obstacles:
			if obstacle.obstacle_type != ObstacleDefinition.ObstacleType.SLIDING_GATE: continue
			var closed := Rect2(obstacle.position-obstacle.gate_size*0.5,obstacle.gate_size)
			check.call(_separates(h,closed), "%s: geschlossenes Tor sperrt den Spielweg vollstaendig" % h.hole_id)
			var runtime := obstacle.instantiate_obstacle() as TimedSlidingGate
			host.add_child(runtime)
			runtime.set_physics_process(false)
			for phase in [0.0,3.25,4.0,7.75]:
				runtime.reset_motion()
				runtime.advance_motion(phase)
				var fraction := TimedSlidingGate.openness_at_time(phase,8,0.5,4)
				check.call(runtime.position.is_equal_approx(obstacle.position+obstacle.open_offset*fraction), "%s: Torphase %.2f besitzt passende physische Stellung" % [h.hole_id,phase])
				if fraction == 1.0:
					var open_rect := Rect2(runtime.position-obstacle.gate_size*0.5,obstacle.gate_size).grow(PrototypeBall.RADIUS)
					check.call(not _separates(h,open_rect), "%s: offenes Tor gibt den Weg einschliesslich Ballradius frei" % h.hole_id)
			runtime.free()
		# The real world remains active: mistimed shots must settle, even after kicks.
		for wait in [0,90,195,300,465]:
			var route := WorldRouteFixtures.route(entries[number-1])
			var index := 2 if number == 8 else (1 if number == 9 else 0)
			route.resize(index+1)
			route[index].wait_ticks = wait
			var result := await LiveRouteRunner.play(host,h,route)
			check.call(result.holed or result.reason == "Schlagfolge beendet, Loch nicht erreicht", "%s: Fehlzeit %d fuehrt zu Stillstand statt Dauerkontakt" % [h.hole_id,wait])
			check.call(_clear_point(h,Vector2(result.position[0],result.position[1])), "%s: nach Fehlzeit %d bleibt der Ball in freier Bahngeometrie" % [h.hole_id,wait])


static func _clear_point(h: HoleDefinition, p: Vector2) -> bool:
	if not h.lane_outline.contains_point(p): return false
	for piece in h.get_normalized_wall_network():
		for segment in piece["segments"]:
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1])) < PrototypeBall.RADIUS + WallTileDefinition.THICKNESS*0.5 - 0.1: return false
	return true


static func _separates(h: HoleDefinition, r: Rect2) -> bool:
	var corners := PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
	for piece in Geometry2D.clip_polygons(h.lane_outline.get_floor_points(),corners):
		if Geometry2D.is_point_in_polygon(h.tee_position,piece) and Geometry2D.is_point_in_polygon(h.hole_position,piece): return false
	return true


static func _ice_is_required(h: HoleDefinition) -> bool:
	var pieces: Array[PackedVector2Array] = [h.lane_outline.get_floor_points()]
	for s in h.surfaces:
		var remaining: Array[PackedVector2Array] = []
		for piece in pieces: remaining.append_array(Geometry2D.clip_polygons(piece,s.get_rotated_corners()))
		pieces = remaining
	for piece in pieces:
		if Geometry2D.is_point_in_polygon(h.tee_position,piece) and Geometry2D.is_point_in_polygon(h.hole_position,piece): return false
	return true
