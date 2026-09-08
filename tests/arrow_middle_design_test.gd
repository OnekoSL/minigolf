extends RefCounted

# World-space sections are bounded by real joined wall geometry, not merely
# expected cell counts. All fields share the half-cell raster of their walls.
const FIELDS := {
	4: [Rect2(232,248,48,64),Rect2(360,184,64,64),Rect2(504,136,48,64)],
	5: [Rect2(280,136,160,112),Rect2(440,56,64,176),Rect2(360,88,64,48),Rect2(360,248,64,32)],
	6: [Rect2(424,248,192,80),Rect2(936,168,64,160),Rect2(616,168,192,80),Rect2(184,88,64,160),Rect2(456,88,352,80)],
}
const ROUTES := {
	4: [[Vector2(350,235),245.0],[Vector2(580,180),110.0],[Vector2(580,180),78.0]],
	5: [[Vector2(395,180),230.0],[Vector2(575,95),225.0],[Vector2(575,70),100.0]],
	6: [[-2.0,360.0],[-180.0,280.0],[-156.0,370.0]],
}


static func run(host: Node, check: Callable) -> void:
	print("\n[Pfeil-Mittelteil: Pflichtquerschnitte und Tunnelroute]")
	var holes := HoleCatalog.load_default()
	for number in [4,5,6]:
		var definition := holes.get_hole(StringName("arrow_armageddon_%02d" % number))
		check.call(definition.validate().is_empty(), "%s: neue Passage ist kataloggueltig" % definition.hole_id)
		var expected_count: int = {4:40,5:134,6:310}[number]
		check.call(definition.arrow_tiles.size() == expected_count, "%s: kuratierte Pfeilmenge" % definition.hole_id)
		check.call(definition.arrow_tiles.all(func(tile): return tile.grid_offset == Vector2i(8,8) and tile.cell_size == 16 and tile.deceleration == 30 and tile.minimum_flow_speed == 0 and tile.maximum_flow_speed == 0 and tile.flow_alignment_rate == 0 and tile.flow_centering_strength == 0), "%s: gemeinsames wandbuendiges Raster ohne Flow-Hilfe" % definition.hole_id)
		for field in FIELDS[number]:
			check.call(_field_is_filled(definition, field), "%s: Feld %s besitzt jede benoetigte atomare Zelle" % [definition.hole_id,field])
		var geometry := WallJoinGeometry.build(definition)
		if number == 4:
			# The outline is x-monotone: these are all possible y positions at
			# each cut, not a selected corridor inside a wider open chamber.
			for field in FIELDS[number]:
				check.call(_whole_vertical_cut(definition,geometry,field.get_center().x), "Wechselstrom: Jede der drei Stufen sperrt den gesamten neutralen Querschnitt")
		elif number == 5:
			check.call(_whole_vertical_cut(definition,geometry,304), "Kompasskreuz: Jeder Bodenweg vom Westabschlag zur Kreuzung durchquert blaue Pfeile")
			check.call(definition.arrow_tiles.filter(func(tile): return tile.slope_grade == SurfaceZone.SlopeGrade.SHALLOW).all(func(tile): return tile.direction == SurfaceZone.SlopeDirection.UP), "Kompasskreuz: Suedarm fuehrt aus dem Fehlweg zur Kreuzung zurueck")
		else:
			for field in [FIELDS[6][0],FIELDS[6][2],FIELDS[6][4]]:
				check.call(_bounded_section(definition,geometry,field), "Pfeilspirale: Horizontaler Pflichtgang %s besitzt keinen neutralen Randstreifen" % field)
			check.call(_wall_line_closed(geometry,Vector2(184,248),Vector2(936,248)), "Pfeilspirale: Unterer Riegel ist bis zum rechten Umlauf durchgehend geschlossen")
			check.call(_wall_line_closed(geometry,Vector2(248,168),Vector2(1000,168)), "Pfeilspirale: Mittlerer Riegel ist bis zum linken Umlauf durchgehend geschlossen")
			check.call(_wall_line_closed(geometry,Vector2(840,24),Vector2(840,168)) and _wall_line_closed(geometry,Vector2(840,168),Vector2(1000,168)), "Pfeilspirale: West- und Suedwand trennen die Zielkammer vollstaendig vom Bodenweg")
			check.call(not definition.lane_outline.contains_point(Vector2(600,56)), "Pfeilspirale: Eingeschlossene obere Restflaeche ist kein Spielboden")
			check.call(definition.surfaces.size() == 1 and definition.surfaces[0].surface_type == SurfaceZone.SurfaceType.SAND and definition.surfaces[0].rect == Rect2(480,216,112,32), "Pfeilspirale: Eine unveraenderte Sandtasche bleibt als Auffangzone")
			check.call(definition.tunnels.size() == 1 and definition.tunnels[0].endpoint_a == Vector2(808,100) and definition.tunnels[0].endpoint_b == Vector2(872,100), "Pfeilspirale: Ein unmarkiertes Tunnelpaar verbindet Auslauf und Zielkammer")
			check.call(_free_line(definition,geometry,Vector2(536,232),Vector2(536,184)), "Pfeilspirale: Die Sandtasche laesst sich zum mittleren Gang verlassen")
		var route_result := await _route(host,definition,ROUTES[number])
		check.call(route_result["holed"] and route_result["shots"] <= definition.par and route_result["legal"], "%s: Legale PAR-Route endet mit echtem Einlochsignal" % definition.hole_id)
		if number == 6:
			check.call(route_result["tunnel_used"], "Pfeilspirale: PAR-Nachweis verwendet den Tunnel tatsaechlich")
		else:
			# Later targets follow the actual resting position, just like a
			# player aiming anew; only the first shot receives perturbations.
			for angle_error in [-0.25,0.0,0.25]:
				for speed_error in [-3.0,0.0,3.0]:
					var shots: Array = ROUTES[number].duplicate(true)
					var direction := definition.tee_position.direction_to(shots[0][0])
					shots[0] = [rad_to_deg(direction.angle()) + angle_error,shots[0][1] + speed_error]
					var perturbed := await _route(host,definition,shots)
					check.call(perturbed["holed"] and perturbed["legal"] and perturbed["shots"] <= definition.par, "%s: PAR bei erstem Winkel %+.2f Grad / Tempo %+.1f" % [definition.hole_id,angle_error,speed_error])


