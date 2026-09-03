extends Node


func _ready() -> void:
	await get_tree().process_frame
	var main := get_parent().get_node("PrototypeMain") as PrototypeMain
	for _index in range(3):
		main.switch_test_hole()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var start_result := get_viewport().get_texture().get_image().save_png("res://.godot/cannon-workshop-start.png")

	var trigger := main.hole.trigger_nodes[0]
	trigger.activate()
	await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var active_result := get_viewport().get_texture().get_image().save_png("res://.godot/cannon-workshop-active.png")

	var safe := main.hole.cannon_nodes[0]
	main.ball.set_physics_process(false)
	main.ball.position = safe.position - safe.entry_direction * 4.0
	main.ball.velocity = safe.entry_direction * 100.0
	main.ball.moving = true
	safe._on_body_entered(main.ball)
	main.ball.advance_cannon_sequence(0.60)
	main.course_camera.set_follow_motion(main.ball.position, Vector2.RIGHT * 300.0)
	main.course_camera.snap_to_target()
	await RenderingServer.frame_post_draw
	var flight_result := get_viewport().get_texture().get_image().save_png("res://.godot/cannon-workshop-flight.png")

	main.ball.advance_cannon_sequence(1.0)
	main.course_camera.set_focus_position(main.hole.get_hole_position())
	main.course_camera.snap_to_target()
	await RenderingServer.frame_post_draw
	var end_result := get_viewport().get_texture().get_image().save_png("res://.godot/cannon-workshop-end.png")
	var result := start_result
	if result == OK:
		result = active_result
	if result == OK:
		result = flight_result
	if result == OK:
		result = end_result
	print("Cannon workshop screenshots: ", error_string(result))
	get_tree().quit(0 if result == OK else 1)
