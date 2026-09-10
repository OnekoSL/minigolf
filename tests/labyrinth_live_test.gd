extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Labyrinth: bestaetigte Route mit aktiven Hindernissen]")
	var hole := HoleCatalog.load_default().get_hole(&"labyrinth_nine_05")
	var route := LabyrinthRoutes.live_route(hole.hole_id, 150)
	var first := await LiveRouteRunner.play(host, hole, route)
	var second := await LiveRouteRunner.play(host, hole, route)
	check.call(first.holed and second.holed, "Diagonalfalle: Aktive Hindernisse erlauben dieselbe Route nach zwei frischen Resets")
	check.call(first.within_par and second.within_par, "Diagonalfalle: Beide echten Ablaeufe enden innerhalb PAR %d" % hole.par)
	check.call(first.within_limit and second.within_limit, "Diagonalfalle: Beide echten Ablaeufe liegen innerhalb des Schlaglimits")
	check.call(first.strokes == 4 and second.strokes == 4, "Diagonalfalle: Vier legale Schlaege werden am Ballkontakt gezaehlt")
	check.call(first.contact_delays == [6, 6, 6, 6] and second.contact_delays == [6, 6, 6, 6], "Live-Routen beruecksichtigen den Abschwung von sechs Physikticks")
	check.call(same_stops(first, second), "Diagonalfalle: Zwischenpositionen bleiben beim Wiederholen reproduzierbar")


static func same_stops(first: Dictionary, second: Dictionary) -> bool:
	if first.trace.size() != second.trace.size():
		return false
	for index in range(first.trace.size()):
		var a: Array = first.trace[index].position
		var b: Array = second.trace[index].position
		if Vector2(a[0], a[1]).distance_to(Vector2(b[0], b[1])) > 0.01:
			return false
	return true
