extends Node

const OUTPUT := "res://.godot/practice"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var app := GameApp.new()
	add_child(app)
	app._select_mode(RoundConfig.GameMode.PRACTICE)
	var practice := app.practice
	practice.progress.storage_path = "user://capture-practice.cfg"
	practice.progress.read()
	var original_locale := TranslationServer.get_locale()
	for language in GameSettings.LANGUAGES:
		TranslationServer.set_locale(language)
		practice.show_hub()
		await _save(language, "hub")
		practice.show_lessons()
		await _save(language, "lessons")
		practice.show_sections(4)
		await _save(language, "sections")
		practice.show_categories()
		await _save(language, "courses")
		practice.category_index = 0
		practice.hole_index = 0
		practice.show_holes()
		await _save(language, "holes")
		practice.category_index = app.course_catalog.courses.size()
		practice.hole_index = 12
		practice.show_holes()
		await _save(language, "labs")
		practice.start_lesson(1)
		await _save(language, "intro")
		practice.resume()
		for tick in range(20): await get_tree().process_frame
		practice.game.shot_controller.action_pressed()
		practice.game.shot_controller.power_value = 0.5
		practice.game.shot_controller.set_process(false)
		await _save(language, "power")
		practice.game.shot_controller.action_pressed()
		await _save(language, "accuracy")
		practice.show_tools()
		await _save(language, "tools")
		for lesson in [2, 4, 5, 7]:
			practice.start_lesson(lesson, false, 2 if lesson in [4, 5] else 0)
			practice.resume()
			for tick in range(20): await get_tree().process_frame
			await _save(language, "lesson-%d" % lesson)
		practice.show_result(true)
		await _save(language, "lesson-result")
		practice.category_index = 0
		practice.start_free(0)
		practice.show_golfers()
		await _save(language, "golfers")
		practice.show_don()
		await _save(language, "don")
		practice.resume()
		for tick in range(20): await get_tree().process_frame
		var shot := practice.game.shot_controller
		shot.action_pressed()
		shot.power_value = 0.32
		shot.action_pressed()
		shot.accuracy_value = 0
		shot.action_pressed()
		shot.action_released()
		for tick in range(110): await get_tree().physics_frame
		practice.show_tools()
		await practice.retry()
		for tick in range(20): await get_tree().process_frame
		shot.cursor_position = practice.game.ball.position + Vector2(100, -20)
		shot.action_pressed()
		shot.power_value = 0.58
		shot.action_pressed()
		shot.accuracy_value = 0
		shot.action_pressed()
		shot.action_released()
		for tick in range(45): await get_tree().physics_frame
		await _save(language, "comparison")
		practice.show_result(true)
		await _save(language, "result")
	TranslationServer.set_locale(original_locale)
	practice.close()
	app.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _save(language: String, name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var app := get_child(0) as GameApp
	if app.practice.overlay != null:
		var overlay := app.practice.overlay
		if overlay.hint.get_minimum_size().y > 52 or overlay.menu_button.size.x > 152.1:
			push_error("Practice sidebar overflow: %s/%s" % [language, name])
			get_tree().quit(1)
			return
	var error := get_viewport().get_texture().get_image().save_png("%s/%s-%s.png" % [OUTPUT, language, name])
	if error != OK:
		push_error("Capture failed: " + name)
		get_tree().quit(1)
