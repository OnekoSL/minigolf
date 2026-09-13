class_name CourseTheme
extends Resource

enum Motif { PARK, COAST, MILL, MOUNTAIN, PALACE, FACTORY, TEMPLE, OBSERVATORY, CIRCUS, CONSTRUCTION, URBAN_WINTER }

@export var theme_id: StringName
@export var background := Color("183626")
@export var turf := Color("347a4a")
@export var wall := Color("dad1af")
@export var trim := Color("584d43")
@export var accent := Color("e5bf73")
@export var foliage := Color("244936")
@export var motif := Motif.PARK


func draw_scenery(canvas: Node2D, hole: HoleDefinition) -> void:
	var floor_points := hole.lane_outline.get_floor_points()
	var bounds := hole.course_rect
	if motif in [Motif.CONSTRUCTION, Motif.URBAN_WINTER]:
		_draw_concrete(canvas, floor_points, bounds)
	# Texture is clipped to the same curved floor used by physics.
	for x in range(int(bounds.position.x), int(bounds.end.x), 48):
		if motif in [Motif.CONSTRUCTION, Motif.URBAN_WINTER]:
			break
		var stripe := PackedVector2Array([Vector2(x,bounds.position.y), Vector2(x+24,bounds.position.y), Vector2(x+24,bounds.end.y), Vector2(x,bounds.end.y)])
		for polygon in Geometry2D.intersect_polygons(floor_points, stripe):
			canvas.draw_colored_polygon(polygon, Color(accent, 0.035))
	for y in range(int(bounds.position.y)+16, int(bounds.end.y)-20, 48):
		for x in range(int(bounds.position.x)+24, int(bounds.end.x)-20, 48):
			if motif in [Motif.CONSTRUCTION, Motif.URBAN_WINTER]:
				if (x/48+y/48)%3 != 0:
					continue
			elif (x/48+y/48)%3 == 1:
				continue
			var point := Vector2(x,y)
			if not _has_clearance(point, floor_points, hole):
				continue
			_draw_motif(canvas, point, (x / 48 * 2 + y / 48) % 3 if motif in [Motif.CIRCUS, Motif.CONSTRUCTION, Motif.URBAN_WINTER] else (x / 48 + y / 48) % 3)


func _has_clearance(point: Vector2, floor_points: PackedVector2Array, hole: HoleDefinition) -> bool:
	if Geometry2D.is_point_in_polygon(point, floor_points):
		return false
	for index in range(floor_points.size()):
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, floor_points[index], floor_points[(index+1)%floor_points.size()])) < 23:
			return false
	for obstacle in hole.obstacles:
		var reach := maxf(obstacle.blade_size.length(), obstacle.seesaw_size.length()) * 0.5 + 22
		if point.distance_to(obstacle.position) < reach:
			return false
		if obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE:
			var rail := Rect2(obstacle.position-obstacle.gate_size*0.5, obstacle.gate_size)
			if rail.merge(Rect2(rail.position+obstacle.open_offset,rail.size)).grow(22).has_point(point):
				return false
	return true


