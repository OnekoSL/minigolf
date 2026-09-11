extends SceneTree

const WORLD_IDS := ["stadtpark", "duenenkueste", "muehlental", "bergpass", "schlossgarten", "uhrwerkfabrik", "tempelruinen", "sternwarte"]
const WORLD_NAMES := ["STADTPARK", "DUENENKUESTE", "MUEHLENTAL", "BERGPASS", "SCHLOSSGARTEN", "UHRWERKFABRIK", "TEMPELRUINEN", "STERNWARTE"]
const PALETTES := [
	["203d30","397e4d","ece0b7","615d48","e5b96c","285f3b"],
	["c4b483","477e66","f5e4b3","76634b","cc7058","687e51"],
	["243e36","4b8050","dbbc88","57493b","dcb971","957350"],
	["344551","527d68","dce1cd","5a6871","d1c993","667d86"],
	["233e37","39735a","eee1c6","6c5c5c","cc9aaf","42664b"],
	["292d36","426760","d7b782","635041","e5a154","93764b"],
	["453e32","687e4e","e1cc9c","7b6547","d4a157","9b8a60"],
	["182333","355b60","c3bba3","655268","e2bf82","57627c"],
]

var waypoints: Array[Vector2] = []
var blueprints: Array[Dictionary] = []
var failed := false


func _initialize() -> void:
	var holes := HoleCatalog.new()
	var courses := CourseCatalog.new()
	var legacy := LegacyCourseFixtures.holes()
	var verified_routes: Array = []
	if FileAccess.file_exists("res://tests/world_routes.json"):
		verified_routes = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	var rows := FileAccess.get_file_as_string("res://KURSPLAN_8_WELTEN.md").split("\n")
	var themes: Array[CourseTheme] = []
	for world in range(8):
		var theme := CourseTheme.new()
		theme.theme_id = StringName(WORLD_IDS[world])
		theme.motif = world
		theme.background = Color(PALETTES[world][0])
		theme.turf = Color(PALETTES[world][1])
		theme.wall = Color(PALETTES[world][2])
		theme.trim = Color(PALETTES[world][3])
		theme.accent = Color(PALETTES[world][4])
		theme.foliage = Color(PALETTES[world][5])
		_save(theme, "res://data/themes/%s.tres" % WORLD_IDS[world])
		themes.append(theme)
		var course := CourseDefinition.new()
		course.course_id = StringName(WORLD_IDS[world]+"_course")
		course.display_name = WORLD_NAMES[world]
		if world in [0,2,5]:
			course.best_score_revision = 3
		elif world == 6:
			course.best_score_revision = 2
		courses.courses.append(course)
	for line in rows:
		if not line.begins_with("| K") or line.length() < 8 or line[4] != "-":
			continue
		var cells := line.split("|")
		var key := cells[1].strip_edges()
		var world := int(key.substr(1,1))-1
		var number := int(key.substr(3,2))
		var source := cells[5].strip_edges().replace("`", "")
		waypoints.clear()
		var hole: HoleDefinition
		var rebuilt := source == "Neu" or source.begins_with("labyrinth_nine_") or source == "arrow_armageddon_09" or (world == 0 and number in [4,6])
		if rebuilt:
			hole = _build(world, number)
			hole.hole_id = StringName("%s_%02d" % [WORLD_IDS[world],number]) if source == "Neu" else StringName(source)
		else:
			hole = legacy.get_hole(StringName(source)).duplicate(true) as HoleDefinition
		hole.display_name = cells[2].strip_edges().to_upper().replace("Ä","AE").replace("Ö","OE").replace("Ü","UE").replace("ẞ","SS").replace("ß","SS")
		hole.theme = themes[world]
		hole.garden_presentation = false
		for route in verified_routes:
			if route.id == String(hole.hole_id):
				hole.par = int(route.par)
		var path := "res://data/holes/%s.tres" % hole.hole_id
		if hole.hole_id == &"reference_01":
			path = "res://data/holes/reference_hole_01.tres"
		_save(hole, path, legacy.get_hole(StringName(source)).resource_path if not rebuilt else "")
		holes.holes.append(hole)
		courses.courses[world].hole_ids.append(hole.hole_id)
		var coordinates: Array = []
		for point in waypoints:
			coordinates.append([point.x,point.y])
		blueprints.append({"key":key,"id":String(hole.hole_id),"source":source,"rebuilt":rebuilt,"task":cells[3].strip_edges(),"risk":cells[4].strip_edges(),"waypoints":coordinates,"par":hole.par,"tee":[hole.tee_position.x,hole.tee_position.y],"cup":[hole.hole_position.x,hole.hole_position.y]})
	for definition in legacy.holes:
		if not definition.is_course_hole():
			holes.holes.append(load("res://data/holes/%s.tres" % definition.hole_id) as HoleDefinition)
	for course in courses.courses:
		_save(course,"res://data/%s.tres" % course.course_id)
	_save(holes,"res://data/holes/hole_catalog.tres")
	_save(courses,"res://data/course_catalog.tres")
	var blueprint_file := FileAccess.open("res://data/world_blueprints.json",FileAccess.WRITE)
	blueprint_file.store_string(JSON.stringify(blueprints,"\t")+"\n")
	print("Acht Welten: %d Kurse, %d Bahnen, %d Bahnplaene" % [courses.courses.size(),holes.holes.size(),blueprints.size()])
	quit(1 if failed else 0)