static func _field_is_filled(definition: HoleDefinition, field: Rect2) -> bool:
	var count := 0
	for tile in definition.arrow_tiles:
		if field.encloses(tile.get_rect()): count += 1
	return count == int(field.size.x * field.size.y / 256)


static func _arrow_intervals(definition: HoleDefinition, x: float) -> Array[Vector2]:
	var intervals: Array[Vector2] = []
	for tile in definition.arrow_tiles:
		var rect := tile.get_rect()
		if x >= rect.position.x and x < rect.end.x:
			intervals.append(Vector2(rect.position.y,rect.end.y))
	intervals.sort_custom(func(a,b): return a.x < b.x)
	return intervals


static func _intervals_cover(intervals: Array[Vector2], low: float, high: float) -> bool:
	var covered_until := low
	for interval in intervals:
		if interval.y < covered_until: continue
		if interval.x > covered_until: return false
		covered_until = maxf(covered_until,interval.y)
		if covered_until >= high: return true
	return false


static func _wall_clear(geometry: WallJoinGeometry, point: Vector2) -> bool:
	if geometry.contains_point(point): return false
	for index in range(0,geometry.boundary_segments.size(),2):
		if Geometry2D.get_closest_point_to_segment(point,geometry.boundary_segments[index],geometry.boundary_segments[index+1]).distance_to(point) < PrototypeBall.RADIUS:
			return false
	return true


static func _whole_vertical_cut(definition: HoleDefinition, geometry: WallJoinGeometry, x: float) -> bool:
	if definition.tee_position.x >= x or definition.hole_position.x <= x: return false
	var start := Vector2(x,definition.course_rect.position.y)
	var end := Vector2(x,definition.course_rect.end.y)
	var polygon := definition.lane_outline.get_floor_points()
	var cuts: Array[float] = [0.0,1.0]
	_add_polygon_cuts(cuts,start,end,polygon)
	cuts.sort()
	var arrows := _arrow_intervals(definition,x)
	var found_floor := false
	for index in range(cuts.size()-1):
		if cuts[index+1] <= cuts[index]: continue
		var midpoint := start.lerp(end,(cuts[index]+cuts[index+1])*0.5)
		if not Geometry2D.is_point_in_polygon(midpoint,polygon): continue
		found_floor = true
		var low := start.lerp(end,cuts[index]).y
		var high := start.lerp(end,cuts[index+1]).y
		# Cover the entire floor interval, including the wall centerlines.
		# This is stronger than only covering radius-5 ball-center space.
		if not _intervals_cover(arrows,low,high): return false
		if not geometry.contains_point(Vector2(x,low)) or not geometry.contains_point(Vector2(x,high)): return false
	return found_floor


static func _bounded_section(definition: HoleDefinition, geometry: WallJoinGeometry, field: Rect2) -> bool:
	# Valid, non-overlapping 16x16 cells whose total area equals the field
	# cover the rectangle. Both longitudinal walls must cover its full length.
	return _field_is_filled(definition,field) \
		and _wall_line_closed(geometry,field.position,Vector2(field.end.x,field.position.y)) \
		and _wall_line_closed(geometry,Vector2(field.position.x,field.end.y),field.end)


