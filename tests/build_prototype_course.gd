extends SceneTree

# Reproducible course editions; the original laboratory resources stay intact.
func _initialize() -> void:
	var garden := _hole(4, "SANDUFER", 3, [Vector2(184,216), Vector2(472,216), Vector2(472,56), Vector2(600,56), Vector2(600,328), Vector2(184,328)], Vector2(220,280), Vector2(552,88))
	_surface(garden, Rect2(280,264,64,64), SurfaceZone.SurfaceType.SAND)
	_surface(garden, Rect2(392,216,80,40), SurfaceZone.SurfaceType.WATER)
	_save(garden, 4)
	var hills := _hole(5, "DOPPELHUEGEL", 3, [Vector2(184,104),Vector2(312,104),Vector2(344,136),Vector2(472,136),Vector2(504,104),Vector2(632,104),Vector2(664,136),Vector2(792,136),Vector2(824,104),Vector2(984,104),Vector2(984,248),Vector2(824,248),Vector2(792,216),Vector2(664,216),Vector2(632,248),Vector2(504,248),Vector2(472,216),Vector2(344,216),Vector2(312,248),Vector2(184,248)], Vector2(232,176), Vector2(936,176), 816)
	_arrows(hills, Rect2i(360,136,32,80), 6, 0)
	_arrows(hills, Rect2i(392,136,32,80), 2, 0)
	_arrows(hills, Rect2i(680,136,32,80), 6, 1)
	_arrows(hills, Rect2i(712,136,32,80), 2, 1)
	_save(hills, 5)
	var river := _hole(6, "UFERKEHRE", 3, [Vector2(216,56),Vector2(312,56),Vector2(312,216),Vector2(504,216),Vector2(504,56),Vector2(600,56),Vector2(600,280),Vector2(568,312),Vector2(248,312),Vector2(216,280)], Vector2(264,88), Vector2(552,88))
	river.initial_aim_offset = Vector2(0,100)
	_arrows(river, Rect2i(216,136,96,48), 4, 0)
	_arrows(river, Rect2i(504,136,96,48), 0, 0)
	_save(river, 6)
	var panorama := _hole(7, "PANORAMAWEG", 5, [Vector2(184,56),Vector2(472,56),Vector2(472,216),Vector2(728,216),Vector2(728,56),Vector2(1112,56),Vector2(1112,184),Vector2(840,184),Vector2(840,328),Vector2(360,328),Vector2(360,168),Vector2(184,168)], Vector2(224,112), Vector2(1064,120), 944)
	_arrows(panorama, Rect2i(536,216,48,112), 2, 0)
	_surface(panorama, Rect2(880,56,64,48), SurfaceZone.SurfaceType.SAND)
	_save(panorama, 7)
	var curve := _hole(8, "BOGENPROMENADE", 4, [Vector2(216,56),Vector2(312,56),Vector2(312,200),Vector2(504,200),Vector2(504,56),Vector2(600,56),Vector2(600,200),Vector2(216,200)], Vector2(264,88), Vector2(552,88))
	curve.initial_aim_offset = Vector2(0,100)
	var inner := _arc(Vector2(408,200), 96)
	var outer := _arc(Vector2(408,200), 192)
	curve.lane_outline.boundary_arcs = [inner, outer]
	curve.course_rect.size.y = 400
	curve.camera_center_bounds.size.y = 64
	_save(curve, 8)
	quit()


func _hole(number: int, title: String, par: int, points: Array, tee: Vector2, cup: Vector2, width := 448) -> HoleDefinition:
	var hole := HoleDefinition.new()
	hole.hole_id = StringName("prototype_%02d" % number)
	hole.display_name = title
	hole.par = par
	hole.garden_presentation = true
	hole.course_rect = Rect2(176,16,width,328)
	hole.camera_center_bounds = Rect2(320,180,maxi(0,width - 456),0)
	hole.lane_outline = LaneOutlineDefinition.new()
	hole.lane_outline.points = PackedVector2Array(points)
	hole.lane_outline.use_normalized_walls = true
	hole.tee_position = tee
	hole.hole_position = cup
	hole.initial_aim_offset = Vector2(96,0)
	return hole


func _arrows(hole: HoleDefinition, rect: Rect2i, direction: int, grade: int) -> void:
	for y in range(rect.position.y, rect.end.y, 16):
		for x in range(rect.position.x, rect.end.x, 16):
			var tile := ArrowTileDefinition.new()
			tile.grid_cell = Vector2i(x / 16, y / 16)
			tile.grid_offset = Vector2i(x % 16, y % 16)
			tile.direction = direction
			tile.slope_grade = grade
			hole.arrow_tiles.append(tile)


func _surface(hole: HoleDefinition, rect: Rect2, kind: int) -> void:
	var surface := SurfaceDefinition.new()
	surface.rect = rect
	surface.surface_type = kind
	surface.deceleration = 260 if kind == SurfaceZone.SurfaceType.SAND else 120
	hole.surfaces.append(surface)


func _arc(center: Vector2, radius: float) -> WallDefinition:
	var arc := WallDefinition.new()
	arc.wall_type = WallDefinition.WallType.ARC
	arc.center = center
	arc.radius = radius
	arc.thickness = 4
	arc.arc_start_degrees = 0
	arc.arc_sweep_degrees = 180
	arc.arc_segments = 64
	return arc


func _save(hole: HoleDefinition, number: int) -> void:
	var errors := hole.validate()
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	var result := ResourceSaver.save(hole, "res://data/holes/prototype_%02d.tres" % number)
	print(hole.display_name, ": ", error_string(result))