func _build(world: int, number: int) -> HoleDefinition:
	match world:
		0:
			match number:
				4: return _pavilion_slope()
				6: return _park_spiral()
				7:
					var h := _elbow()
					h.lane_outline.points = PackedVector2Array([Vector2(184,56),Vector2(408,56),Vector2(440,88),Vector2(440,216),Vector2(600,216),Vector2(600,296),Vector2(392,296),Vector2(360,264),Vector2(360,136),Vector2(184,136)])
					return h
				8: return _island(false)
				9: return _curve(true)
		1:
			match number:
				1:
					var h := _straight()
					_surface(h,Rect2(344,136,48,80),false)
					return h
				3:
					var h := _chambers([232.0,120.0])
					_surface(h,Rect2(440,264,144,48),true)
					return h
				4:
					var h := _straight()
					_arrows(h,Rect2i(312,136,48,80),2,0)
					_surface(h,Rect2(392,136,48,80),false)
					return h
				5:
					var h := _island(true)
					_surface(h,Rect2(344,264,112,48),true)
					return h
				8:
					var h := _elbow()
					_surface(h,Rect2(280,56,48,80),false)
					_surface(h,Rect2(456,272,128,24),true)
					return h
				9:
					var h := _u()
					_surface(h,Rect2(184,152,96,32),false)
					_arrows(h,Rect2i(344,216,48,80),2,0)
					_surface(h,Rect2(504,168,24,48),true)
					return h
		2:
			match number:
				1:
					var h := _compact_machines([0])
					var second := h.obstacles[0].duplicate(true) as ObstacleDefinition
					second.position = Vector2(456,160)
					second.blade_size = Vector2(32,8)
					second.seconds_per_revolution = 8.0
					h.obstacles.append(second)
					waypoints = [Vector2(408,176),h.hole_position]
					return h
				2: return _machines([1])
				3: return _machines([2])
				4:
					var h := _curve(false)
					_surface(h,Rect2(400,248,48,32),true)
					return h
				6:
					var h := _curve(false)
					_gate(h,Vector2(288,112),true)
					return h
				8: return _compact_machines([2,0])
				9: return _compact_machines([0,1],true)
		3:
			match number:
				5: return _elbow()
				8:
					var h := _straight()
					_arrows(h,Rect2i(328,136,16,80),6,2)
					_arrows(h,Rect2i(344,136,16,80),6,1)
					_arrows(h,Rect2i(360,136,16,80),6,0)
					h.hole_position = Vector2(440,176)
					waypoints = [h.hole_position]
					return h
				9:
					var h := _u()
					_arrows(h,Rect2i(184,152,96,16),0,1)
					_arrows(h,Rect2i(184,168,96,16),4,0)
					_arrows(h,Rect2i(344,216,32,80),4,0)
					_arrows(h,Rect2i(504,136,96,32),0,0)
					return h
		4:
			match number:
				1: return _island(true)
				5: return _elbow()
				6: return _chambers([248.0,104.0])
				7:
					var h := _chambers([232.0,120.0])
					# The closed diagonal islands shape the approach to each opening.
					_diamond(h,Vector2(272,128),32)
					_diamond(h,Vector2(544,208),32)
					waypoints = [Vector2(232,232),Vector2(392,232),Vector2(392,120),Vector2(568,120),Vector2(584,248)]
					h.hole_position = Vector2(584,248)
					return h
				9:
					var h := _curve(true)
					_circle(h,Vector2(408,264),12)
					return h
		5:
			match number:
				1: return _machines([1])
				2: return _compact_machines([0])
				3: return _vertical_wippe()
				4: return _elbow()
				5: return _compact_machines([2,1,0])
				6: return _machines([1,1,1])
				7: return _compact_machines([0,1,2],true)
				8:
					var h := _compact_machines([0])
					_arrows(h,Rect2i(440,136,32,80),2,0)
					return h
				9: return _gear_crossing()
		6:
			match number:
				1: return _tunnels(1)
				2:
					var h := _tunnels(1)
					_circle(h,Vector2(280,144),12)
					_circle(h,Vector2(312,208),12)
					return h
				3: return _tunnels(1,true)
				4: return _curve(false)
				6: return _tunnels(2)
				7:
					var h := _tunnels(1,true)
					_surface(h,Rect2(472,216,32,96),true)
					waypoints.insert(waypoints.size()-1,Vector2(552,176))
					return h
				8:
					var h := _tunnels(1)
					h.lane_outline.points = PackedVector2Array([Vector2(184,136),Vector2(344,136),Vector2(344,56),Vector2(600,56),Vector2(600,312),Vector2(344,312),Vector2(344,216),Vector2(184,216)])
					_rotor(h,Vector2(280,188))
					h.obstacles.back().blade_size = Vector2(40,8)
					h.obstacles.back().start_rotation_degrees = 0.0
					return h
				9: return _tunnels(2,true)
		7:
			match number:
				1: return _cannons(1,false)
				2: return _cannons(1,true)
				7: return _cannons(2,false)
				8:
					var h := _chambers([232.0,120.0])
					_arrows(h,Rect2i(256,56,32,256),2,0)
					_arrows(h,Rect2i(392,56,32,256),0,0)
					_arrows(h,Rect2i(520,56,32,256),6,1)
					return h
				9:
					var h := _cannons(1,true)
					_arrows(h,Rect2i(504,136,32,80),2,0)
					return h
	push_error("Fehlender Bauplan %d/%d" % [world,number])
	failed = true
	return _straight()


