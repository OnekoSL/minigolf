class_name CourseTheme
extends Resource

enum Motif { PARK, COAST, MILL, MOUNTAIN, PALACE, FACTORY, TEMPLE, OBSERVATORY }

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
	# Texture is clipped to the same curved floor used by physics.
	for x in range(int(bounds.position.x), int(bounds.end.x), 48):
		var stripe := PackedVector2Array([Vector2(x,bounds.position.y), Vector2(x+24,bounds.position.y), Vector2(x+24,bounds.end.y), Vector2(x,bounds.end.y)])
		for polygon in Geometry2D.intersect_polygons(floor_points, stripe):
			canvas.draw_colored_polygon(polygon, Color(accent, 0.035))
	for y in range(int(bounds.position.y)+16, int(bounds.end.y)-20, 48):
		for x in range(int(bounds.position.x)+24, int(bounds.end.x)-20, 48):
			if (x/48+y/48)%3 == 1:
				continue
			var point := Vector2(x,y)
			if not _has_clearance(point, floor_points, hole):
				continue
			_draw_motif(canvas, point, (x / 48 + y / 48) % 3)


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
