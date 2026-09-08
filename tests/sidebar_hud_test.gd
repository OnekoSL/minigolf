extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Spielfeldfreie Seitenanzeige]")
	var hud := PrototypeHUD.new()
	host.add_child(hud)
	var catalog := HoleCatalog.load_default()
	hud.set_player_context(PlayerProfile.create(1, "SPIELER MIT LANGEM NAMEN", 0), 9, 9, 180)
	hud.update_game(23, 20, 0.5, 0.0, ShotController.ShotState.AIMING, 230, 23)
	for definition in catalog.holes:
		hud.set_course_name(definition.display_name)
		await host.get_tree().process_frame
		check.call(hud.help_label.get_visible_line_count() == hud.help_label.get_line_count(), "%s: Alle vier Steuerungshinweise bleiben sichtbar" % definition.hole_id)
		var inside := true
		var labels: Array[Label] = [hud.controller_label, hud.course_label, hud.stroke_label, hud.player_label, hud.round_label, hud.distance_label, hud.help_label]
		for index in range(labels.size()):
			var rect := labels[index].get_rect()
			inside = inside and rect.position.x >= 0 and rect.end.x <= 168 and rect.end.y <= 216
			for other_index in range(index + 1, labels.size()):
				inside = inside and not rect.intersects(labels[other_index].get_rect())
		check.call(inside, "%s: Bahninfos bleiben ohne Ueberlappung in der Seitenleiste" % definition.hole_id)
	hud.free()