func _lane(points: Array, tee: Vector2, cup: Vector2, route: Array[Vector2], width := 448) -> HoleDefinition:
	var h := HoleDefinition.new()
	h.lane_outline = LaneOutlineDefinition.new()
	h.lane_outline.points = PackedVector2Array(points)
	h.lane_outline.use_normalized_walls = true
	h.tee_position = tee
	h.hole_position = cup
	h.initial_aim_offset = (route[0]-tee).normalized()*64
	h.course_rect = Rect2(176,16,width,328)
	h.camera_center_bounds = Rect2(320,180,maxi(0,width-456),0)
	waypoints.assign(route)
	h.par = route.size()+1
	return h


func _straight() -> HoleDefinition:
	return _lane([Vector2(184,136),Vector2(600,136),Vector2(600,216),Vector2(184,216)],Vector2(224,176),Vector2(568,176),[Vector2(568,176)])


func _pavilion_slope() -> HoleDefinition:
	var h := LegacyCourseFixtures.holes().get_hole(&"classic_nine_04").duplicate(true) as HoleDefinition
	var arc := h.lane_outline.boundary_arcs[0]
	var circle := arc.get_arc_centerline()
	for index in range(circle.size()):
		circle[index] += arc.center
	for index in range(1,23):
		circle.append(arc.center+Vector2.from_angle(deg_to_rad(135.0+index*90.0/23.0))*arc.radius)
	var floor_regions := Geometry2D.intersect_polygons(circle,h.lane_outline.get_floor_points())
	for y in range(64,288,16):
		for x in range(352,576,16):
			var square := PackedVector2Array([Vector2(x,y),Vector2(x+16,y),Vector2(x+16,y+16),Vector2(x,y+16)])
			for floor_region in floor_regions:
				for polygon in Geometry2D.intersect_polygons(square,floor_region):
					if Geometry2D.triangulate_polygon(polygon).is_empty(): continue
					var tile := ArrowTileDefinition.new()
					tile.grid_cell = Vector2i(x/16,y/16)
					tile.direction = SurfaceZone.SlopeDirection.LEFT
					tile.slope_grade = SurfaceZone.SlopeGrade.STEEP
					if polygon.size() != 4 or not (polygon.has(square[0]) and polygon.has(square[1]) and polygon.has(square[2]) and polygon.has(square[3])):
						for point in polygon:
							tile.clip_polygon.append(point-Vector2(x,y))
					h.arrow_tiles.append(tile)
	waypoints = [h.hole_position]
	return h


