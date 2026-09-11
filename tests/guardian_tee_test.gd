extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Waechterkammer: sicherer Abschlag bei aktivem Rotor]")
	var hole := HoleCatalog.load_default().get_hole(&"tempelruinen_08")
	var rotor := hole.obstacles[0]
	var sweep_radius := rotor.blade_size.length() * 0.5
	var wake_radius := (rotor.blade_size + Vector2(10,10)).length() * 0.5
	check.call(hole.tee_position.distance_to(rotor.position) > wake_radius + PrototypeBall.RADIUS + 8.0,
		"Abschlag bleibt mit Ballradius und Wartezone ausserhalb des gesamten Rotor- und Weckbereichs")
	var free_passage := Rect2(190,142,148,68)
	check.call(free_passage.encloses(Rect2(rotor.position-Vector2.ONE*sweep_radius,Vector2.ONE*sweep_radius*2.0)),
		"Rotor bleibt in jeder Drehstellung innerhalb der Passage mit Abstand zu den Banden")
	var runtime := HoleRuntime.new()
	runtime.configure(hole)
	host.add_child(runtime)
	var ball := PrototypeBall.new()
	ball.position = hole.tee_position
	host.add_child(ball)
	ball.configure_environment(runtime.zones,hole.hole_position,runtime.get_tunnels())
	for attempt in range(2):
		runtime.reset_mechanisms()
		ball.reset_to(hole.tee_position)
		var displaced := false
		for tick in range(ceili(rotor.seconds_per_revolution*60.0)*2+4):
			await host.get_tree().physics_frame
			displaced = displaced or ball.moving or ball.position.distance_to(hole.tee_position)>0.01
		check.call(not displaced,"Abschlag bleibt zwei volle Rotorumdrehungen ruhig, auch nach Neustart (%d)" % (attempt+1))
	ball.queue_free()
	runtime.queue_free()
	await host.get_tree().process_frame
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	for entry in entries:
		if entry.id != "tempelruinen_08":
			continue
		var cases := [[&"allrounder",0.0,1.0,0],[&"mara",0.0,1.0,0],[&"bruno",0.0,1.0,0],[&"nika",0.0,1.0,0],
			[&"allrounder",-0.3,1.0,0],[&"allrounder",0.3,1.0,0],[&"allrounder",0.0,0.99,0],[&"allrounder",0.0,1.01,0],
			[&"allrounder",0.0,1.0,-5],[&"allrounder",0.0,1.0,5],[&"allrounder",0.0,1.0,300]]
		for test_case in cases:
			var route := WorldRouteFixtures.route(entry,test_case[0],test_case[1],test_case[2])
			route[0].wait_ticks += test_case[3]
			var result := await LiveRouteRunner.play(host,hole,route,test_case[0])
			check.call(result.within_par and result.contact_delays.all(func(t): return t==6),
				"Waechterkammer PAR 2: %s, Winkel %+.1f, Kraft %.2f, Warteabweichung %d Ticks" % test_case)

