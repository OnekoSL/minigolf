extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Elefant: Aufnahme vor Einklemmen an der Bande]")
	var definition := HoleCatalog.load_default().get_hole(&"zirkus_05")
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	host.add_child(runtime)
	var elephant := runtime.obstacle_nodes[0] as ElephantObstacle
	var ball := PrototypeBall.new()
	host.add_child(ball)
	ball.configure_environment(runtime.zones,definition.hole_position,runtime.get_tunnels(),runtime.obstacle_nodes)
	# The original bug pushed a parked ball from (400,300) to y=1003 and
	# the rear case from (400,36) to y=-279. Check every physics tick.
	for x in [388.0,400.0,412.0]:
		for speed in [0.0,100.0,420.0,520.0]:
			ball.reset_to(definition.tee_position)
			elephant.reset_motion()
			elephant.advance_motion(0.5)
			ball.reset_to(Vector2(x,300))
			ball.current_stroke_count = 1
			if speed > 0.0:
				ball.launch(Vector2.RIGHT,speed,1)
			var captured := false
			var escaped := false
			for tick in range(300):
				await host.get_tree().physics_frame
				captured = captured or ball.is_tunnel_sequence_active()
				if not ball.is_tunnel_sequence_active():
					escaped = escaped or not definition.lane_outline.contains_point(ball.position)
			check.call(captured and not escaped, "Ruesselspalt x=%.0f, Tempo %.0f: Aufnahme und kein Verlassen der Bahn" % [x,speed])
	for y in [31.0,36.0,44.0]:
		ball.reset_to(definition.tee_position)
		elephant.reset_motion()
		ball.reset_to(Vector2(400,y))
		ball.current_stroke_count = 1
		var escaped := false
		for tick in range(720):
			await host.get_tree().physics_frame
			escaped = escaped or not definition.lane_outline.contains_point(ball.position)
		check.call(not escaped and ball.position.is_equal_approx(Vector2(400,y)), "Schwanz haelt vor ruhendem Ball an der oberen Bande bei y=%.0f" % y)
	# Sideways approaches to the closing tail must not be depenetrated through
	# the wall, even at the largest impulse speed supported by the ball.
	for phase in [0.0,1.0,2.0,3.0,4.0,5.0]:
		for direction in [Vector2.LEFT,Vector2.RIGHT]:
			ball.reset_to(definition.tee_position)
			elephant.reset_motion()
			elephant.advance_motion(maxf(0.001,phase))
			ball.reset_to(Vector2(400 - direction.x * 40,33))
			ball.launch(direction,520,1)
			var escaped := false
			for tick in range(120):
				await host.get_tree().physics_frame
				escaped = escaped or not definition.lane_outline.contains_point(ball.position)
			check.call(not escaped, "Schwanz: schneller seitlicher Kontakt bleibt bei Phase %.0f innerhalb der Bahn" % phase)
	# A fully lifted trunk still permits the long route for a rolling ball.
	ball.reset_to(definition.tee_position)
	elephant.reset_motion()
	elephant.advance_motion(4.0)
	ball.reset_to(Vector2(370,280))
	ball.launch(Vector2.RIGHT,200,1)
	var entered := false
	for tick in range(22):
		await host.get_tree().physics_frame
		entered = entered or ball.is_tunnel_sequence_active()
	check.call(not entered and ball.position.x > 420, "Vollstaendig gehobener Ruessel laesst die normale Durchfahrt offen")
	# No gate callback may impart an impulse to a ball already in transport.
	ball.reset_to(definition.tee_position)
	elephant.reset_motion()
	ball.reset_to(Vector2(400,300))
	ball.current_stroke_count = 1
	ball._finish_stopped()
	var accepted := ball.apply_moving_obstacle_contact(Vector2(0,100),Vector2.DOWN,1.0,55.0,&"gate")
	check.call(not accepted and ball.velocity == Vector2.ZERO and ball.is_tunnel_sequence_active(), "Aufgenommener Ball ist gegen nachlaufende Hindernisimpulse gesperrt")
	ball.queue_free()
	runtime.queue_free()
	await host.get_tree().process_frame