func _park_spiral() -> HoleDefinition:
	var corners := [Vector2(200,312),Vector2(200,56),Vector2(584,56),Vector2(584,312),Vector2(280,312),Vector2(280,152),Vector2(424,152),Vector2(424,200),Vector2(328,200),Vector2(328,264),Vector2(536,264),Vector2(536,104),Vector2(248,104),Vector2(248,312)]
	var h := _lane(corners,Vector2(224,280),Vector2(400,176),[Vector2(240,88),Vector2(552,88),Vector2(552,280),Vector2(312,280),Vector2(312,184),Vector2(400,176)])
	var points := PackedVector2Array()
	for index in range(corners.size()):
		if index in [0,6,7,13]:
			points.append(corners[index])
			continue
		var radius := 64.0 if index in [1,2,3,4,5] else 16.0
		var before: Vector2 = (corners[index-1]-corners[index]).normalized()
		var after: Vector2 = (corners[(index+1)%corners.size()]-corners[index]).normalized()
		var start: Vector2 = corners[index]+before*radius
		var end: Vector2 = corners[index]+after*radius
		var arc := WallDefinition.new()
		arc.wall_type = WallDefinition.WallType.ARC
		arc.center = corners[index]+(before+after)*radius
		arc.radius = radius
		arc.thickness = 4
		arc.arc_start_degrees = rad_to_deg((start-arc.center).angle())
		arc.arc_sweep_degrees = rad_to_deg((start-arc.center).angle_to(end-arc.center))
		arc.arc_segments = 24
		h.lane_outline.boundary_arcs.append(arc)
		points.append(start)
		points.append(end)
	h.lane_outline.points = points
	return h


func _elbow() -> HoleDefinition:
	return _lane([Vector2(184,56),Vector2(440,56),Vector2(440,216),Vector2(600,216),Vector2(600,296),Vector2(360,296),Vector2(360,136),Vector2(184,136)],Vector2(224,96),Vector2(568,256),[Vector2(400,96),Vector2(400,256),Vector2(568,256)])


func _u() -> HoleDefinition:
	return _lane([Vector2(184,56),Vector2(280,56),Vector2(280,216),Vector2(504,216),Vector2(504,56),Vector2(600,56),Vector2(600,296),Vector2(184,296)],Vector2(232,96),Vector2(552,96),[Vector2(232,256),Vector2(552,256),Vector2(552,96)])


func _curve(finale: bool) -> HoleDefinition:
	var h := _lane([Vector2(240,56),Vector2(320,56),Vector2(320,136),Vector2(480,136),Vector2(480,56),Vector2(560,56),Vector2(560,136),Vector2(240,136)],Vector2(280,88),Vector2(520,88),[Vector2(320,232),Vector2(480,232),Vector2(520,88)])
	for radius in [80,160]:
		var arc := WallDefinition.new()
		arc.wall_type = WallDefinition.WallType.ARC
		arc.center = Vector2(400,136)
		arc.radius = radius
		arc.thickness = 4
		arc.arc_start_degrees = 0
		arc.arc_sweep_degrees = 180
		arc.arc_segments = 48
		h.lane_outline.boundary_arcs.append(arc)
	if finale:
		h.hole_position = Vector2(536,80)
		waypoints[-1] = h.hole_position
	# Align the straight arc anchors with cardinal wall cell centres.
	for i in range(h.lane_outline.points.size()):
		h.lane_outline.points[i].x += 8
	for arc in h.lane_outline.boundary_arcs:
		arc.center.x += 8
	h.tee_position.x += 8
	h.hole_position.x += 8
	for i in range(waypoints.size()):
		waypoints[i].x += 8
	h.par = 4
	return h


