class_name LiveRouteRunner
extends Node

signal finished(result: Dictionary)

const MAX_MOTION_TICKS := 1800

var definition: HoleDefinition
var shots: Array[RouteShot] = []
var runtime: HoleRuntime
var ball: PrototypeBall
var controller: ShotController
var _ticks := 0
var _shot_index := 0
var _wait_left := 0
var _motion_ticks := 0
var _strokes := 0
var _rolling := false
var _done := false
var _holed := false
var _trace: Array[Dictionary] = []
var _last_contact := ""
var _contact_count := 0
var _swing_tick := 0
var _contact_delays: Array[int] = []


static func play(host: Node, hole: HoleDefinition, route: Array[RouteShot]) -> Dictionary:
	var runner := LiveRouteRunner.new()
	runner.definition = hole
	runner.shots = route
	host.get_tree().root.add_child(runner)
	var result: Dictionary = await runner.finished
	runner.queue_free()
	await host.get_tree().process_frame
	return result


func _ready() -> void:
	# Observe after the production obstacles and ball have completed their tick.
	process_physics_priority = 100
	runtime = HoleRuntime.new()
	runtime.configure(definition)
	add_child(runtime)
	ball = PrototypeBall.new()
	ball.position = definition.tee_position
	add_child(ball)
	ball.configure_environment(runtime.zones, definition.hole_position, runtime.get_tunnels())
	controller = ShotController.new()
	add_child(controller)
	controller.configure(ball, definition.course_rect)
	# Only the input/timing driver is replaced. World physics runs normally.
	controller.set_process(false)
	controller.set_process_unhandled_input(false)
	controller.shot_committed.connect(_on_shot_committed)
	ball.holed.connect(func(_count): _holed = true)
	ball.hazard_entered.connect(func(kind): _finish("Gefahr: " + kind))
	ball.wall_hit.connect(func(_intensity, position, _normal, kind):
		_last_contact = "%s bei (%.2f, %.2f)" % [kind, position.x, position.y]
		_contact_count += 1
	)
	if not shots.is_empty():
		_wait_left = shots[0].wait_ticks


func _physics_process(delta: float) -> void:
	if _done:
		return
	_ticks += 1
	if _ticks == 1:
		runtime.reset_mechanisms()
		ball.reset_to(definition.tee_position)
		return
	if _ticks == 2:
		return # Allow physics-server overlaps to synchronize after reset.
	if _holed:
		_record_stop()
		_finish("")
		return
	if controller.state == ShotController.ShotState.SWINGING:
		controller.advance_swing(delta)
		return
	if _rolling:
		_motion_ticks += 1
		if _motion_ticks >= MAX_MOTION_TICKS:
			_finish("Ball kommt innerhalb von 1800 Physikticks nicht zur Ruhe")
			return
		if ball.moving:
			return
		if ball.global_position.distance_to(definition.hole_position) <= PrototypeBall.HOLE_RADIUS:
			return # Wait for the production hole-capture animation and signal.
		_record_stop()
		_rolling = false
		_shot_index += 1
		if _shot_index < shots.size():
			_wait_left = shots[_shot_index].wait_ticks
	if _shot_index >= shots.size():
		_finish("Schlagfolge beendet, Loch nicht erreicht")
		return
	if _strokes >= RoundSession.stroke_limit_for_par(definition.par):
		_finish("Schlaglimit erreicht")
		return
	# Waiting does not freeze the ball: moving gates/rotors can still wake it.
	if ball.moving:
		_motion_ticks += 1
		if _motion_ticks >= MAX_MOTION_TICKS:
			_finish("Externe Bewegung verhindert den naechsten Schlag")
		return
	if _wait_left > 0:
		_wait_left -= 1
		return
	_prepare_shot(shots[_shot_index])


func _prepare_shot(shot: RouteShot) -> void:
	var minimum_speed := lerpf(controller.minimum_ball_speed, controller.maximum_ball_speed, controller.minimum_power)
	if shot.speed < minimum_speed or shot.speed > controller.maximum_ball_speed or shot.wait_ticks < 0:
		_finish("Ungueltige Schlagstaerke oder Wartezeit")
		return
	if not controller._clamp_cursor(shot.target).is_equal_approx(shot.target):
		_finish("Zielpunkt liegt ausserhalb des erreichbaren Zielbereichs")
		return
	controller.reset_aim()
	controller.cursor_position = shot.target
	controller.action_pressed()
	controller.power_value = inverse_lerp(controller.minimum_ball_speed, controller.maximum_ball_speed, shot.speed)
	controller.action_pressed()
	controller.accuracy_value = 0.0
	controller.action_pressed()
	controller.action_released()
	_swing_tick = _ticks
	_motion_ticks = 0
	_last_contact = ""
	_contact_count = 0


func _on_shot_committed(direction: Vector2, speed: float, _accuracy: float) -> void:
	_contact_delays.append(_ticks - _swing_tick)
	_strokes += 1
	ball.launch(direction, speed, _strokes)
	_rolling = true


func _record_stop() -> void:
	_trace.append({
		"shot": _strokes,
		"position": [ball.position.x, ball.position.y],
		"ticks": _ticks,
		"contacts": _contact_count,
		"last_contact": _last_contact,
	})


func _finish(reason: String) -> void:
	if _done:
		return
	_done = true
	set_physics_process(false)
	# Defer disposal until the current physics callback/signal has returned.
	finished.emit.call_deferred({
		"hole_id": String(definition.hole_id),
		"holed": _holed,
		"strokes": _strokes,
		"par": definition.par,
		"within_par": _holed and _strokes <= definition.par,
		"within_limit": _holed and _strokes <= RoundSession.stroke_limit_for_par(definition.par),
		"position": [ball.position.x, ball.position.y],
		"reason": reason,
		"trace": _trace,
		"contact_delays": _contact_delays,
	})
