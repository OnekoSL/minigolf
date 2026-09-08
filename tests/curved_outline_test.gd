extends RefCounted


static func run(check: Callable) -> void:
	print("\n[Echte gebogene Bahnkonturen]")
	var holes := HoleCatalog.load_default()
	for number in [3, 4, 6, 9]:
		var definition := holes.get_hole(StringName("classic_nine_%02d" % number))
		var outline := definition.lane_outline
		check.call(definition.validate().is_empty(), "%s: Bogenkontur ist gueltig" % definition.hole_id)
		check.call(outline.get_floor_points().size() > outline.points.size(), "%s: Gruen folgt den Boegen statt ihren Sehnen" % definition.hole_id)
		var reversed := outline.duplicate(true) as LaneOutlineDefinition
		reversed.points.reverse()
		check.call(reversed.validate("Umgekehrte Kontur").is_empty(), "%s: Beide Umlaufrichtungen der Bogenanker sind gueltig" % definition.hole_id)
		var geometry := WallJoinGeometry.build(definition)
		var arcs_are_tangent := true
		var no_chord_wall := true
		for index in range(outline.points.size()):
			var arc := outline.get_boundary_arc(index)
			if arc == null:
				continue
			var start := outline.points[index]
			var end := outline.points[(index + 1) % outline.points.size()]
			var approach := start - outline.points[(index - 1 + outline.points.size()) % outline.points.size()]
			var departure := outline.points[(index + 2) % outline.points.size()] - end
			arcs_are_tangent = arcs_are_tangent and absf(approach.normalized().dot((start - arc.center).normalized())) < 0.001
			arcs_are_tangent = arcs_are_tangent and absf(departure.normalized().dot((end - arc.center).normalized())) < 0.001
			no_chord_wall = no_chord_wall and not geometry.contains_point((start + end) * 0.5)
		check.call(arcs_are_tangent, "%s: Gerade und diagonale Zufahrten treffen beide Bogenenden tangential" % definition.hole_id)
		check.call(no_chord_wall, "%s: Keine unsichtbare gerade Sehne sperrt den Bogenweg" % definition.hole_id)
		for point in [definition.tee_position, definition.hole_position]:
			check.call(outline.contains_point(point) and reversed.contains_point(point) and not geometry.contains_point(point), "%s: Start/Ziel sind in beiden Umlaufrichtungen frei auf dem Gruen" % definition.hole_id)

	var home := holes.get_hole(&"classic_nine_09")
	check.call(home.lane_outline.contains_point(Vector2(968, 168)) and not home.lane_outline.contains_point(Vector2(856, 168)), "Heimkehr: Wendekanal ist Gruen, Mittelinsel ist ausserhalb der Bahn")
	check.call(not home.lane_outline.contains_point(Vector2(992, 40)) and not home.lane_outline.contains_point(Vector2(992, 304)), "Heimkehr: Ehemalige rechteckige Restflaechen sind nicht mehr bespielbar")
	check.call(home.lane_outline.boundary_arcs[0].radius - home.lane_outline.boundary_arcs[1].radius == 64.0, "Heimkehr: Einlauf, Kurve und Ruecklauf haben einheitlich 64 Pixel Achsabstand")
	var horseshoe := holes.get_hole(&"classic_nine_04")
	var symmetric := true
	for point in horseshoe.lane_outline.points:
		symmetric = symmetric and horseshoe.lane_outline.points.has(Vector2(point.x, 352.0 - point.y))
	check.call(symmetric and horseshoe.tee_position.y == 176 and horseshoe.hole_position.y == 176, "Hufeisen: Kontur, Zufahrt und Ziel liegen auf einer gemeinsamen Symmetrieachse")
	var opener := holes.get_hole(&"classic_nine_01")
	check.call(opener.tee_position.y == 176 and opener.hole_position.y == 176, "Auftakt: Start und Loch stimmen mit der Konturachse ueberein")
	var neck := holes.get_hole(&"classic_nine_06")
	check.call(neck.arrow_tiles.all(func(tile): return tile.grid_offset == Vector2i(0, 8)), "Engstelle: Das komplette Pfeilraster schliesst an die Halswaende an")
	check.call(neck.lane_outline.contains_point(Vector2(392, 169)) and neck.lane_outline.contains_point(Vector2(392, 231)) and not neck.lane_outline.contains_point(Vector2(392, 165)) and not neck.lane_outline.contains_point(Vector2(392, 235)), "Engstelle: Kein neutraler Seitenstreifen neben dem 64 Pixel hohen Pflichtfeld")

	var invalid := home.lane_outline.duplicate(true) as LaneOutlineDefinition
	invalid.boundary_arcs[0].center.x += 16
	check.call(not invalid.validate("Falscher Anker").is_empty(), "Aussenbogen ohne passendes Ankerpaar wird abgelehnt")
	invalid = home.lane_outline.duplicate(true)
	invalid.boundary_arcs.append(invalid.boundary_arcs[0].duplicate(true))
	check.call(not invalid.validate("Doppelter Bogen").is_empty(), "Zwei Boegen auf derselben Ankerkante werden abgelehnt")
	invalid = home.lane_outline.duplicate(true)
	invalid.boundary_arcs[0].thickness = 8
	check.call(not invalid.validate("Falsche Breite").is_empty(), "Abweichende Staerke am Bogenanschluss wird abgelehnt")
	invalid = home.lane_outline.duplicate(true)
	invalid.use_normalized_walls = false
	check.call(not invalid.validate("Legacy-Bogenkontur").is_empty(), "Gebogene Aussenkonturen erfordern das gemeinsame Wandnetz")
	var out_of_bounds := home.duplicate(true) as HoleDefinition
	out_of_bounds.course_rect.size.x = 700
	check.call(not out_of_bounds.validate().is_empty(), "Katalogpruefung erfasst auch die Auswoelbung eines Bogens ausserhalb der Kameraflaeche")
