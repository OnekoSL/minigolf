class_name WallDefinition
extends Resource

enum WallType { RECTANGLE, CIRCLE, ARC }

@export var wall_type := WallType.RECTANGLE
@export var center := Vector2.ZERO
@export var size := Vector2(8.0, 8.0)
@export_range(-180.0, 180.0, 0.1) var rotation_degrees := 0.0
@export_range(2.0, 512.0, 0.5) var radius := 24.0
@export_range(2.0, 64.0, 0.5) var thickness := 8.0
@export_range(-360.0, 360.0, 0.5) var arc_start_degrees := 0.0
@export_range(-350.0, 350.0, 0.5) var arc_sweep_degrees := 90.0
@export_range(4, 128, 1) var arc_segments := 24


func validate(label: String, issues: Array[ValidationIssue] = []) -> PackedStringArray:
	var report := ValidationReport.new(issues, self)
	var errors := PackedStringArray()
	match wall_type:
		WallType.RECTANGLE:
			if size.x <= 0.0 or size.y <= 0.0:
				errors.append(report.message("TEXT_HAS_AN_INVALID_SIZE", [label], null, ""))
		WallType.CIRCLE:
			if radius <= 0.0:
				errors.append(report.message("TEXT_HAS_AN_INVALID_RADIUS", [label], null, ""))
		WallType.ARC:
			if radius <= thickness * 0.5 + 1.0:
				errors.append(report.message("TEXT_HAS_AN_ARC_RADIUS_THAT_IS_TOO_SMALL", [label], null, ""))
			if thickness <= 0.0:
				errors.append(report.message("TEXT_HAS_AN_INVALID_ARC_THICKNESS", [label], null, ""))
			if absf(arc_sweep_degrees) < 1.0 or absf(arc_sweep_degrees) > 350.0:
				errors.append(report.message("TEXT_HAS_AN_INVALID_ARC_SWEEP", [label], null, ""))
			if arc_segments < 4:
				errors.append(report.message("TEXT_HAS_TOO_FEW_ARC_SEGMENTS", [label], null, ""))
		_:
			errors.append(report.message("TEXT_HAS_AN_UNKNOWN_WALL_TYPE", [label], null, ""))
	return errors


func get_arc_polygon() -> PackedVector2Array:
	var polygon := PackedVector2Array()
	if wall_type != WallType.ARC:
		return polygon
	var outer_radius := radius + thickness * 0.5
	var inner_radius := radius - thickness * 0.5
	for index in range(arc_segments + 1):
		var progress := float(index) / float(arc_segments)
		var angle := deg_to_rad(arc_start_degrees + arc_sweep_degrees * progress)
		polygon.append(Vector2(cos(angle), sin(angle)) * outer_radius)
	for index in range(arc_segments, -1, -1):
		var progress := float(index) / float(arc_segments)
		var angle := deg_to_rad(arc_start_degrees + arc_sweep_degrees * progress)
		polygon.append(Vector2(cos(angle), sin(angle)) * inner_radius)
	return polygon


func get_arc_centerline() -> PackedVector2Array:
	var points := PackedVector2Array()
	if wall_type != WallType.ARC:
		return points
	for index in range(arc_segments + 1):
		var progress := float(index) / float(arc_segments)
		var angle := deg_to_rad(arc_start_degrees + arc_sweep_degrees * progress)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
