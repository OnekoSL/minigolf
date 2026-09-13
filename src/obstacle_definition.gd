class_name ObstacleDefinition
extends Resource

enum ObstacleType { ROTATING_BLADE, SLIDING_GATE, SEESAW, TUNNEL_GEAR, ELEPHANT }

@export var elephant_intake := Vector2(0, 144)
@export var elephant_exit := Vector2(-28, -112)
@export var elephant_gate_size := Vector2(12, 64)
@export var elephant_gate_offset := Vector2(0, 76)
@export var elephant_intake_radius := 8.0
@export var elephant_exit_speed := 205.0
@export var elephant_transport_seconds := 1.2
@export var elephant_cycle_seconds := 6.0

@export var obstacle_type := ObstacleType.ROTATING_BLADE
@export var position := Vector2.ZERO
@export var gear_links := PackedInt32Array([1,0,4,7,2,6,5,3])
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
@export var seesaw_size := Vector2(96.0, 64.0)
@export_range(1.0, 30.0, 0.5) var seesaw_max_angle_degrees := 16.0
@export_range(0.1, 3.0, 0.05) var seesaw_response_seconds := 0.35
@export_range(0.0, 200.0, 1.0) var seesaw_slope_strength := 120.0
@export_range(1.0, 12.0, 1.0) var seesaw_end_lip_thickness := 4.0
@export_range(0.05, 0.95, 0.05) var seesaw_blocker_tilt_threshold := 0.2
@export_range(-1.0, 1.0, 0.05) var seesaw_preferred_tilt := -1.0


func validate(label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if obstacle_type == ObstacleType.ELEPHANT:
		if elephant_intake_radius <= 0.0 or elephant_exit_speed <= 0.0 or elephant_transport_seconds < PrototypeBall.TUNNEL_DURATION or elephant_cycle_seconds < 4.0:
			errors.append("%s besitzt ungueltige Elefantenzeiten oder Aufnahmeparameter" % label)
		if elephant_gate_size.x <= 0.0 or elephant_gate_size.y <= 0.0 or elephant_gate_offset.y < elephant_gate_size.y + PrototypeBall.RADIUS:
			errors.append("%s gibt den Elefantendurchgang nicht vollstaendig frei" % label)
		if not elephant_intake.is_finite() or not elephant_exit.is_finite():
			errors.append("%s besitzt ungueltige Elefantenpositionen" % label)
	if obstacle_type == ObstacleType.TUNNEL_GEAR:
		if seconds_per_revolution < 4.0:
			errors.append("%s dreht fuer sichere Zahnrad-Ausgaenge zu schnell" % label)
		if gear_links.size() != 8:
			errors.append("%s benoetigt acht paarweise verbundene Zahnradloecher" % label)
		else:
			for index in range(8):
				var partner := gear_links[index]
				if partner < 0 or partner >= 8 or partner == index or gear_links[partner] != index:
					errors.append("%s besitzt kein gegenseitiges Lochpaar bei %d" % [label,index])
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
	elif obstacle_type == ObstacleType.SEESAW:
		if seesaw_size.x <= 0.0 or seesaw_size.y <= 0.0:
			errors.append("%s besitzt keine gueltige Wippengroesse" % label)
		if seesaw_max_angle_degrees <= 0.0 or seesaw_response_seconds <= 0.0 or seesaw_slope_strength <= 0.0:
			errors.append("%s besitzt keine gueltige Wippenbewegung" % label)
		if seesaw_end_lip_thickness <= 0.0 or seesaw_blocker_tilt_threshold <= 0.0:
			errors.append("%s besitzt keine gueltige Wippensperre" % label)
		if absf(seesaw_preferred_tilt) > 1.0:
			errors.append("%s besitzt keine gueltige Wippen-Vorzugsposition" % label)
	return errors


func instantiate_obstacle() -> Node2D:
	var placement_rotation := deg_to_rad(start_rotation_degrees)
	match obstacle_type:
		ObstacleType.ELEPHANT:
			var elephant := ElephantObstacle.new()
			elephant.position = position
			elephant.rotation = placement_rotation
			elephant.intake_position = elephant_intake
			elephant.exit_position = elephant_exit
			elephant.gate_size = elephant_gate_size
			elephant.gate_offset = elephant_gate_offset
			elephant.intake_radius = elephant_intake_radius
			elephant.exit_speed = elephant_exit_speed
			elephant.transport_seconds = elephant_transport_seconds
			elephant.cycle_seconds = elephant_cycle_seconds
			return elephant
		ObstacleType.TUNNEL_GEAR:
			var gear := TunnelGear.new()
			gear.position = position
			gear.rotation = placement_rotation
			gear.seconds_per_revolution = seconds_per_revolution
			gear.links = gear_links.duplicate()
			return gear
		ObstacleType.ROTATING_BLADE:
			var obstacle := RotatingObstacle.new()
			obstacle.position = position
			obstacle.rotation = placement_rotation
			obstacle.blade_size = blade_size
			obstacle.seconds_per_revolution = seconds_per_revolution
			obstacle.impulse_multiplier = impulse_multiplier
			obstacle.minimum_kick_speed = minimum_kick_speed
			return obstacle
		ObstacleType.SLIDING_GATE:
			var gate := TimedSlidingGate.new()
			gate.position = position
			gate.rotation = placement_rotation
			gate.gate_size = gate_size
			# Der Oeffnungsweg ist Teil der lokalen Hindernisgeometrie und dreht
			# sich deshalb gemeinsam mit einem um 90 Grad platzierten Tor.
			gate.open_offset = open_offset.rotated(placement_rotation)
			gate.cycle_seconds = cycle_seconds
			gate.transition_seconds = transition_seconds
			gate.open_hold_seconds = open_hold_seconds
			gate.phase_offset_seconds = phase_offset_seconds
			return gate
		ObstacleType.SEESAW:
			var seesaw := SeesawObstacle.new()
			seesaw.position = position
			seesaw.rotation = placement_rotation
			seesaw.plank_size = seesaw_size
			seesaw.max_tilt_degrees = seesaw_max_angle_degrees
			seesaw.response_seconds = seesaw_response_seconds
			seesaw.seesaw_slope_strength = seesaw_slope_strength
			seesaw.end_lip_thickness = seesaw_end_lip_thickness
			seesaw.blocker_tilt_threshold = seesaw_blocker_tilt_threshold
			seesaw.preferred_tilt = seesaw_preferred_tilt
			return seesaw
	return Node2D.new()