func _draw_motif(canvas: Node2D, p: Vector2, variant: int) -> void:
	match motif:
		Motif.URBAN_WINTER:
			if variant == 0:
				canvas.draw_rect(Rect2(p + Vector2(-12, 10), Vector2(24, 4)), wall)
				canvas.draw_line(p + Vector2(0, 10), p + Vector2(0, -15), trim, 3)
				canvas.draw_rect(Rect2(p + Vector2(-5, -17), Vector2(10, 9)), trim)
				canvas.draw_rect(Rect2(p + Vector2(-3, -15), Vector2(6, 5)), accent)
				canvas.draw_line(p + Vector2(-6, -18), p + Vector2(6, -18), wall, 2)
			elif variant == 1:
				for x in [-11, 11]:
					canvas.draw_line(p + Vector2(x, 0), p + Vector2(x, 12), trim, 3)
				canvas.draw_rect(Rect2(p + Vector2(-15, -5), Vector2(30, 7)), foliage)
				canvas.draw_rect(Rect2(p + Vector2(-15, 5), Vector2(30, 4)), trim)
				canvas.draw_line(p + Vector2(-15, -6), p + Vector2(15, -6), wall, 3)
			else:
				for x in [-12, 0, 12]:
					var height: int = 20 + (x + 12) / 3
					canvas.draw_rect(Rect2(p + Vector2(x - 5, 12 - height), Vector2(10, height)), foliage)
					canvas.draw_line(p + Vector2(x - 5, 12 - height), p + Vector2(x + 5, 12 - height), wall, 2)
					for y in range(16 - height, 8, 7):
						canvas.draw_rect(Rect2(p + Vector2(x - 2, y), Vector2(3, 3)), accent)
		Motif.CONSTRUCTION:
			if variant == 0:
				canvas.draw_rect(Rect2(p + Vector2(-11, 9), Vector2(22, 4)), trim)
				canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 9), p + Vector2(0, -12), p + Vector2(8, 9)]), accent)
				canvas.draw_line(p + Vector2(-4, 1), p + Vector2(4, 1), wall, 3)
			elif variant == 1:
				for y in [-4, 4]:
					canvas.draw_rect(Rect2(p + Vector2(-14, y), Vector2(28, 6)), Color("#96724b"))
				for x in [-10, 10]:
					canvas.draw_line(p + Vector2(x, -7), p + Vector2(x, 13), trim, 3)
			else:
				canvas.draw_rect(Rect2(p + Vector2(-15, -5), Vector2(30, 9)), wall)
				for x in [-10, 0, 10]:
					canvas.draw_line(p + Vector2(x - 3, 3), p + Vector2(x + 3, -4), accent, 3)
				for x in [-11, 11]:
					canvas.draw_line(p + Vector2(x, 4), p + Vector2(x, 13), trim, 3)
		Motif.CIRCUS:
			if variant == 0:
				canvas.draw_rect(Rect2(p + Vector2(-13, -1), Vector2(26, 18)), wall)
				for x in [-10, 0, 10]:
					canvas.draw_rect(Rect2(p + Vector2(x - 2, 0), Vector2(5, 17)), trim)
				canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(-17, 0), p + Vector2(0, -18), p + Vector2(17, 0)]), trim)
				canvas.draw_rect(Rect2(p + Vector2(-3, 7), Vector2(6, 10)), background)
			elif variant == 1:
				canvas.draw_line(p + Vector2(-18, -7), p + Vector2(18, -7), accent, 1)
				for x in [-12, 0, 12]:
					canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(x-4,-7), p + Vector2(x+4,-7), p + Vector2(x,3)]), wall if x == 0 else trim)
			else:
				canvas.draw_rect(Rect2(p + Vector2(-11, 0), Vector2(22, 12)), trim)
				canvas.draw_rect(Rect2(p + Vector2(-13, -4), Vector2(26, 5)), accent)
				canvas.draw_circle(p + Vector2(0, -11), 6, wall)
		Motif.PARK:
			canvas.draw_rect(Rect2(p+Vector2(-2,0),Vector2(4,15)),trim)
			canvas.draw_circle(p+Vector2(0,-3),12,foliage)
			canvas.draw_circle(p+Vector2(-4,-6),7,foliage.lightened(0.12))
			canvas.draw_rect(Rect2(p+Vector2(7,10),Vector2(3,3)),accent)
		Motif.COAST:
			if variant == 0:
				canvas.draw_rect(Rect2(p+Vector2(-5,-12),Vector2(10,27)),wall)
				canvas.draw_rect(Rect2(p+Vector2(-5,-1),Vector2(10,5)),accent)
				canvas.draw_rect(Rect2(p+Vector2(-7,-15),Vector2(14,5)),trim)
			else:
				for i in range(4):
					canvas.draw_line(p+Vector2(i*4-6,8),p+Vector2(i*5-8,-6-i%2*5),foliage,2)
		Motif.MILL:
			canvas.draw_rect(Rect2(p+Vector2(-7,-2),Vector2(14,16)),foliage)
			canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-10,-2),p+Vector2(0,-13),p+Vector2(10,-2)]),trim)
			canvas.draw_line(p+Vector2(-12,-12),p+Vector2(12,12),wall,3)
			canvas.draw_line(p+Vector2(12,-12),p+Vector2(-12,12),wall,3)
			canvas.draw_circle(p,3,accent)
		Motif.MOUNTAIN:
			canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-17,12),p+Vector2(-3,-15),p+Vector2(16,12)]),foliage)
			canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-8,-6),p+Vector2(-3,-15),p+Vector2(3,-6)]),wall)
			canvas.draw_line(p+Vector2(-3,-5),p+Vector2(7,10),trim,2)
		Motif.PALACE:
			canvas.draw_rect(Rect2(p+Vector2(-14,-10),Vector2(28,20)),trim)
			canvas.draw_rect(Rect2(p+Vector2(-12,-8),Vector2(24,16)),foliage)
			canvas.draw_circle(p,6,accent)
			canvas.draw_circle(p,3,wall)
		Motif.FACTORY:
			canvas.draw_circle(p,12,trim)
			for i in range(8):
				var v := Vector2.from_angle(i*TAU/8)
				canvas.draw_line(p+v*8,p+v*15,foliage,4)
			canvas.draw_circle(p,9,foliage)
			canvas.draw_circle(p,4,background)
			canvas.draw_line(p+Vector2(-18,18),p+Vector2(18,18),accent,2)
		Motif.TEMPLE:
			canvas.draw_rect(Rect2(p+Vector2(-7,-10),Vector2(14,23)),foliage)
			canvas.draw_rect(Rect2(p+Vector2(-10,-14),Vector2(20,5)),wall)
			canvas.draw_rect(Rect2(p+Vector2(-10,11),Vector2(20,4)),trim)
			canvas.draw_line(p+Vector2(-2,-7),p+Vector2(-2,7),accent,2)
		Motif.OBSERVATORY:
			if variant == 0:
				canvas.draw_circle(p,13,foliage)
				canvas.draw_rect(Rect2(p+Vector2(-13,0),Vector2(26,13)),foliage)
				canvas.draw_line(p+Vector2(-3,-11),p+Vector2(4,10),accent,2)
				canvas.draw_rect(Rect2(p+Vector2(-15,12),Vector2(30,3)),trim)
			else:
				canvas.draw_line(p+Vector2(-4,0),p+Vector2(4,0),accent,1)
				canvas.draw_line(p+Vector2(0,-4),p+Vector2(0,4),accent,1)


func _draw_concrete(canvas: Node2D, floor_points: PackedVector2Array, bounds: Rect2) -> void:
	# Thin slab joints are clipped to the floor and never create collision edges.
	for y in range(int(bounds.position.y), int(bounds.end.y), 64):
		for x in range(int(bounds.position.x), int(bounds.end.x), 80):
			for rect in [Rect2(x, y, 80, 1), Rect2(x, y, 1, 64)]:
				var joint := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
				for polygon in Geometry2D.intersect_polygons(floor_points, joint):
					canvas.draw_colored_polygon(polygon, Color(0.16, 0.18, 0.20, 0.13))
