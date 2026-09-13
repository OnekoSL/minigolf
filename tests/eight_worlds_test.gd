extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Elf Welten: aktueller Produktionskatalog und Spielrahmen]")
	await _test_strandzugang(host, check)
	await _test_muschelbucht(host, check)
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	check.call(courses.courses.size() == 11 and holes.holes.size() == 113,"Elf Kurse und 113 registrierte Bahnen ersetzen den bisherigen Spielbestand")
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
	check.call(ids.size() == 99 and themes.size() == 11,"99 unterschiedliche Kursplaetze mit elf Weltthemen")
	check.call(holes.holes.filter(func(h): return not h.is_course_hole()).size() == 14,"Vierzehn technische Referenzen und Labore bleiben erreichbar")
	for old_id in [&"classic_nine_course",&"arrow_armageddon_course",&"prototype_course_03",&"labyrinth_nine_course",&"reference_lanes_course"]:
		check.call(courses.get_course(old_id) == null,"Alter Kurs %s ist aus der offiziellen Auswahl entfernt" % old_id)
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	host.get_tree().root.add_child(app)
	await host.get_tree().process_frame
	app.best_store = BestScoreStore.new("res://.godot/worlds_best_test.cfg")
	app.best_store.submit(&"classic_nine_course_v10",19)
	for page in range(4):
		app.course_select_page = page
		app._show_course_select()
		var count := mini(3, courses.courses.size() - page * 3)
		check.call(app.option_buttons.size() == count+3,"Kursseite %d zeigt %d Kurse mit Navigation" % [page+1,count])
		check.call(app.option_buttons[count].disabled == (page==0) and app.option_buttons[count+2].disabled == (page==3),"Kursseite %d begrenzt Vor/Zurueck korrekt" % [page+1])
		check.call(app._menu_input_locked,"Seitenwechsel sperrt gehaltene Eingaben")
	app.hole_select_page = 19
	app._show_hole_select()
	check.call(app.hole_select_page == 19 and app.option_buttons.size() == 7,"Uebung erreicht die letzten der 99 Bahnen auf Seite 20")
	app.free_select_page = 19
	app._show_free_builder()
	check.call(app.free_select_page == 19 and app.option_buttons.size() == 9,"Freies Spiel erreicht die letzte Bahnseite")
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


static func _test_strandzugang(host: Node, check: Callable) -> void:
	var hole := HoleCatalog.load_default().get_hole(&"duenenkueste_01")
	var runtime := HoleRuntime.new()
	runtime.configure(hole)
	host.add_child(runtime)
	var ball := PrototypeBall.new()
	host.add_child(ball)
	ball.configure_environment(runtime.zones,hole.hole_position)
	var passage_clear := true
	var sand_flanks := true
	for x in range(248,536):
		for y in range(169,184):
			var sample := ball._surface_at(Vector2(x,y))
			passage_clear = passage_clear and sample.surface_type == SurfaceZone.SurfaceType.SLOPE and sample.acceleration.is_equal_approx(Vector2(60,0))
		for y in [140,167,185,212]:
			var sample := ball._surface_at(Vector2(x,y))
			sand_flanks = sand_flanks and sample.surface_type == SurfaceZone.SurfaceType.SAND and sample.deceleration == 260.0
	check.call(passage_clear,"Strandzugang: durchgaengige mittige Pfeilspur wirkt zum Loch und bleibt frei von Sand")
	check.call(sand_flanks,"Strandzugang: Sand bremst oberhalb und unterhalb der gesamten Pfeilreihe")
	check.call(hole.arrow_tiles.size() == 18 and hole.arrow_tiles.all(func(tile): return tile.get_rect().position.y == 168 and tile.get_rect().size == Vector2(16,16)),"Strandzugang: genau eine waagerechte Reihe atomarer Pfeile")
	check.call(CourseCatalog.load_default().get_course(&"duenenkueste_course").best_score_revision == 3,"Duenenkueste trennt Bestwerte nach Strandzugang und Muschelbucht")
	ball.queue_free()
	runtime.queue_free()
	await host.get_tree().process_frame
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	for entry in entries:
		if entry.id != "duenenkueste_01": continue
		for test_case in [[&"allrounder",0.0,1.0],[&"mara",0.0,1.0],[&"bruno",0.0,1.0],[&"nika",0.0,1.0],[&"allrounder",-0.3,1.0],[&"allrounder",0.3,1.0],[&"allrounder",0.0,0.99],[&"allrounder",0.0,1.01]]:
			var route := WorldRouteFixtures.route(entry,test_case[0],test_case[1],test_case[2])
			var result := await LiveRouteRunner.play(host,hole,route,test_case[0])
			check.call(result.within_par and result.contact_delays.all(func(t): return t == 6),"Strandzugang PAR 1: %s, Winkel %+.1f, Kraft %.2f" % test_case)
			if not result.within_par: print(JSON.stringify(result))


static func _test_muschelbucht(host: Node, check: Callable) -> void:
	var hole := HoleCatalog.load_default().get_hole(&"duenenkueste_05")
	var runtime := HoleRuntime.new()
	runtime.configure(hole)
	host.add_child(runtime)
	var ball := PrototypeBall.new()
	host.add_child(ball)
	ball.configure_environment(runtime.zones,hole.hole_position)
	var downfield := hole.arrow_tiles.size() == 40
	for row in range(4):
		for column in range(10):
			var point := Vector2(320+column*16,64+row*16)
			var sample := ball._surface_at(point)
			downfield = downfield and sample.surface_type == SurfaceZone.SurfaceType.SLOPE and sample.acceleration.is_equal_approx(Vector2(0,60))
	check.call(downfield,"Muschelbucht: 10 Spalten und 4 Reihen wirken durchgaengig nach unten")
	var circle := hole.walls[0]
	check.call(circle.center.y-circle.radius-120.0 > PrototypeBall.RADIUS*2.0,"Muschelbucht: zwischen Feld und Insel bleibt mehr als ein Balldurchmesser Rasen")
	ball.queue_free()
	runtime.queue_free()
	await host.get_tree().process_frame
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	for entry in entries:
		if entry.id != "duenenkueste_05": continue
		for test_case in [[&"allrounder",0.0,1.0],[&"mara",0.0,1.0],[&"bruno",0.0,1.0],[&"nika",0.0,1.0],[&"allrounder",-0.3,1.0],[&"allrounder",0.3,1.0],[&"allrounder",0.0,0.99],[&"allrounder",0.0,1.01]]:
			var route := WorldRouteFixtures.route(entry,test_case[0],test_case[1],test_case[2])
			var result := await LiveRouteRunner.play(host,hole,route,test_case[0])
			check.call(result.within_par and result.contact_delays.all(func(t): return t == 6),"Muschelbucht PAR 3: %s, Winkel %+.1f, Kraft %.2f" % test_case)
			if not result.within_par: print(JSON.stringify(result))
		for variation in [Vector2(-0.3,1),Vector2(0.3,1),Vector2(0,0.99),Vector2(0,1.01)]:
			var route := WorldRouteFixtures.route(entry)
			var stop := Vector2(297.5935,93.8088)
			route[1].target = stop+(route[1].target-stop).rotated(deg_to_rad(variation.x))
			route[1].speed *= variation.y
			var result := await LiveRouteRunner.play(host,hole,route)
			check.call(result.within_par,"Muschelbucht: Feldquerung vertraegt Winkel %+.1f und Kraft %.2f" % [variation.x,variation.y])
			if not result.within_par: print(JSON.stringify(result))
