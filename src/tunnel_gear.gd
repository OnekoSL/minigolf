class_name TunnelGear
extends MovingObstacle

const CORE_RADIUS := 64.0
const OUTER_RADIUS := 88.0
const PORT_RADIUS := 76.0
const EXIT_RADIUS := 104.0
const PORT_COUNT := 8

var seconds_per_revolution := 16.0
var links := PackedInt32Array([1,0,4,7,2,6,5,3])
var intake: Area2D
var start_rotation := 0.0


func _ready() -> void:
	start_rotation = rotation
	feedback_kind = &"windmill"
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = true
	var core := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = CORE_RADIUS
	core.shape = circle
	add_child(core)
	for index in range(PORT_COUNT):
		var tooth := CollisionPolygon2D.new()
		tooth.polygon = tooth_polygon(index)
		add_child(tooth)
	intake = Area2D.new()
	intake.collision_layer = 0
	intake.collision_mask = 1
	var shape := CollisionShape2D.new()
	var region := CircleShape2D.new()
	region.radius = OUTER_RADIUS+PrototypeBall.RADIUS
	shape.shape = region
	intake.add_child(shape)
	add_child(intake)


static func tooth_polygon(index: int) -> PackedVector2Array:
	var angle := (index+0.5)*TAU/PORT_COUNT
	return PackedVector2Array([
		Vector2.from_angle(angle-0.22)*(CORE_RADIUS-2),
		Vector2.from_angle(angle-0.14)*OUTER_RADIUS,
		Vector2.from_angle(angle+0.14)*OUTER_RADIUS,
		Vector2.from_angle(angle+0.22)*(CORE_RADIUS-2)])


func port_position(index: int) -> Vector2:
	return global_position+Vector2.from_angle(global_rotation+index*TAU/PORT_COUNT)*PORT_RADIUS


func transfer_for(index: int) -> Dictionary:
	var angle := global_rotation+links[index]*TAU/PORT_COUNT
	var angular_speed := TAU/seconds_per_revolution
	# Keep the ball inside until its partner hole faces one of the four arms.
	var exit_angle := ceilf((angle+angular_speed*PrototypeBall.TUNNEL_DURATION)/(PI*0.5))*(PI*0.5)
	var direction := Vector2.from_angle(exit_angle).snapped(Vector2.ONE)
	return {"hole":global_position+direction*PORT_RADIUS,"direction":direction,"duration":(exit_angle-angle)/angular_speed}


func _physics_process(delta: float) -> void:
	rotation += TAU*delta/seconds_per_revolution
	for body in intake.get_overlapping_bodies():
		if not body is PrototypeBall: continue
		var ball := body as PrototypeBall
		if ball.is_tunnel_sequence_active(): continue
		if not ball.moving:
			_wake_ball_at_tooth(ball)
		if not ball.moving: continue
		for index in range(PORT_COUNT):
			var entry := port_position(index)
			if ball.global_position.distance_to(entry)>TunnelDefinition.HOLE_RADIUS: continue
			var transfer := transfer_for(index)
			ball.start_directed_tunnel(entry,transfer.hole,transfer.direction,EXIT_RADIUS-PORT_RADIUS,transfer.duration)
			break


func _wake_ball_at_tooth(ball: PrototypeBall) -> void:
	var point := to_local(ball.global_position)
	for index in range(PORT_COUNT):
		var polygon := tooth_polygon(index)
		var closest := Vector2.INF
		var distance := INF
		for edge in range(polygon.size()):
			var candidate := Geometry2D.get_closest_point_to_segment(point,polygon[edge],polygon[(edge+1)%polygon.size()])
			if point.distance_squared_to(candidate)<distance:
				distance = point.distance_squared_to(candidate)
				closest = candidate
		if distance>pow(PrototypeBall.RADIUS+0.5,2): continue
		var normal := (point-closest).normalized()
		if Geometry2D.is_point_in_polygon(point,polygon): normal = -normal
		normal = normal.rotated(global_rotation)
		var surface_velocity := get_velocity_at_world_point(ball.global_position)
		if surface_velocity.dot(normal)>2:
			ball.apply_moving_obstacle_contact(surface_velocity,normal,get_impulse_multiplier(),get_minimum_kick_speed(),feedback_kind)
			return


func reset_motion() -> void:
	# Menu/restart callbacks run outside the physics step. Apply the reset now,
	# rather than letting AnimatableBody2D restore its previous physics pose.
	sync_to_physics = false
	rotation = start_rotation
	reset_physics_interpolation()
	sync_to_physics = true


func get_velocity_at_world_point(point: Vector2) -> Vector2:
	return (point-global_position).orthogonal()*TAU/seconds_per_revolution


func _draw() -> void:
	for index in range(PORT_COUNT):
		var polygon := tooth_polygon(index)
		draw_colored_polygon(polygon,Color("b99555"))
		polygon.append(polygon[0])
		draw_polyline(polygon,Color("604936"),2)
	draw_circle(Vector2.ZERO,CORE_RADIUS,Color("b99555"))
	draw_circle(Vector2.ZERO,CORE_RADIUS-5,Color("604936"),false,2)
	draw_circle(Vector2.ZERO,44,Color("796044"))
	for index in range(4):
		draw_set_transform(Vector2.ZERO,index*PI*0.5)
		draw_rect(Rect2(12,-4,39,8),Color("d7b782"))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2.ZERO,14,Color("493d36"))
	draw_circle(Vector2.ZERO,6,Color("d7b782"))
	for index in range(PORT_COUNT):
		var point := Vector2.from_angle(index*TAU/PORT_COUNT)*PORT_RADIUS
		draw_circle(point,9,Color("d7b782"))
		draw_circle(point,TunnelDefinition.HOLE_RADIUS,Color("101820"))
