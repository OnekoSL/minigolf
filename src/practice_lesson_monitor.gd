class_name PracticeLessonMonitor
extends Node2D

signal succeeded()
signal missed_goal()

var section: TutorialSection
var game: PrototypeMain
var progress := {"bank": false, "surface": false, "passage": false, "entry": false, "held": false}
var held_seconds := 0.0
var completed := false


func _ready() -> void:
	process_physics_priority = 110
	game.ball.wall_hit.connect(_wall_hit)
	game.ball.holed.connect(_holed)
	game.ball.stopped.connect(_stopped)
	game.shot_controller.shot_committed.connect(_committed)
	game.shot_controller.state_changed.connect(_state_changed)
	game.shot_controller.cancelled.connect(func(): held_seconds = 0.0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if get_tree().paused or completed:
		return
	if game.shot_controller.state == ShotController.ShotState.ARMED:
		held_seconds += delta
	if not game.ball.moving or game.strokes == 0:
		return
	if game.ball.current_surface_type == section.required_surface:
		progress.surface = true
	if section.passage.has_point(game.ball.position):
		progress.passage = true
	if section.goal == TutorialSection.Goal.SEESAW:
		for obstacle in game.hole.obstacle_nodes:
			if obstacle is SeesawObstacle:
				var point: Vector2 = obstacle.to_local(game.ball.global_position)
				if point.x < -obstacle.plank_size.x * 0.25 and absf(point.y) < obstacle.plank_size.y * 0.35 and game.ball.current_surface_type == SurfaceZone.SurfaceType.SLOPE:
					progress.entry = true


func _state_changed(state: int) -> void:
	if state == ShotController.ShotState.POWER:
		held_seconds = 0.0


func _committed(_direction: Vector2, _speed: float, _accuracy: float) -> void:
	if held_seconds >= 0.75:
		progress.held = true


func _wall_hit(_intensity: float, _point: Vector2, _normal: Vector2, kind: StringName) -> void:
	if game.strokes > 0 and kind == &"wall":
		progress.bank = true


func _stopped(point: Vector2) -> void:
	if section.goal == TutorialSection.Goal.STOP_ZONE and game.strokes > 0 and section.target_zone.grow(-PrototypeBall.RADIUS).has_point(point):
		_complete()


func _holed(_strokes: int) -> void:
	var valid := false
	match section.goal:
		TutorialSection.Goal.HOLE: valid = true
		TutorialSection.Goal.HELD_GATE: valid = progress.held and progress.passage
		TutorialSection.Goal.BANK: valid = progress.bank
		TutorialSection.Goal.SURFACE: valid = progress.surface
		TutorialSection.Goal.PASSAGE: valid = progress.passage
		TutorialSection.Goal.SEESAW: valid = progress.entry and progress.passage
	if valid:
		_complete()
	else:
		missed_goal.emit.call_deferred()


func _complete() -> void:
	if completed:
		return
	completed = true
	succeeded.emit.call_deferred()


func capture() -> Dictionary:
	return {"progress": progress.duplicate(), "held": held_seconds, "completed": completed}


func restore(state: Dictionary) -> void:
	progress = state.progress.duplicate()
	held_seconds = state.held
	completed = state.completed


func reset() -> void:
	for key in progress:
		progress[key] = false
	held_seconds = 0.0
	completed = false


func _draw() -> void:
	if section.goal == TutorialSection.Goal.STOP_ZONE:
		draw_rect(section.target_zone, Color(0.95, 0.85, 0.3, 0.18))
		draw_rect(section.target_zone, Color("#fff1b0"), false, 2)
