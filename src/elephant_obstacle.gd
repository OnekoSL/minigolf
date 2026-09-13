class_name ElephantObstacle
extends Node2D

signal feedback(kind: StringName, point: Vector2, direction: Vector2)

# Local +Y faces the lower lane; -Y faces the return lane.
var intake_position := Vector2(0, 144)
var exit_position := Vector2(-28, -112)
var gate_size := Vector2(12, 64)
var gate_offset := Vector2(0, 76)
var intake_radius := 8.0
var exit_speed := 205.0
var transport_seconds := 1.2
var cycle_seconds := 6.0
var elapsed := 0.0
var trunk: TimedSlidingGate
var tail: TimedSlidingGate
var passenger: PrototypeBall
var sequence_elapsed := 0.0
var intake_wait := 0.0
var puff_time := 0.0
var sounded := false
var active_ball: PrototypeBall


class Limb extends TimedSlidingGate:
	var is_tail := false

	# The paired mechanism handles squeezing before either limb moves. These
	# limbs are barriers, not the kicking gates used elsewhere in the game.
	func _try_move_ball(_body: Node2D) -> void:
		pass

	func get_velocity_at_world_point(_point: Vector2) -> Vector2:
		return Vector2.ZERO

	func _draw() -> void:
		var rect := Rect2(-gate_size * 0.5, gate_size)
		draw_rect(rect, Color("444958"))
		draw_rect(rect.grow(-2), Color("9299aa") if not is_tail else Color("777e90"))
		for y in range(int(rect.position.y) + 8, int(rect.end.y) - 4, 10):
			draw_line(Vector2(rect.position.x + 2, y), Vector2(rect.end.x - 2, y), Color("636b80"), 2)
		if is_tail:
			draw_rect(Rect2(-2, rect.position.y, 4, 9), Color("34394b"))
		else:
			draw_rect(Rect2(-5, rect.end.y - 6, 10, 6), Color("c5c9ce"))
			draw_rect(Rect2(-4, rect.end.y - 4, 8, 4), Color("262c39"))


func _ready() -> void:
	process_physics_priority = -12
	trunk = _make_limb(intake_position - Vector2(0, gate_size.y * 0.5), -gate_offset, false)
	tail = _make_limb(Vector2(0, exit_position.y), gate_offset, true)
	reset_motion()


func _make_limb(center: Vector2, offset: Vector2, rear: bool) -> TimedSlidingGate:
	var limb := Limb.new()
	limb.is_tail = rear
	limb.position = center
	limb.gate_size = Vector2(4.0, gate_size.y) if rear else gate_size
	limb.open_offset = offset
	limb.cycle_seconds = cycle_seconds
	limb.transition_seconds = cycle_seconds / 6.0
	limb.open_hold_seconds = cycle_seconds / 3.0
	limb.phase_offset_seconds = cycle_seconds * (0.5 if rear else 1.0) - cycle_seconds / 6.0
	add_child(limb)
	# Parent advances the paired limbs before balls, including override recovery.
	limb.set_physics_process(false)
	return limb


func _physics_process(delta: float) -> void:
	advance_motion(delta)


func bind_ball(ball: PrototypeBall) -> void:
	active_ball = ball


func advance_motion(delta: float) -> void:
	if delta <= 0.0:
		return
	# Claim a ball in the tip-to-wall gap before the closing trunk touches it.
	if is_instance_valid(active_ball):
		try_capture_ball(active_ball)
	elapsed += delta
	trunk.advance_motion(delta)
	if is_instance_valid(active_ball):
		try_capture_ball(active_ball)
	var previous_tail := tail.position
	tail.advance_motion(delta)
	puff_time = maxf(0.0, puff_time - delta)
	if is_instance_valid(passenger):
		if not passenger.is_tunnel_sequence_active():
			passenger = null
		else:
			sequence_elapsed += delta
			var progress := maxf(0.0, sequence_elapsed - intake_wait)
			if progress > 0.0 and not sounded:
				sounded = true
				feedback.emit(&"elephant_sniff", trunk.to_global(Vector2(0, gate_size.y * 0.5)), Vector2.UP.rotated(global_rotation))
			if progress > 0.0:
				var lift := clampf(progress / (transport_seconds * 0.65), 0.0, 1.0)
				tail.position = tail.closed_position + tail.open_offset * maxf(lift, _tail_openness())
				if progress >= transport_seconds - PrototypeBall.TUNNEL_DURATION * 0.5 and puff_time <= 0.0:
					puff_time = 0.8
					feedback.emit(&"elephant_puff", to_global(exit_position), Vector2.LEFT.rotated(global_rotation))
	# The tail may close behind a ball, but must never squeeze it into the
	# upper boundary. Hold the tip on the safe side until the ball moves away.
	if is_instance_valid(active_ball) and active_ball.visible and not active_ball.is_tunnel_sequence_active() and not active_ball.is_cannon_sequence_active():
		var point := to_local(active_ball.global_position)
		var half_width := tail.gate_size.x * 0.5 + PrototypeBall.RADIUS + 1.0
		var wall_y := exit_position.y - gate_size.y * 0.5 + WallTileDefinition.THICKNESS * 0.5
		if absf(point.x - tail.closed_position.x) <= half_width and point.y >= wall_y and point.y <= previous_tail.y - gate_size.y * 0.5 + PrototypeBall.RADIUS:
			tail.position.y = maxf(tail.position.y, point.y + PrototypeBall.RADIUS + gate_size.y * 0.5 + 1.0)
	# Return smoothly to the cycle after the release override.
	tail.position = previous_tail.move_toward(tail.position, gate_offset.length() * delta / (cycle_seconds / 6.0))
	tail.linear_velocity = (tail.position - previous_tail) / maxf(delta, 0.0001)
	queue_redraw()


