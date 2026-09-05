extends Node


func _ready() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	var catalog := HoleCatalog.load_default()
	var ids := [
		&"reference_gate_lane",
		&"reference_gate_bumpers",
		&"reference_gate_rotor",
		&"reference_gate_slider",
		&"reference_gate_seesaw",
		&"reference_gate_hill",
		&"reference_angle_lane",
		&"reference_mos_lane",
		&"reference_gate_hill_hole",
		&"labyrinth_nine_01",
		&"labyrinth_nine_02",
		&"labyrinth_nine_03",
		&"labyrinth_nine_04",
		&"labyrinth_nine_05",
		&"labyrinth_nine_06",
		&"labyrinth_nine_07",
		&"labyrinth_nine_08",
		&"labyrinth_nine_09",
	]
	for hole_id in ids:
		var definition := catalog.get_hole(hole_id)
		var main := PrototypeMain.new()
		main.configure_attempt(definition, PlayerProfile.create(1, "SPIELER 1", 0), true, 1, 1, 0, false)
		add_child(main)
		await get_tree().process_frame
		if String(hole_id).begins_with("labyrinth_nine_"):
			main.course_camera.set_physics_process(false)
			main.course_camera.position = Vector2(656, 180)
			main.course_camera.zoom = Vector2(0.62, 0.62)
		await RenderingServer.frame_post_draw
		var path := "res://.godot/%s.png" % hole_id
		var result := get_viewport().get_texture().get_image().save_png(path)
		print("Capture %s: %s" % [hole_id, error_string(result)])
		remove_child(main)
		main.queue_free()
		await get_tree().process_frame
	get_tree().quit()
