extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Muehlental: freie Drehkreise und aktive Durchfahrten]")
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	for entry in entries:
		if entry.id not in ["muehlental_01","muehlental_08","muehlental_09"]:
			continue
		var hole := HoleCatalog.load_default().get_hole(StringName(entry.id))
		var rotors: Array[ObstacleDefinition] = []
		for obstacle in hole.obstacles:
			if obstacle.obstacle_type == ObstacleDefinition.ObstacleType.ROTATING_BLADE:
				rotors.append(obstacle)
		for rotor in rotors:
			var radius := rotor.blade_size.length()*0.5
			var wake_radius := (rotor.blade_size+Vector2(10,10)).length()*0.5
			var passage := Rect2(190,142,hole.course_rect.end.x-220,68)
			check.call(passage.encloses(Rect2(rotor.position-Vector2.ONE*radius,Vector2.ONE*radius*2)),
				"%s: gesamter Drehkreis bei %s mit Abstand innerhalb der Banden" % [entry.id,rotor.position])
			check.call(hole.tee_position.distance_to(rotor.position)>wake_radius+PrototypeBall.RADIUS+8 and hole.hole_position.distance_to(rotor.position)>wake_radius+PrototypeBall.RADIUS+8,
				"%s: Abschlag und Loch ausserhalb des Dreh- und Weckbereichs" % entry.id)
		if entry.id == "muehlental_01":
			check.call(rotors.size()==2 and rotors[0].position.y>hole.tee_position.y and rotors[1].position.y<hole.tee_position.y,
				"Erste Muehle: zwei gegenueberliegend versetzte Rotoren")
			check.call(rotors.all(func(r): return r.position.distance_to(Vector2(408,176))>(r.blade_size+Vector2(10,10)).length()*0.5+PrototypeBall.RADIUS+8),
				"Erste Muehle: Zwischenablage bleibt ausserhalb beider Dreh- und Weckbereiche")
		var runtime := HoleRuntime.new()
		runtime.configure(hole)
		host.add_child(runtime)
		var ball := PrototypeBall.new()
		ball.position = hole.tee_position
		host.add_child(ball)
		ball.configure_environment(runtime.zones,hole.hole_position,runtime.get_tunnels())
		var displaced := false
		var observation_ticks := ceili(rotors.map(func(r): return r.seconds_per_revolution).max()*120)+4
		for tick in range(observation_ticks):
			await host.get_tree().physics_frame
			displaced = displaced or ball.moving or ball.position.distance_to(hole.tee_position)>0.01
		check.call(not displaced,"%s: Ball wartet zwei volle Umdrehungen ungestoert am Abschlag" % entry.id)
		if entry.id == "muehlental_01":
			ball.reset_to(Vector2(408,176))
			displaced = false
			for tick in range(observation_ticks):
				await host.get_tree().physics_frame
				displaced = displaced or ball.moving or ball.position.distance_to(Vector2(408,176))>0.01
			check.call(not displaced,"Erste Muehle: Zwischenablage bleibt zwei Umdrehungen ruhig")
		ball.queue_free()
		runtime.queue_free()
		await host.get_tree().process_frame
		var cases := [[&"allrounder",0.0,1.0,0],[&"mara",0.0,1.0,0],[&"bruno",0.0,1.0,0],[&"nika",0.0,1.0,0],
			[&"allrounder",-0.3,1.0,0],[&"allrounder",0.3,1.0,0],[&"allrounder",0.0,0.99,0],[&"allrounder",0.0,1.01,0],
			[&"allrounder",0.0,1.0,-5],[&"allrounder",0.0,1.0,5]]
		for test_case in cases:
			var route := WorldRouteFixtures.route(entry,test_case[0],test_case[1],test_case[2])
			var timing_shot := 1 if entry.id == "muehlental_08" else 0
			route[timing_shot].wait_ticks += test_case[3]
			var result := await LiveRouteRunner.play(host,hole,route,test_case[0])
			check.call(result.within_par and result.contact_delays.all(func(t): return t==6),
				"%s: PAR %d, %s, Winkel %+.1f, Kraft %.2f, Warteabweichung %d" % [entry.id,hole.par,test_case[0],test_case[1],test_case[2],test_case[3]])
			if not result.within_par: print("  ROUTENLUECKE ",JSON.stringify(result))
		if entry.id == "muehlental_01":
			for extra_wait in [-5,5,480]:
				var route := WorldRouteFixtures.route(entry)
				route[1].wait_ticks += extra_wait
				var result := await LiveRouteRunner.play(host,hole,route)
				check.call(result.within_par,"Erste Muehle: zweites Rotorfenster mit %d Ticks Warteabweichung" % extra_wait)
