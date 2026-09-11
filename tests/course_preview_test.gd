extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Kursvorschau: neun Bahnen vor der Auswahl]")
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	host.add_child(app)
	await host.get_tree().process_frame
	app.set_process(false)
	app.working_players = [PlayerProfile.create(1,"VORSCHAU",0)]
	for index in range(app.course_catalog.courses.size()):
		app.course_select_page = index/app.COURSES_PER_PAGE
		app._show_course_select()
		app._select_option(index%app.COURSES_PER_PAGE)
		await host.get_tree().process_frame
		var course := app.course_catalog.courses[index]
		var preview := app.course_preview
		check.call(preview.course_id == course.course_id and preview.hole_ids == course.hole_ids and preview.runtimes.size() == 9,
			"%s: Vorschau zeigt alle neun aktuellen Bahnen in Kursreihenfolge" % course.course_id)
		check.call(preview.viewport.world_2d != host.get_viewport().world_2d and preview.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"%s: Vorschau besitzt getrennte Physik und blockiert keine Menueeingabe" % course.course_id)
		var fits := true
		for hole_index in range(9):
			var runtime := preview.runtimes[hole_index]
			var bounds := Rect2(runtime.position+runtime.definition.course_rect.position*runtime.scale,runtime.definition.course_rect.size*runtime.scale)
			var cell := Rect2(Vector2(hole_index%3,hole_index/3)*CoursePreview.CELL_SIZE,CoursePreview.CELL_SIZE)
			fits = fits and cell.encloses(bounds) and runtime.process_mode == Node.PROCESS_MODE_DISABLED
		check.call(fits,"%s: ganze Bahnen passen ohne Kamerabeschnitt in ihre unbewegten Vorschaubilder" % course.course_id)
		var obstacle_transforms: Array[Transform2D] = []
		for runtime in preview.runtimes:
			for obstacle in runtime.obstacle_nodes:
				obstacle_transforms.append(obstacle.transform)
		for tick in range(12):
			await host.get_tree().physics_frame
		var obstacle_index := 0
		var stationary := true
		for runtime in preview.runtimes:
			for obstacle in runtime.obstacle_nodes:
				stationary = stationary and obstacle.transform.is_equal_approx(obstacle_transforms[obstacle_index])
				obstacle_index += 1
		check.call(stationary,"%s: Vorschau bewegt Rotoren und Tore auch nach echten Physikframes nicht" % course.course_id)
		var count := mini(app.COURSES_PER_PAGE,app.course_catalog.courses.size()-app.course_select_page*app.COURSES_PER_PAGE)
		var separate := true
		for button_index in range(count-1):
			separate = separate and app.option_buttons[button_index].get_rect().end.y < app.option_buttons[button_index+1].position.y
		check.call(separate,"%s: Kurskarten und Bestwerte ueberlappen nicht" % course.course_id)
		var same_viewport := preview.viewport
		app._select_option(count+1)
		check.call(preview.viewport == same_viewport and preview.course_id == course.course_id,"Navigation behaelt die letzte Kursvorschau")
		app._select_option(index%app.COURSES_PER_PAGE)
		app._invoke_option(index%app.COURSES_PER_PAGE)
		check.call(app.current_screen == GameApp.ScreenState.COURSE_SELECT,"Vorschauladen hebt die Eingabesperre nicht auf")
	app.course_select_page = 0
	app._show_course_select()
	var stale_button := app.option_buttons[2]
	app._move_selection(Vector2.DOWN)
	check.call(app.course_preview.course_id == &"duenenkueste_course","Controller-Navigation aktualisiert den markierten Kurs")
	app._menu_input_locked = false
	app.option_buttons[2].mouse_entered.emit()
	check.call(app.course_preview.course_id == &"muehlental_course","Mauskontakt aktualisiert die neun Vorschaubahnen")
	app._change_course_page(1)
	app._menu_input_locked = false
	stale_button.mouse_entered.emit()
	check.call(app.course_preview.course_id == &"bergpass_course","Alte Maussignale koennen keine fremde Kursvorschau einblenden")
	app._select_option(1)
	app._invoke_option(1)
	check.call(app.current_screen == GameApp.ScreenState.GAMEPLAY and app.session.config.course_id == &"schlossgarten_course" and app.course_preview == null,
		"Bestaetigen startet den zuvor gezeigten Kurs und entfernt die Vorschau")
	app._remove_gameplay()
	app.queue_free()
	await host.get_tree().process_frame
