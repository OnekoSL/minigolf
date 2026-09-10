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
		var inside := true
		var labels: Array[Label] = [hud.controller_label, hud.course_label, hud.stroke_label, hud.player_label, hud.round_label, hud.distance_label]
		for index in range(labels.size()):
			var rect := labels[index].get_rect()
			inside = inside and rect.position.x >= 0 and rect.end.x <= 168 and rect.end.y <= 168
			for other_index in range(index + 1, labels.size()):
				inside = inside and not rect.intersects(labels[other_index].get_rect())
		check.call(inside, "%s: Bahninfos bleiben ohne Ueberlappung in der Seitenleiste" % definition.hole_id)
	var panel := hud.golfer.get_parent() as Control
	check.call(panel.get_rect().end.y <= 352 and panel.position.y >= hud.distance_label.get_rect().end.y, "Vergroessertes Golferfenster bleibt unter den Bahninfos im Bildschirm")
	check.call(panel.get_rect().size.y >= 180 and hud.power_bar.size.y >= 150, "Golferfenster nutzt den freigewordenen Platz fuer die laengere Skala")
	var panel_labels: Array[String] = []
	for child in panel.get_children():
		if child is Label:
			panel_labels.append(child.text)
	check.call(panel_labels == [hud.golfer_title.text], "Golferfenster enthaelt nur den Spielertitel und keine Phasen- oder Anzeigetexte")
	hud.free()
