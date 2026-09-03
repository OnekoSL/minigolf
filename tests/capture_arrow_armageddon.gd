extends Node


func _ready() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	var catalog := HoleCatalog.load_default()
	for index in range(9):
		var hole_id := StringName("arrow_armageddon_%02d" % (index + 1))
		var definition := catalog.get_hole(hole_id)
		var main := PrototypeMain.new()
		main.configure_attempt(definition, PlayerProfile.create(1, "SPIELER 1", 0), true, index + 1, 9, 0, false)
		add_child(main)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "res://.godot/arrow-armageddon-%02d.png" % (index + 1)
		var result := get_viewport().get_texture().get_image().save_png(path)
		print("Capture %s: %s" % [hole_id, error_string(result)])
		if index >= 5:
			main.course_camera.set_process(false)
			main.course_camera.global_position = definition.camera_center_bounds.end
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var end_path := "res://.godot/arrow-armageddon-%02d-end.png" % (index + 1)
			var end_result := get_viewport().get_texture().get_image().save_png(end_path)
			print("Capture %s end: %s" % [hole_id, error_string(end_result)])
		remove_child(main)
		main.queue_free()
		await get_tree().process_frame
	get_tree().quit()
