class_name ObstacleDefinition
extends Resource

enum ObstacleType { ROTATING_BLADE, SLIDING_GATE }

@export var obstacle_type := ObstacleType.ROTATING_BLADE
@export var position := Vector2.ZERO
@export_range(-180.0, 180.0, 0.1) var start_rotation_degrees := 0.0
@export var blade_size := Vector2(72.0, 8.0)
@export_range(0.2, 20.0, 0.1) var seconds_per_revolution := 2.4
@export_range(0.0, 4.0, 0.05) var impulse_multiplier := 1.25
@export_range(0.0, 300.0, 1.0) var minimum_kick_speed := 55.0
@export var gate_size := Vector2(10.0, 86.0)
@export var open_offset := Vector2(0.0, -100.0)
@export_range(0.5, 20.0, 0.1) var cycle_seconds := 2.8
@export_range(0.01, 5.0, 0.01) var transition_seconds := 0.25
@export_range(0.0, 10.0, 0.05) var open_hold_seconds := 1.0
@export_range(0.0, 20.0, 0.05) var phase_offset_seconds := 0.0


func validate(label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if obstacle_type == ObstacleType.ROTATING_BLADE:
		if blade_size.x <= 0.0 or blade_size.y <= 0.0:
			errors.append("%s besitzt keine gueltige Hindernisgroesse" % label)
		if seconds_per_revolution <= 0.0:
			errors.append("%s besitzt keine gueltige Umlaufzeit" % label)
	elif obstacle_type == ObstacleType.SLIDING_GATE:
		if gate_size.x <= 0.0 or gate_size.y <= 0.0:
			errors.append("%s besitzt keine gueltige Torgroesse" % label)
		if open_offset.is_zero_approx():
			errors.append("%s besitzt keinen Oeffnungsweg" % label)
		if cycle_seconds <= open_hold_seconds + transition_seconds * 2.0:
			errors.append("%s besitzt keine geschlossene Haltephase" % label)
	return errors


func instantiate_obstacle() -> Node2D:
	match obstacle_type:
		ObstacleType.ROTATING_BLADE:
			var obstacle := RotatingObstacle.new()
			obstacle.position = position
			obstacle.rotation = deg_to_rad(start_rotation_degrees)
			obstacle.blade_size = blade_size
			obstacle.seconds_per_revolution = seconds_per_revolution
			obstacle.impulse_multiplier = impulse_multiplier
			obstacle.minimum_kick_speed = minimum_kick_speed
			return obstacle
		ObstacleType.SLIDING_GATE:
			var gate := TimedSlidingGate.new()
			gate.position = position
			gate.rotation = deg_to_rad(start_rotation_degrees)
			gate.gate_size = gate_size
			gate.open_offset = open_offset
			gate.cycle_seconds = cycle_seconds
			gate.transition_seconds = transition_seconds
			gate.open_hold_seconds = open_hold_seconds
			gate.phase_offset_seconds = phase_offset_seconds
			return gate
	return Node2D.new()
