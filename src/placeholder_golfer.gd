class_name PlaceholderGolfer
extends Control

var shot_state := ShotController.ShotState.AIMING
var reaction := ""
var _time := 0.0
var _state_time := 0.0
var _reaction_left := 0.0
var _perfect_left := 0.0
var palette_id := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_state_time += delta
	_perfect_left = maxf(0.0, _perfect_left - delta)
	if _reaction_left > 0.0:
		_reaction_left -= delta
		if _reaction_left <= 0.0:
			reaction = ""
	queue_redraw()


func set_shot_state(value: int) -> void:
	if shot_state == value:
		return
	shot_state = value
	_state_time = 0.0


func play_reaction(kind: String) -> void:
	if kind == "perfect_swing":
		reaction = "swing"
		_reaction_left = 0.35
		_perfect_left = 0.25
	else:
		reaction = kind
		_reaction_left = 1.25 if kind in ["success", "frustration"] else 0.35


func set_palette(value: int) -> void:
	palette_id = clampi(value, 0, 3)
	queue_redraw()


func _draw() -> void:
	# The ball lies centrally in front of the golfer. The club comes from the
	# left and follows through to the course on the right.
	var center_x := 40.0
	var bob := sin(_time * 3.0) * 0.7
	var stance := 9.0
	var crouch := 0.0
	if shot_state == ShotController.ShotState.POWER:
		bob = sin(_time * 6.0) * 0.55
		stance = 11.0
		crouch = 1.0
	elif shot_state == ShotController.ShotState.ACCURACY:
		bob = sin(_time * 12.0) * 0.2
		stance = 10.0
		crouch = 2.0
	elif shot_state == ShotController.ShotState.ARMED:
		bob = -1.0
		stance = 12.0
	elif shot_state == ShotController.ShotState.SWINGING:
		bob = lerpf(-1.0, 1.0, clampf(_state_time / 0.10, 0.0, 1.0))
		stance = 12.0
	elif shot_state == ShotController.ShotState.BALL_MOVING:
		bob = sin(minf(_state_time, 0.4) * 8.0) * 0.35
	if reaction == "success":
		bob = -absf(sin(_time * 8.0)) * 5.0
		stance = 12.0
	elif reaction == "frustration":
		bob = 3.0
		stance = 7.0
		crouch = 2.0

	var hip := Vector2(center_x, 50 + bob + crouch)
	var shoulder := Vector2(center_x, 31 + bob + crouch)
	var head := Vector2(center_x, 18 + bob + crouch)
	var skin := Color("#d8a16f")
	var shirts := [Color("#49d6cf"), Color("#ee66cf"), Color("#f0c45b"), Color("#9b7bea")]
	var pants_colors := [Color("#293c5b"), Color("#54294f"), Color("#5b4329"), Color("#30295b")]
	var shirt: Color = shirts[palette_id]
	var pants: Color = pants_colors[palette_id]
	var outline := Color("#18202a")
	if _perfect_left > 0.0:
		var glow_alpha := clampf(_perfect_left / 0.25, 0.0, 1.0)
		draw_circle(head, 12.0, Color(1.0, 0.92, 0.48, glow_alpha * 0.22))
		draw_line(head + Vector2(-14, 0), head + Vector2(-10, 0), Color(1.0, 0.95, 0.62, glow_alpha), 1.0)
		draw_line(head + Vector2(10, 0), head + Vector2(14, 0), Color(1.0, 0.95, 0.62, glow_alpha), 1.0)

	# Symmetric legs and body keep the figure clearly front-facing.
	draw_line(hip, hip + Vector2(-stance, 17), outline, 6.0)
	draw_line(hip, hip + Vector2(stance, 17), outline, 6.0)
	draw_line(hip, hip + Vector2(-stance, 17), pants, 3.0)
	draw_line(hip, hip + Vector2(stance, 17), pants, 3.0)
	draw_line(shoulder, hip, outline, 12.0)
	draw_line(shoulder, hip, shirt, 8.0)

	# Frontal head, cap and face.
	draw_circle(head, 8.0, outline)
	draw_circle(head, 6.0, skin)
	draw_rect(Rect2(head + Vector2(-7, -8), Vector2(14, 4)), Color("#f0ce64"), true)
	draw_rect(Rect2(head + Vector2(-9, -5), Vector2(18, 2)), Color("#f0ce64"), true)
	draw_circle(head + Vector2(-2.5, -1), 1.0, outline)
	draw_circle(head + Vector2(2.5, -1), 1.0, outline)
	if reaction == "frustration":
		draw_line(head + Vector2(-3, 4), head + Vector2(3, 2), outline, 1.0)
	else:
		draw_line(head + Vector2(-3, 3), head + Vector2(3, 3), outline, 1.0)

	var left_shoulder := shoulder + Vector2(-5, 1)
	var right_shoulder := shoulder + Vector2(5, 1)
	var grip := Vector2(center_x + 1.0, 42 + bob + crouch)
	var address_end := Vector2(center_x, 69)
	var backswing_end := Vector2(12, 18)
	var follow_through_end := Vector2(84, 23)
	var club_end := address_end
	if reaction == "success":
		var left_hand := shoulder + Vector2(-11, -12)
		var right_hand := shoulder + Vector2(11, -12)
		_draw_arm(left_shoulder, left_hand, outline, skin)
		_draw_arm(right_shoulder, right_hand, outline, skin)
		grip = right_hand
		club_end = Vector2(75, 12)
	elif reaction == "frustration":
		grip = shoulder + Vector2(0, 17)
		club_end = grip + Vector2(1, 28)
		_draw_arm(left_shoulder, grip + Vector2(-3, 0), outline, skin)
		_draw_arm(right_shoulder, grip + Vector2(3, 0), outline, skin)
	else:
		if shot_state == ShotController.ShotState.POWER:
			club_end = address_end.lerp(Vector2(18, 27), (sin(_time * 3.0) + 1.0) * 0.5)
		elif shot_state == ShotController.ShotState.ACCURACY:
			club_end = Vector2(17 + sin(_time * 12.0), 23)
		elif shot_state == ShotController.ShotState.ARMED:
			grip += Vector2(-2, -2)
			club_end = backswing_end
		elif shot_state == ShotController.ShotState.SWINGING:
			var swing_progress := clampf(_state_time / 0.10, 0.0, 1.0)
			grip.x += swing_progress * 5.0
			club_end = backswing_end.lerp(address_end, swing_progress)
		elif shot_state == ShotController.ShotState.BALL_MOVING:
			var follow_progress := clampf(_state_time / 0.24, 0.0, 1.0)
			grip.x += 5.0 + follow_progress * 3.0
			club_end = address_end.lerp(follow_through_end, follow_progress)
		_draw_arm(left_shoulder, grip + Vector2(-2, 0), outline, skin)
		_draw_arm(right_shoulder, grip + Vector2(2, 0), outline, skin)

	draw_line(grip, club_end, Color("#d4d7d9"), 2.0)
	var club_tangent := (club_end - grip).normalized().orthogonal()
	draw_line(club_end - club_tangent * 3.0, club_end + club_tangent * 3.0, Color("#f5e1a4"), 3.0)

	# The ball waits in front of the stance, then visibly exits toward the course.
	if shot_state in [
		ShotController.ShotState.AIMING,
		ShotController.ShotState.POWER,
		ShotController.ShotState.ACCURACY,
		ShotController.ShotState.ARMED,
		ShotController.ShotState.SWINGING,
	]:
		var inset_ball := Vector2(center_x, 72)
		draw_circle(inset_ball + Vector2(1, 1), 3.5, Color(0.05, 0.08, 0.10, 0.45))
		draw_circle(inset_ball, 3.0, Color("#f5f0d7"))
		draw_circle(inset_ball + Vector2(-1, -1), 0.8, Color.WHITE)
	elif shot_state == ShotController.ShotState.BALL_MOVING and _state_time < 0.22:
		var flight_progress := clampf(_state_time / 0.22, 0.0, 1.0)
		var moving_ball := Vector2(center_x + flight_progress * 54.0, 72.0 - sin(flight_progress * PI) * 5.0)
		draw_circle(moving_ball + Vector2(1, 1), 3.5, Color(0.05, 0.08, 0.10, 0.35))
		draw_circle(moving_ball, 3.0, Color("#f5f0d7"))


func _draw_arm(from: Vector2, to: Vector2, outline: Color, skin: Color) -> void:
	draw_line(from, to, outline, 5.0)
	draw_line(from, to, skin, 2.0)