func _island(round_island: bool) -> HoleDefinition:
	var h := _lane([Vector2(184,56),Vector2(600,56),Vector2(600,312),Vector2(184,312)],Vector2(232,184),Vector2(552,184),[Vector2(296,96),Vector2(496,96),Vector2(552,184)])
	if round_island:
		_circle(h,Vector2(392,200),54)
	else:
		_wall_line(h,Vector2(344,152),Vector2(456,152))
		_wall_line(h,Vector2(456,152),Vector2(456,248))
		_wall_line(h,Vector2(456,248),Vector2(344,248))
		_wall_line(h,Vector2(344,248),Vector2(344,152))
	return h


func _chambers(openings: Array) -> HoleDefinition:
	var h := _lane([Vector2(184,56),Vector2(600,56),Vector2(600,312),Vector2(184,312)],Vector2(232,104),Vector2(568,240),[Vector2(280,openings[0]),Vector2(392,openings[0]),Vector2(392,openings[1]),Vector2(536,openings[1]),Vector2(568,240)])
	for i in range(2):
		var x := 328+i*144
		_wall_line(h,Vector2(x,56),Vector2(x,openings[i]-48))
		_wall_line(h,Vector2(x,openings[i]+48),Vector2(x,312))
	h.par = 5
	return h


func _gear_crossing() -> HoleDefinition:
	var h := _lane([Vector2(184,136),Vector2(312,136),Vector2(360,88),Vector2(360,24),Vector2(440,24),Vector2(440,88),Vector2(488,136),Vector2(616,136),Vector2(616,216),Vector2(488,216),Vector2(440,264),Vector2(440,328),Vector2(360,328),Vector2(360,264),Vector2(312,216),Vector2(184,216)],Vector2(224,176),Vector2(576,176),[Vector2(324,176),Vector2(576,176)])
	var gear := ObstacleDefinition.new()
	gear.obstacle_type = ObstacleDefinition.ObstacleType.TUNNEL_GEAR
	gear.position = Vector2(400,176)
	gear.seconds_per_revolution = 16.0
	h.obstacles.append(gear)
	return h


func _compact_machines(kinds: Array, bent := false) -> HoleDefinition:
	var h := _machines(kinds,bent)
	for obstacle in h.obstacles:
		if obstacle.obstacle_type == ObstacleDefinition.ObstacleType.ROTATING_BLADE:
			# Full sweep fits the narrow lane; the offset hub leaves a timed straight passage.
			obstacle.position.y = 188
			obstacle.blade_size = Vector2(40,8)
	return h


func _machines(kinds: Array, bent := false) -> HoleDefinition:
	var width := 448 if kinds.size() == 1 else 208*kinds.size()+128
	var end_x := 176+width-24
	var h := _lane([Vector2(184,136),Vector2(end_x,136),Vector2(end_x,216),Vector2(184,216)],Vector2(224,176),Vector2(end_x-32,176),[Vector2(end_x-32,176)],width)
	waypoints.clear()
	for i in range(kinds.size()):
		var p := Vector2(360+i*208,176)
		match kinds[i]:
			0:
				_rotor(h,p+Vector2(0,24))
			1:
				_gate(h,p,false)
			2:
				var wippe := ObstacleDefinition.new()
				wippe.obstacle_type = ObstacleDefinition.ObstacleType.SEESAW
				wippe.position = p
				wippe.seesaw_size = Vector2(96,88)
				h.obstacles.append(wippe)
		waypoints.append(p+Vector2(80,0))
	waypoints.append(h.hole_position)
	if bent:
		h.lane_outline.points = PackedVector2Array([Vector2(184,136),Vector2(end_x-80,136),Vector2(end_x-80,56),Vector2(end_x,56),Vector2(end_x,216),Vector2(184,216)])
		h.hole_position = Vector2(end_x-40,88)
		waypoints[-1] = Vector2(end_x-40,176)
		waypoints.append(h.hole_position)
	h.par = kinds.size()+2
	return h


func _vertical_wippe() -> HoleDefinition:
	var h := _lane([Vector2(312,56),Vector2(408,56),Vector2(408,312),Vector2(312,312)],Vector2(360,280),Vector2(360,88),[Vector2(360,88)])
	var wippe := ObstacleDefinition.new()
	wippe.obstacle_type = ObstacleDefinition.ObstacleType.SEESAW
	wippe.position = Vector2(360,184)
	wippe.seesaw_size = Vector2(96,104)
	wippe.start_rotation_degrees = -90
	h.obstacles.append(wippe)
	h.par = 3
	return h


