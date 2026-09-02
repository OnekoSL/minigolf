extends Node


func _ready() -> void:
	await get_tree().process_frame
	var main = get_parent().get_node("PrototypeMain")
	main.switch_test_hole()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var diamond_result := get_viewport().get_texture().get_image().save_png("res://.godot/diamond-hole.png")
	main.switch_test_hole()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var gate_start_result := get_viewport().get_texture().get_image().save_png("res://.godot/double-gate-start.png")
	for obstacle in main.hole.obstacle_nodes:
		obstacle.set_physics_process(false)
		obstacle.reset_motion()
		obstacle.advance_motion(1.60)
	await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var gate_open_result := get_viewport().get_texture().get_image().save_png("res://.godot/double-gate-open.png")
	main.course_camera.set_focus_position(main.hole.get_hole_position())
	main.course_camera.snap_to_target()
	await RenderingServer.frame_post_draw
	var gate_end_result := get_viewport().get_texture().get_image().save_png("res://.godot/double-gate-end.png")
	var result := diamond_result if diamond_result != OK else gate_start_result
	if result == OK:
		result = gate_open_result
	if result == OK:
		result = gate_end_result
	print("New hole screenshots: ", error_string(result))
	get_tree().quit(0 if result == OK else 1)