static func _wall_line_closed(geometry: WallJoinGeometry, start: Vector2, end: Vector2) -> bool:
	var cuts: Array[float] = [0.0,1.0]
	for polygon in geometry.polygons:
		_add_polygon_cuts(cuts,start,end,polygon)
	cuts.sort()
	# Polygon-union membership is constant between consecutive edge cuts.
	# Check every critical point and every open interval, without raster steps.
	for index in range(cuts.size()):
		if not geometry.contains_point(start.lerp(end,cuts[index])): return false
		if index+1 < cuts.size() and cuts[index+1] > cuts[index]:
			if not geometry.contains_point(start.lerp(end,(cuts[index]+cuts[index+1])*0.5)): return false
	return true


static func _free_line(definition: HoleDefinition, geometry: WallJoinGeometry, start: Vector2, end: Vector2) -> bool:
	var polygon := definition.lane_outline.get_floor_points()
	var cuts: Array[float] = [0.0,1.0]
	_add_polygon_cuts(cuts,start,end,polygon)
	cuts.sort()
	for index in range(cuts.size()):
		if not Geometry2D.is_point_in_polygon(start.lerp(end,cuts[index]),polygon): return false
		if index+1 < cuts.size() and cuts[index+1] > cuts[index]:
			if not Geometry2D.is_point_in_polygon(start.lerp(end,(cuts[index]+cuts[index+1])*0.5),polygon): return false
	if not _wall_clear(geometry,start) or not _wall_clear(geometry,end): return false
	for index in range(0,geometry.boundary_segments.size(),2):
		var a := geometry.boundary_segments[index]
		var b := geometry.boundary_segments[index+1]
		if Geometry2D.segment_intersects_segment(start,end,a,b) != null: return false
		var distance := minf(
			minf(start.distance_to(Geometry2D.get_closest_point_to_segment(start,a,b)),end.distance_to(Geometry2D.get_closest_point_to_segment(end,a,b))),
			minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a,start,end)),b.distance_to(Geometry2D.get_closest_point_to_segment(b,start,end))))
		if distance < PrototypeBall.RADIUS: return false
	return true


static func _add_polygon_cuts(cuts: Array[float], start: Vector2, end: Vector2, polygon: PackedVector2Array) -> void:
	var line := end-start
	if line.length_squared() == 0.0: return
	for index in range(polygon.size()):
		var a := polygon[index]
		var b := polygon[(index+1)%polygon.size()]
		var edge := b-a
		var denominator := line.cross(edge)
		var offset := a-start
		if denominator != 0.0:
			var along := offset.cross(edge)/denominator
			var edge_along := offset.cross(line)/denominator
			if along >= 0.0 and along <= 1.0 and edge_along >= 0.0 and edge_along <= 1.0:
				cuts.append(along)
		elif offset.cross(line) == 0.0:
			# Collinear boundaries change interval ownership at their endpoints.
			cuts.append(clampf(offset.dot(line)/line.length_squared(),0.0,1.0))
			cuts.append(clampf((b-start).dot(line)/line.length_squared(),0.0,1.0))


static func _route(host: Node, definition: HoleDefinition, shots: Array) -> Dictionary:
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	host.get_tree().root.add_child(runtime)
	var ball := PrototypeBall.new()
	host.get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = definition.tee_position
	ball.configure_environment(runtime.zones,definition.hole_position,definition.tunnels)
	var result := {"holed":false,"tunnel_used":false,"legal":true,"shots":0}
	ball.holed.connect(func(_strokes): result["holed"] = true)
	await host.get_tree().physics_frame
	for index in range(shots.size()):
		var aim = shots[index][0]
		var speed:float = shots[index][1]
		result["legal"] = result["legal"] and speed >= 78 and speed <= 420
		if ball.moving: break
		var direction:Vector2 = Vector2.from_angle(deg_to_rad(float(aim))) if typeof(aim) == TYPE_FLOAT or typeof(aim) == TYPE_INT else ball.position.direction_to(aim)
		ball.launch(direction,speed,index+1)
		result["shots"] = index+1
		for _step in range(2400):
			ball._physics_process(1.0/60.0)
			result["tunnel_used"] = result["tunnel_used"] or ball._tunnel_active
			if not ball.moving: break
		if ball.position.distance_to(definition.hole_position) <= PrototypeBall.HOLE_RADIUS:
			await host.get_tree().create_timer(0.4).timeout
		if result["holed"]: break
	if not result["holed"]: print("  Pfeilroute ",definition.hole_id," endete bei ",ball.position)
	ball.free()
	runtime.free()
	return result