func _tunnels(count: int, bent := false) -> HoleDefinition:
	var width := 448 if count == 1 else 640
	var end_x := 176+width-24
	var h := _lane([Vector2(184,56),Vector2(end_x,56),Vector2(end_x,312),Vector2(184,312)],Vector2(224,176),Vector2(end_x-32,176),[Vector2(end_x-32,176)],width)
	waypoints.clear()
	for i in range(count):
		var x := 376+i*208
		_wall_line(h,Vector2(x,56),Vector2(x,312))
		var tunnel := TunnelDefinition.new()
		tunnel.endpoint_a = Vector2(x-48,176)
		tunnel.endpoint_b = Vector2(x+48,176)
		h.tunnels.append(tunnel)
		waypoints.append(tunnel.endpoint_a)
	if bent:
		h.tee_position = Vector2(224,88)
		waypoints.push_front(Vector2(280,176))
		h.hole_position = Vector2(end_x-32,280)
	waypoints.append(h.hole_position)
	h.par = count+2
	return h


func _cannons(count: int, locked: bool) -> HoleDefinition:
	var h := _tunnels(count)
	h.tunnels.clear()
	waypoints.clear()
	for i in range(count):
		var x := 376+i*208
		var cannon := CannonDefinition.new()
		cannon.mechanism_id = StringName("cannon_%d" % i)
		cannon.position = Vector2(x-48,176)
		cannon.landing_position = Vector2(x+56,176)
		cannon.landing_velocity = Vector2(45,0)
		if locked:
			cannon.required_trigger_id = &"start_switch"
			var trigger := TriggerDefinition.new()
			trigger.trigger_id = &"start_switch"
			trigger.position = Vector2(272,176)
			trigger.size = Vector2(24,80)
			trigger.target_ids = [cannon.mechanism_id]
			h.triggers.append(trigger)
			h.lane_outline.points = PackedVector2Array([Vector2(184,136),Vector2(344,136),Vector2(344,56),Vector2(600,56),Vector2(600,312),Vector2(344,312),Vector2(344,216),Vector2(184,216)])
		h.cannons.append(cannon)
		waypoints.append(cannon.position)
	waypoints.append(h.hole_position)
	h.par = count+2
	return h


func _gate(h: HoleDefinition, p: Vector2, vertical_lane: bool) -> void:
	var gate := ObstacleDefinition.new()
	gate.obstacle_type = ObstacleDefinition.ObstacleType.SLIDING_GATE
	gate.position = p
	gate.gate_size = Vector2(8,88) if not vertical_lane else Vector2(88,8)
	gate.open_offset = Vector2(0,-104) if not vertical_lane else Vector2(-104,0)
	gate.cycle_seconds = 4.8
	gate.open_hold_seconds = 2.4
	gate.transition_seconds = 0.4
	h.obstacles.append(gate)


func _rotor(h: HoleDefinition, p: Vector2) -> void:
	var rotor := ObstacleDefinition.new()
	rotor.position = p
	rotor.blade_size = Vector2(128,8)
	rotor.seconds_per_revolution = 5.0
	rotor.minimum_kick_speed = 35
	h.obstacles.append(rotor)


func _circle(h: HoleDefinition, p: Vector2, radius: float) -> void:
	var circle := WallDefinition.new()
	circle.wall_type = WallDefinition.WallType.CIRCLE
	circle.center = p
	circle.radius = radius
	h.walls.append(circle)


func _diamond(h: HoleDefinition, p: Vector2, radius: int) -> void:
	# Diagonal tiles use grid corners, unlike cardinal cell-centre walls.
	for step in range(radius/16):
		for side in range(4):
			var tile := WallTileDefinition.new()
			var corners := [p+Vector2(step*16,-radius+step*16),p+Vector2(radius-step*16-16,step*16),p+Vector2(-step*16-16,radius-step*16-16),p+Vector2(-radius+step*16,-step*16-16)]
			tile.grid_cell = Vector2i(corners[side]/16)
			tile.variant = WallTileDefinition.Variant.DIAGONAL_DOWN if side%2 == 0 else WallTileDefinition.Variant.DIAGONAL_UP
			h.wall_tiles.append(tile)


