extends Node


func _ready() -> void:
	call_deferred("_capture_ui")


func _capture_ui() -> void:
	var app_scene := load("res://scenes/game_app.tscn") as PackedScene
	var app := app_scene.instantiate() as GameApp
	add_child(app)
	await get_tree().process_frame
	app._show_course_select()
	await _save("res://.godot/classic-nine-course-select.png")
	app.hole_select_page = 2
	app._show_hole_select()
	await _save("res://.godot/classic-nine-hole-page.png")

	var holes := HoleCatalog.load_default()
	var course := CourseCatalog.load_default().get_course(&"classic_nine_course")
	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.COURSE_LOCAL
	config.course_id = course.course_id
	config.players = [
		PlayerProfile.create(1, "TINA", 0),
		PlayerProfile.create(2, "MAX", 1),
		PlayerProfile.create(3, "KIM", 2),
		PlayerProfile.create(4, "JULE", 3),
	]
	config.hole_ids = course.hole_ids.duplicate()
	config.best_eligible = true
	app.session = RoundSession.new()
	app.session.configure(config, holes)
	for player_index in range(4):
		for hole_index in range(9):
			app.session.scores[player_index][hole_index] = [1, 1, 1, 2, 2, 2, 3, 3, 3][hole_index] + (1 if player_index == 3 and hole_index % 3 == 0 else 0)
	app._show_scorecard(true, false)
	await _save("res://.godot/classic-nine-scorecard.png")
	app.free()
	get_tree().quit()


func _save(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(path)
	print("Capture %s: %s" % [path, error_string(result)])
