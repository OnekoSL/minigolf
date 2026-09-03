extends Node


func _ready() -> void:
	await get_tree().process_frame
	var app := get_parent().get_node("GameApp") as GameApp
	var result := await _capture("res://.godot/shell-title.png")
	app._show_mode()
	await get_tree().process_frame
	result = await _capture("res://.godot/shell-modes.png") if result == OK else result
	app.selected_mode = RoundConfig.GameMode.COURSE_LOCAL
	app.desired_player_count = 2
	app.setup_player_index = 0
	app.setup_name = "SPIELER 1"
	app._show_player_name()
	await get_tree().process_frame
	result = await _capture("res://.godot/shell-name.png") if result == OK else result

	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.COURSE_LOCAL
	config.course_id = &"prototype_course_03"
	config.players = [PlayerProfile.create(1, "ANNA", 0), PlayerProfile.create(2, "BERT", 1)]
	config.hole_ids = [&"reference_01", &"classic_diamond_02", &"double_gate_03"]
	config.best_eligible = true
	app.session = RoundSession.new()
	app.session.configure(config, app.hole_catalog)
	app.session.scores[0] = [4, 3, 4]
	app.session.scores[1] = [3, 4, 4]
	app._show_scorecard(true, false)
	await get_tree().process_frame
	result = await _capture("res://.godot/shell-table.png") if result == OK else result
	print("Shell screenshots: ", error_string(result))
	get_tree().quit(0 if result == OK else 1)


func _capture(path: String) -> Error:
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image().save_png(path)
