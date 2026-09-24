class_name SurfaceDefinition
extends Resource

@export var rect := Rect2(Vector2.ZERO, Vector2(64.0, 32.0))
@export_range(-180.0, 180.0, 0.1) var rotation_degrees := 0.0
@export_enum("Sand", "Gefaelle", "Wasser", "Beton", "Eis") var surface_type: int = SurfaceZone.SurfaceType.SAND
@export var deceleration := 260.0
@export var acceleration := Vector2.ZERO
@export_enum("Oben", "Oben rechts", "Rechts", "Unten rechts", "Unten", "Unten links", "Links", "Oben links") var slope_direction: int = SurfaceZone.SlopeDirection.UP
@export_range(0.0, 300.0, 1.0) var slope_strength := SurfaceZone.DEFAULT_SLOPE_ACCELERATION
@export_range(0.0, 300.0, 1.0) var minimum_flow_speed := 0.0
@export_range(0.0, 500.0, 1.0) var maximum_flow_speed := 0.0
@export_range(0.0, 30.0, 0.5) var flow_alignment_rate := 0.0
@export_range(0.0, 30.0, 0.5) var flow_centering_strength := 0.0


func validate(label: String, issues: Array[ValidationIssue] = []) -> PackedStringArray:
	var report := ValidationReport.new(issues, self)
	var errors := PackedStringArray()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		errors.append(report.message("TEXT_HAS_AN_INVALID_AREA", [label], null, ""))
	if deceleration < 0.0:
		errors.append(report.message("TEXT_HAS_NEGATIVE_FRICTION", [label], null, ""))
	if surface_type == SurfaceZone.SurfaceType.ICE:
		if not is_equal_approx(deceleration, SurfaceZone.ICE_DECELERATION) or acceleration != Vector2.ZERO or minimum_flow_speed != 0.0 or maximum_flow_speed != 0.0 or flow_alignment_rate != 0.0 or flow_centering_strength != 0.0:
			errors.append(report.message("TEXT_ICE_REQUIRES_20_PX_S_BRAKING_AND_NO_ADDITIONAL_FORCES", [label], null, ""))
	if surface_type == SurfaceZone.SurfaceType.SLOPE and slope_strength <= 0.0:
		errors.append(report.message("TEXT_HAS_NO_EFFECTIVE_SLOPE", [label], null, ""))
	return errors


func instantiate_zone() -> SurfaceZone:
	var zone := SurfaceZone.new()
	if surface_type == SurfaceZone.SurfaceType.SLOPE:
		zone.configure_slope(
			rect,
			slope_direction as SurfaceZone.SlopeDirection,
			slope_strength,
			deceleration,
			minimum_flow_speed,
			maximum_flow_speed,
			flow_alignment_rate,
			flow_centering_strength,
			rotation_degrees
		)
	else:
		zone.configure(rect, surface_type as SurfaceZone.SurfaceType, deceleration, acceleration, rotation_degrees)
	return zone


func get_rotated_corners() -> PackedVector2Array:
	var result := PackedVector2Array()
	var center := rect.get_center()
	var half_size := rect.size * 0.5
	var angle := deg_to_rad(rotation_degrees)
	for corner in [
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	]:
		result.append(center + corner.rotated(angle))
	return result
