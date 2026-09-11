extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Klassik-Routen mit Spielreserve]")
	var routes := {
		&"classic_nine_03": [[-36.0, 250.0], [Vector2(575, 74), 180.0]],
		&"classic_nine_06": [[-24.0, 280.0], [Vector2(575, 72), 115.0]],
	}
	for hole_id in routes:
		for angle in [-0.25, 0.0, 0.25]:
			for speed in [-4.0, 0.0, 4.0]:
				var shots: Array = routes[hole_id].duplicate(true)
				shots[0][0] += angle
				shots[0][1] += speed
				check.call(await _play(host, hole_id, shots), "%s: PAR-Route vertraegt Winkel %+.2f und Kraft %+.0f" % [hole_id, angle, speed])
	for aim_x in [956, 960, 964]:
		for speed in [216.0, 220.0, 224.0]:
			var route := [[Vector2(600, 280), 300.0], [Vector2(1000, 280), 300.0], [Vector2(aim_x, 72), speed], [Vector2(220, 56), 420.0]]
			check.call(await _play(host, &"classic_nine_09", route), "Heimkehr: Wendeschlag X%d mit Kraft %.0f beendet die PAR-Route" % [aim_x, speed])
	# The last putt is aimed and powered from the actual resting position,
	# as a player would do after a slightly different first or second shot.
	var deviations := [
		Vector4(-0.5, 0, 0, 0), Vector4(-0.25, 0, 0, 0), Vector4(0.25, 0, 0, 0), Vector4(0.5, 0, 0, 0),
		Vector4(0, -8, 0, 0), Vector4(0, -4, 0, 0),
		Vector4(0, 0, -0.5, 0), Vector4(0, 0, -0.25, 0), Vector4(0, 0, 0.25, 0), Vector4(0, 0, 0.5, 0),
		Vector4(0, 0, 0, -8), Vector4(0, 0, 0, -4), Vector4(0, 0, 0, 4), Vector4(0, 0, 0, 8),
	]
	for deviation in deviations:
		var shots := [[-24.0 + deviation.x, 420.0 + deviation.y], [-28.5 + deviation.z, 340.0 + deviation.w], [Vector2(960, 72), 0.0]]
		check.call(await _play(host, &"classic_nine_08", shots, true), "Kreisallee: Abweichung %s erlaubt den Abschluss in drei Schlaegen" % deviation)


static func _play(host: Node, hole_id: StringName, shots: Array, adjust_last_putt := false) -> bool:
	var definition := LegacyCourseFixtures.holes().get_hole(hole_id)
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	host.get_tree().root.add_child(runtime)
	await host.get_tree().physics_frame
	var ball := PrototypeBall.new()
	host.get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = definition.tee_position
	ball.configure_environment(runtime.zones, definition.hole_position)
	var result := {"holed": false}
	ball.holed.connect(func(_strokes): result["holed"] = true)
	var legal := shots.size() <= definition.par
	for index in range(shots.size()):
		var aim = shots[index][0]
		var speed: float = shots[index][1]
		if adjust_last_putt and index == shots.size() - 1:
			speed = maxf(78.0, sqrt(240.0 * ball.position.distance_to(definition.hole_position)) + 10.0)
		legal = legal and speed >= 78 and speed <= 420
		var direction: Vector2 = ball.position.direction_to(aim) if aim is Vector2 else Vector2.from_angle(deg_to_rad(aim))
		ball.launch(direction, speed, index + 1)
		for _step in range(1800):
			ball._physics_process(1.0 / 60.0)
			legal = legal and definition.lane_outline.contains_point(ball.position)
			if not ball.moving:
				break
		if ball.position.distance_to(definition.hole_position) < 0.001:
			await host.get_tree().create_timer(0.4).timeout
			break
	ball.free()
	runtime.free()
	if not legal or not result["holed"]:
		print("  Margin route ", hole_id, " legal=", legal, " holed=", result["holed"], " shots=", shots)
	return legal and result["holed"]