func _wall_line(h: HoleDefinition, a: Vector2, b: Vector2) -> void:
	if a.is_equal_approx(b): return
	var step := (b-a).normalized()*16
	var length := int(a.distance_to(b)/16)
	var masks: Dictionary = h.get_meta("builder_wall_masks",{})
	for i in range(length+1):
		var center := a+step*i
		var cell := Vector2i((center-Vector2(8,8))/16)
		var mask: int = masks.get(cell,0)
		if i > 0: mask |= 8 if step.x > 0 else (2 if step.x < 0 else (1 if step.y > 0 else 4))
		if i < length: mask |= 2 if step.x > 0 else (8 if step.x < 0 else (4 if step.y > 0 else 1))
		for boundary in h.lane_outline.get_normalized_wall_tiles():
			if boundary.grid_cell == cell:
				mask |= WallTileDefinition.get_cardinal_mask(boundary.variant)
		masks[cell] = mask
		var tile := WallTileDefinition.new()
		tile.grid_cell = cell
		var found := false
		for existing in h.wall_tiles:
			if existing.grid_cell == cell:
				tile = existing
				found = true
				break
		tile.variant = WallTileDefinition.variant_from_cardinal_mask(mask)
		if tile.variant < 0:
			tile.variant = WallTileDefinition.Variant.HORIZONTAL if step.x != 0 else WallTileDefinition.Variant.VERTICAL
		if not found: h.wall_tiles.append(tile)
	h.set_meta("builder_wall_masks",masks)


func _arrows(h: HoleDefinition, rect: Rect2i, direction: int, grade: int) -> void:
	for y in range(rect.position.y,rect.end.y,16):
		for x in range(rect.position.x,rect.end.x,16):
			var tile := ArrowTileDefinition.new()
			tile.grid_cell = Vector2i(x/16,y/16)
			tile.grid_offset = Vector2i(x%16,y%16)
			tile.direction = direction
			tile.slope_grade = grade
			h.arrow_tiles.append(tile)


func _surface(h: HoleDefinition, rect: Rect2, water: bool) -> void:
	var surface := SurfaceDefinition.new()
	surface.rect = rect
	surface.surface_type = SurfaceZone.SurfaceType.WATER if water else SurfaceZone.SurfaceType.SAND
	surface.deceleration = 260 if not water else 120
	h.surfaces.append(surface)


func _save(resource: Resource, path: String, original_path := "") -> void:
	if resource is HoleDefinition:
		if resource.has_meta("builder_wall_masks"): resource.remove_meta("builder_wall_masks")
		for error in resource.validate():
			push_error("%s: %s" % [path,error])
			failed = true
	resource.take_over_path(path)
	# Stage generated text before replacing existing files on Windows.
	var staged := "res://tmp/worlds/staging/"+path.trim_prefix("res://")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(staged.get_base_dir()))
	var result := OK
	if original_path.is_empty():
		result = ResourceSaver.save(resource,staged)
	else:
		# Retained geometry keeps its original external/subresource identifiers.
		var original := FileAccess.get_file_as_string(original_path)
		var marker := original.find("[resource]")
		var header := original.substr(0,marker)
		var body := original.substr(marker)
		var pattern := RegEx.new()
		pattern.compile("load_steps=(\\d+)")
		var match_steps := pattern.search(header)
		if match_steps != null:
			header = pattern.sub(header,"load_steps=%d" % (int(match_steps.get_string(1))+1))
		var theme_reference := "[ext_resource type=\"Resource\" path=\"%s\" id=\"world_theme\"]\n\n" % resource.theme.resource_path
		var first_sub := header.find("[sub_resource")
		if first_sub < 0: first_sub = header.length()
		header = header.insert(first_sub,theme_reference)
		for property in ["display_name","par","garden_presentation"]:
			pattern.compile("(?m)^%s = [^\\r\\n]*" % property)
			var value := JSON.stringify(resource.display_name) if property == "display_name" else (str(resource.par) if property == "par" else "false")
			if pattern.search(body) != null:
				body = pattern.sub(body,property+" = "+value)
			else:
				body += "\n"+property+" = "+value+"\n"
		body += "theme = ExtResource(\"world_theme\")\n"
		var file := FileAccess.open(staged,FileAccess.WRITE)
		if file == null:
			result = FileAccess.get_open_error()
		else:
			file.store_string(header+body)
	if result != OK:
		push_error("%s: %s" % [path,error_string(result)])
		failed = true
