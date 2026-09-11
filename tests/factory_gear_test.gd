extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Uhrwerkfabrik: Rotoren und verborgenes Tunnelzahnrad]")
	var catalog := HoleCatalog.load_default()
	var ids := ["uhrwerkfabrik_02","labyrinth_nine_06","labyrinth_nine_07","uhrwerkfabrik_08","labyrinth_nine_08"]
	for id in ids:
		var hole := catalog.get_hole(StringName(id))
		for obstacle in hole.obstacles:
			if obstacle.obstacle_type != ObstacleDefinition.ObstacleType.ROTATING_BLADE: continue
			var radius := obstacle.blade_size.length()*0.5
			check.call(obstacle.position.y-radius>142 and obstacle.position.y+radius<210,
				"%s: vollstaendiger Rotorumlauf bleibt zwischen den Banden" % id)
	var definition := catalog.get_hole(&"labyrinth_nine_08")
	check.call(definition.validate().is_empty() and definition.obstacles.size()==1 and definition.obstacles[0].obstacle_type==ObstacleDefinition.ObstacleType.TUNNEL_GEAR,
		"Uhrwerk-Finale: ein zentrales Tunnelzahnrad ersetzt die Rotorkette")
	var invalid := definition.obstacles[0].duplicate(true) as ObstacleDefinition
	invalid.gear_links[0] = 0
	check.call(not invalid.validate("Selbstverbindung").is_empty(),"Zahnrad lehnt Selbstverbindungen ab")
	invalid.gear_links = PackedInt32Array([1,2,0,7,6,4,5,3])
	check.call(not invalid.validate("Einbahnverbindung").is_empty(),"Zahnrad verlangt gegenseitige Lochpaare")
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	host.add_child(runtime)
	var gear := runtime.obstacle_nodes[0] as TunnelGear
	check.call(gear.links.size()==8 and Array(gear.links).all(func(partner): return partner>=0 and partner<8),"Alle acht gleich dargestellten Loecher haben feste Partner")
	var ball := PrototypeBall.new()
	ball.position = definition.tee_position
	host.add_child(ball)
	ball.configure_environment(runtime.zones,definition.hole_position,runtime.get_tunnels())
	var exits: Dictionary = {}
	for index in range(TunnelGear.PORT_COUNT):
		runtime.reset_mechanisms()
		gear.rotation = PI-index*TAU/TunnelGear.PORT_COUNT
		ball.reset_to(Vector2(316,176))
		await host.get_tree().physics_frame
		ball.launch(Vector2.RIGHT,120,1)
		for tick in range(60):
			await host.get_tree().physics_frame
			if ball.is_tunnel_sequence_active(): break
		var captured := ball.is_tunnel_sequence_active()
		check.call(captured,"Zahnradloch %d nimmt einen real rollenden Ball auf" % index)
		for tick in range(ceili((gear.seconds_per_revolution/4+PrototypeBall.TUNNEL_DURATION+1)*60)):
			if not ball.is_tunnel_sequence_active(): break
			await host.get_tree().physics_frame
		var direction := (ball.position-gear.position).normalized()
		var axis := direction.snapped(Vector2.ONE)
		exits[Vector2i(axis)] = true
		check.call(captured and not ball.is_tunnel_sequence_active() and ball.collision_mask==2 and ball.position.distance_to(gear.position)>TunnelGear.OUTER_RADIUS+PrototypeBall.RADIUS and definition.lane_outline.contains_point(ball.position) and direction.distance_to(axis)<0.01,
			"Zahnradloch %d gibt den Ball ausserhalb der Zaehne in einem freien Kreuzarm aus" % index)
	check.call(exits.size()==4,"Verborgene Paare erreichen vom Anspielarm aus alle vier Bereiche")
	runtime.reset_mechanisms()
	gear.rotation = PI
	ball.reset_to(Vector2(316,176))
	await host.get_tree().physics_frame
	ball.launch(Vector2.RIGHT,120,1)
	for tick in range(60):
		await host.get_tree().physics_frame
		if ball.is_tunnel_sequence_active(): break
	check.call(ball.is_tunnel_sequence_active(),"Neustartpruefung beginnt waehrend des Zahnradtransports")
	ball.reset_to(definition.tee_position)
	runtime.reset_mechanisms()
	check.call(not ball.is_tunnel_sequence_active() and ball.scale==Vector2.ONE and ball.collision_mask==2 and is_zero_approx(gear.rotation),"Neustart bricht Transport ab und setzt Ball und Zahnrad zurueck")
	var disturbed := false
	for tick in range(ceili(gear.seconds_per_revolution*120)+4):
		await host.get_tree().physics_frame
		disturbed = disturbed or ball.moving or ball.position.distance_to(definition.tee_position)>0.01
	check.call(not disturbed,"Zwei volle Zahnradumdrehungen lassen den Abschlag ungestoert")
	runtime.reset_mechanisms()
	ball.reset_to(Vector2(484,176))
	var woken := false
	for tick in range(120):
		await host.get_tree().physics_frame
		woken = woken or ball.moving
	check.call(woken,"Ein vorbeikommender Zahn setzt einen ruhenden Ball im Drehbereich in Bewegung")
	ball.queue_free()
	runtime.queue_free()
	await host.get_tree().process_frame
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	for entry in entries:
		if entry.id not in ids: continue
		var hole := catalog.get_hole(StringName(entry.id))
		var cases := [[&"allrounder",0.0,1.0],[&"mara",0.0,1.0],[&"bruno",0.0,1.0],[&"nika",0.0,1.0],
			[&"allrounder",-0.3,1.0],[&"allrounder",0.3,1.0],[&"allrounder",0.0,0.99],[&"allrounder",0.0,1.01]]
		for test_case in cases:
			var result := await LiveRouteRunner.play(host,hole,WorldRouteFixtures.route(entry,test_case[0],test_case[1],test_case[2]),test_case[0])
			check.call(result.within_par and result.contact_delays.all(func(t): return t==6),
				"%s: PAR-Route %s, Winkel %+.1f, Kraft %.2f" % [entry.id,test_case[0],test_case[1],test_case[2]])
			if not result.within_par: print("ROUTENLUECKE ",JSON.stringify(result))
		for extra_wait in [-5,5]:
			var route := WorldRouteFixtures.route(entry)
			var shot_index := 2 if entry.id == "labyrinth_nine_06" else 0
			route[shot_index].wait_ticks += extra_wait
			var result := await LiveRouteRunner.play(host,hole,route)
			check.call(result.within_par,"%s: Anspielfenster vertraegt %d Ticks Abweichung" % [entry.id,extra_wait])
