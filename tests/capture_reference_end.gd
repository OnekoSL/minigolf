extends Node


func _ready() -> void:
	await get_tree().process_frame
	var main := get_parent().get_node("PrototypeMain")
	main.shot_controller.cursor_position = main.hole.get_hole_position()
	main.shot_controller.queue_redraw()
	main.course_camera.set_focus_position(main.shot_controller.cursor_position)
	main.course_camera.snap_to_target()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png("res://.godot/prototype-reference-end.png")
	print("Reference end screenshot: ", error_string(result))
	get_tree().quit(0 if result == OK else 1)