func _tail_openness() -> float:
	return TimedSlidingGate.openness_at_time(tail.elapsed_seconds + tail.phase_offset_seconds, cycle_seconds, cycle_seconds / 6.0, cycle_seconds / 3.0)


# The opening is the actual lower end of the trunk. The valid gap is
# clipped to the inside of the lane, including the ball radius at the wall.
func intake_gap_contains(point: Vector2, resting: bool = false) -> bool:
	var tip_y := trunk.position.y + gate_size.y * 0.5
	var wall_half := WallTileDefinition.THICKNESS * 0.5
	var lane_top := intake_position.y - gate_size.y + wall_half
	var lane_bottom := intake_position.y - wall_half
	# A fully lifted trunk permits the regular rolling route. A ball parked
	# beneath it is still taken in, without requiring another shot.
	if tip_y < lane_top and not resting:
		return false
	return absf(point.x - intake_position.x) <= intake_radius + PrototypeBall.RADIUS \
		and point.y >= maxf(lane_top + PrototypeBall.RADIUS, tip_y - PrototypeBall.RADIUS - 1.0) \
		and point.y <= lane_bottom - PrototypeBall.RADIUS + 0.1


func try_capture_resting_ball(ball: PrototypeBall) -> bool:
	return try_capture_ball(ball)


func try_capture_ball(ball: PrototypeBall) -> bool:
	if is_instance_valid(passenger) or ball.current_stroke_count < 1 or not ball.visible or ball.is_tunnel_sequence_active() or ball.is_cannon_sequence_active():
		return false
	var point := to_local(ball.global_position)
	if not intake_gap_contains(point, not ball.moving):
		return false
	intake_wait = 0.0
	var deviation := clampf((point.x - intake_position.x) / intake_radius, -1.0, 1.0)
	var direction := Vector2.LEFT.rotated(deg_to_rad(deviation * 8.0) + global_rotation)
	if not ball.start_mechanism_transport(ball.global_position, to_global(exit_position), direction * exit_speed, 0.0, transport_seconds):
		return false
	passenger = ball
	sequence_elapsed = 0.0
	sounded = false
	return true


func reset_motion() -> void:
	if is_instance_valid(passenger) and passenger.is_tunnel_sequence_active():
		passenger.reset_to(passenger.shot_origin)
	elapsed = 0.0
	passenger = null
	sequence_elapsed = 0.0
	puff_time = 0.0
	sounded = false
	if trunk != null:
		trunk.reset_motion()
		tail.reset_motion()
	queue_redraw()


func _draw() -> void:
	# Chunky top-down elephant: rear above, head and trunk below.
	var breathing := 1.0 if is_instance_valid(passenger) and sequence_elapsed > intake_wait else 0.0
	draw_rect(Rect2(-43, -73, 90, 153), Color("171d2a", 0.3))
	for x in [-36, 24]:
		for y in [-55, 34]:
			draw_rect(Rect2(x, y, 18, 27), Color("525a6b"))
			draw_rect(Rect2(x + 2, y + 19, 14, 6), Color("c0b9ac"))
	draw_colored_polygon(PackedVector2Array([Vector2(-20,-72),Vector2(20,-72),Vector2(20,-66),Vector2(34,-66),Vector2(34,-54),Vector2(40+breathing*2,-54),Vector2(40+breathing*2,34),Vector2(32,34),Vector2(32,54),Vector2(-32,54),Vector2(-32,34),Vector2(-40-breathing*2,34),Vector2(-40-breathing*2,-54),Vector2(-34,-54),Vector2(-34,-66),Vector2(-20,-66)]), Color("626b7e"))
	draw_rect(Rect2(-32, -54, 64, 104), Color("929aaa"))
	draw_rect(Rect2(-22,-65,44,13), Color("929aaa"))
	draw_rect(Rect2(-25, -57, 44, 98), Color("a7afbc"))
	# Circus saddle and gold fringe, ears and expressive face.
	draw_rect(Rect2(-31, -44, 62, 59), Color("9e3445"))
	draw_rect(Rect2(-25, -38, 50, 47), Color("d05257"))
	for x in range(-28, 30, 8):
		draw_rect(Rect2(x, 13, 4, 7), Color("f0ce83"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-31), Vector2(16,-13), Vector2(0,4), Vector2(-16,-13)]), Color("f0ce83"))
	for side in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([Vector2(side*20,28),Vector2(side*40,26),Vector2(side*52,38),Vector2(side*52,60),Vector2(side*40,74),Vector2(side*22,66)]), Color("666f83"))
		draw_rect(Rect2(side * 36 - 9, 37, 18, 26), Color("b2a0ab"))
	draw_rect(Rect2(-24, 35, 48, 44), Color("949dac"))
	draw_rect(Rect2(-18, 40, 32, 27), Color("adb5c1"))
	for x in [-17, 12]:
		draw_rect(Rect2(x, 60, 6, 7), Color("f8ecc8"))
		draw_rect(Rect2(x + 1, 63, 3, 4), Color("202533"))
	for x in [-21, 17]:
		draw_rect(Rect2(x, 73, 4, 11), Color("f8ecc8"))
	if puff_time > 0.0:
		for i in range(4):
			var drift := (0.8 - puff_time) * 32.0
			draw_rect(Rect2(exit_position + Vector2(-drift - i * 6, -8 + i * 5), Vector2(7, 6)), Color("dcccaa", puff_time * 0.65))
