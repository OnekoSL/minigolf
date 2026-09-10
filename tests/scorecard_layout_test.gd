extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Ergebnistabelle: Textfeldgrenzen]")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	for course in courses.courses:
		for player_count in [1, 4]:
			var config := RoundConfig.new()
			config.course_id = course.course_id
			config.hole_ids = course.hole_ids.duplicate()
			config.mode = RoundConfig.GameMode.COURSE_SOLO if player_count == 1 else RoundConfig.GameMode.COURSE_LOCAL
			for index in range(player_count):
				config.players.append(PlayerProfile.create(index + 1, "ABCDEFGHIJKL", index))
			var session := RoundSession.new()
			session.configure(config, holes)
			for row in range(player_count):
				for index in range(config.hole_ids.size()):
					session.scores[row][index] = holes.get_hole(config.hole_ids[index]).par
			var table := ScorecardView.new()
			table.configure(session, holes, courses, true)
			host.add_child(table)
			await host.get_tree().process_frame
			var title_rect := Rect2()
			var info_rect := Rect2()
			var inside := true
			for child in table.get_children():
				if not child is Label:
					continue
				inside = inside and Rect2(62, 76, 516, 218).encloses(child.get_rect())
				if child.text == course.display_name:
					title_rect = child.get_rect()
				if child.text.contains("LOECHER") and child.text.contains("PAR") and not child.text.contains("UNTER"):
					info_rect = child.get_rect()
			check.call(inside, "%s / %d Spieler: Textfelder bleiben innerhalb der Tabelle" % [course.course_id, player_count])
			check.call(info_rect.size.x == 150 and info_rect.end.x == 568 and not title_rect.intersects(info_rect), "%s: Kursinfo haelt rechten Innenabstand ohne Titelueberlappung" % course.course_id)
			table.free()
