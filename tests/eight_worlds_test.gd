extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Acht Welten: aktueller Produktionskatalog und Spielrahmen]")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	check.call(courses.courses.size() == 8 and holes.holes.size() == 86,"Acht Kurse und 86 registrierte Bahnen ersetzen den bisherigen Spielbestand")
	check.call(holes.validate().is_empty() and courses.validate(holes).is_empty(),"Alle aktuellen Bahn- und Kursdefinitionen sind gueltig")
	var ids: Dictionary = {}
	var themes: Dictionary = {}
	for course in courses.courses:
		check.call(course.hole_ids.size() == 9 and not course.allow_technical_holes,"%s: neun regulaere Kursbahnen" % course.course_id)
		for hole_id in course.hole_ids:
			var hole := holes.get_hole(hole_id)
			check.call(not ids.has(hole_id) and hole.is_course_hole(),"%s gehoert genau einem offiziellen Kurs" % hole_id)
			ids[hole_id] = true
			check.call(hole.theme != null and String(hole.theme.theme_id)+"_course" == String(course.course_id),"%s verwendet das passende gemeinsame Weltthema" % hole_id)
			check.call(hole.lane_outline != null and hole.lane_outline.use_normalized_walls,"%s besitzt eine geschlossene Normkontur" % hole_id)
			check.call(hole.arrow_tiles.all(func(tile): return tile.deceleration == 30 and tile.minimum_flow_speed == 0 and tile.maximum_flow_speed == 0 and tile.flow_alignment_rate == 0 and tile.flow_centering_strength == 0),"%s behaelt reine Gefaellephysik" % hole_id)
			themes[hole.theme.theme_id] = true
	check.call(ids.size() == 72 and themes.size() == 8,"72 unterschiedliche Kursplaetze mit acht Weltthemen")
	check.call(holes.holes.filter(func(h): return not h.is_course_hole()).size() == 14,"Vierzehn technische Referenzen und Labore bleiben erreichbar")
	for old_id in [&"classic_nine_course",&"arrow_armageddon_course",&"prototype_course_03",&"labyrinth_nine_course",&"reference_lanes_course"]:
		check.call(courses.get_course(old_id) == null,"Alter Kurs %s ist aus der offiziellen Auswahl entfernt" % old_id)
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	host.get_tree().root.add_child(app)
	await host.get_tree().process_frame
	app.best_store = BestScoreStore.new("res://.godot/worlds_best_test.cfg")
	app.best_store.submit(&"classic_nine_course_v10",19)
	for page in range(3):
		app.course_select_page = page
		app._show_course_select()
		var count := 3 if page<2 else 2
		check.call(app.option_buttons.size() == count+3,"Kursseite %d zeigt %d Kurse mit Navigation" % [page+1,count])
		check.call(app.option_buttons[count].disabled == (page==0) and app.option_buttons[count+2].disabled == (page==2),"Kursseite %d begrenzt Vor/Zurueck korrekt" % [page+1])
		check.call(app._menu_input_locked,"Seitenwechsel sperrt gehaltene Eingaben")
	app.hole_select_page = 14
	app._show_hole_select()
	check.call(app.hole_select_page == 14 and app.option_buttons.size() == 5,"Uebung erreicht die letzten zwei der 72 Bahnen auf Seite 15")
	app.free_select_page = 14
	app._show_free_builder()
	check.call(app.free_select_page == 14 and app.option_buttons.size() == 7,"Freies Spiel erreicht die letzte Bahnseite")
	for course in courses.courses:
		var config := RoundConfig.new()
		config.course_id = course.course_id
		config.players = [PlayerProfile.create(1,"TEST",0)]
		config.hole_ids = course.hole_ids.duplicate()
		check.call(config.validate(holes,courses).is_empty() and config.is_best_eligible(holes,courses),"%s ist als vollstaendige Runde bestwertberechtigt" % course.course_id)
		app._start_round(config)
		check.call(app.gameplay.hole.definition.hole_id == course.hole_ids[0] and not app.gameplay.input_enabled,"%s startet die richtige Bahn mit Eingabesperre" % course.course_id)
		for index in range(9):
			app._on_attempt_finished(holes.get_hole(course.hole_ids[index]).par,false)
			if index<8:
				app.session.advance_hole()
				app._start_current_attempt()
		check.call(app.current_screen == GameApp.ScreenState.FINAL and app.session.get_player_total(0) == course.get_total_par(holes),"%s beendet alle neun Loecher mit korrekter Gesamttabelle" % course.course_id)
	check.call(app.best_store.get_best(&"classic_nine_course_v10") == 19,"Historischer Bestwert bleibt beim Speichern neuer Welten erhalten")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.best_store.storage_path))
	app.queue_free()
	await host.get_tree().process_frame
