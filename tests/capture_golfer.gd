extends Node


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/golfer")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384, 656)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(viewport)
	var background := ColorRect.new()
	background.size = Vector2(viewport.size)
	background.color = Color("#172332")
	viewport.add_child(background)
	var names := ["ANSPRECHEN", "BLINZELN", "ATMEN", "BEOBACHTEN", "KURZ", "MITTEL", "WEIT", "KONZENTRATION", "KONTAKT", "AUS KURZ", "AUS MITTEL", "AUS WEIT", "JUBEL 1", "JUBEL 2", "AERGER 1", "AERGER 2"]
	for frame in range(16):
		var golfer := PlaceholderGolfer.new()
		golfer.position = Vector2((frame % 4) * 96 + 4, (frame / 4) * 164)
		golfer.size = golfer.FRAME_SIZE
		viewport.add_child(golfer)
		golfer.set_process(false)
		golfer.set_shot_state(ShotController.ShotState.HOLE_COMPLETE)
		golfer._sprite.frame = frame
		var label := Label.new()
		label.position = golfer.position + Vector2(0, 145)
		label.text = names[frame]
		label.add_theme_font_size_override("font_size", 8)
		viewport.add_child(label)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png("res://.godot/golfer/poses.png")
	if error != OK:
		get_tree().quit(1)
		return
	viewport.queue_free()
	await get_tree().process_frame
	var colors := SubViewport.new()
	colors.size = Vector2i(384, 164)
	colors.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(colors)
	var colors_background := ColorRect.new()
	colors_background.size = Vector2(colors.size)
	colors_background.color = Color("#172332")
	colors.add_child(colors_background)
	for palette in range(4):
		var golfer := PlaceholderGolfer.new()
		golfer.position = Vector2(palette * 96 + 4, 0)
		golfer.size = golfer.FRAME_SIZE
		colors.add_child(golfer)
		golfer.set_process(false)
		golfer.set_palette(palette)
		var label := Label.new()
		label.position = golfer.position + Vector2(0, 145)
		label.text = PlayerProfile.PALETTE_NAMES[palette]
		label.add_theme_font_size_override("font_size", 8)
		colors.add_child(label)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	error = colors.get_texture().get_image().save_png("res://.godot/golfer/colors.png")
	if error == OK:
		error = await _capture_sequence()
	print("Golferaufnahmen: ", error_string(error))
	get_tree().quit(0 if error == OK else 1)


func _capture_sequence() -> Error:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 492)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(viewport)
	var background := ColorRect.new()
	background.size = Vector2(viewport.size)
	background.color = Color("#172332")
	viewport.add_child(background)
	var names := ["ZIELEN", "KRAFT", "GENAUIGKEIT", "HALTEN", "ABSCHWUNG", "KONTAKT", "DURCHSCHWUNG", "BEOBACHTEN", "JUBEL", "AERGER"]
	for row in range(3):
		for column in range(10):
			var golfer := PlaceholderGolfer.new()
			golfer.position = Vector2(column * 96 + 4, row * 164)
			golfer.size = golfer.FRAME_SIZE
			viewport.add_child(golfer)
			golfer.set_process(false)
			golfer.set_shot_state(ShotController.ShotState.POWER)
			golfer.set_power(float(row) * 0.5)
			match column:
				0:
					golfer.set_shot_state(ShotController.ShotState.AIMING)
				2:
					golfer.set_shot_state(ShotController.ShotState.ACCURACY)
					golfer.advance_animation(12.0)
				3:
					golfer.set_shot_state(ShotController.ShotState.ARMED)
					golfer.advance_animation(12.0)
				4:
					golfer.set_shot_state(ShotController.ShotState.SWINGING)
					golfer.set_swing_progress(0.5)
				5, 6:
					golfer.play_reaction("perfect_swing")
					golfer.notify_ball_contact()
					if column == 6:
						golfer.advance_animation(0.12)
				7:
					golfer.set_shot_state(ShotController.ShotState.BALL_MOVING)
				8:
					golfer.play_reaction("success")
					golfer.advance_animation(0.2)
				9:
					golfer.play_reaction("frustration")
					golfer.advance_animation(0.4)
			var label := Label.new()
			label.position = golfer.position + Vector2(0, 145)
			label.text = names[column]
			label.add_theme_font_size_override("font_size", 8)
			viewport.add_child(label)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image().save_png("res://.godot/golfer/sequences.png")
