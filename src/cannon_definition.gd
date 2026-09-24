class_name CannonDefinition
extends Resource

@export var mechanism_id := &"unnamed_cannon"
@export var required_trigger_id := &""
@export var position := Vector2.ZERO
@export var capture_size := Vector2(24.0, 18.0)
@export var entry_direction := Vector2.RIGHT
@export var landing_position := Vector2.ZERO
@export var landing_velocity := Vector2(55.0, 0.0)
@export_range(0.01, 2.0, 0.01) var intake_seconds := 0.20
@export_range(0.0, 2.0, 0.01) var ignition_seconds := 0.12
@export_range(0.05, 3.0, 0.01) var flight_seconds := 0.55
@export_range(0.0, 128.0, 1.0) var arc_height := 34.0


func validate(label: String, issues: Array[ValidationIssue] = []) -> PackedStringArray:
	var report := ValidationReport.new(issues, self)
	var errors := PackedStringArray()
	if mechanism_id == &"" or mechanism_id == &"unnamed_cannon":
		errors.append(report.message("TEXT_HAS_NO_UNIQUE_MECHANISM_ID", [label], null, ""))
	if capture_size.x <= 0.0 or capture_size.y <= 0.0:
		errors.append(report.message("TEXT_HAS_AN_INVALID_CAPTURE_AREA", [label], null, ""))
	if entry_direction.is_zero_approx():
		errors.append(report.message("TEXT_HAS_NO_ENTRY_DIRECTION", [label], null, ""))
	if intake_seconds <= 0.0 or flight_seconds <= 0.0 or ignition_seconds < 0.0:
		errors.append(report.message("TEXT_HAS_INVALID_SEQUENCE_TIMINGS", [label], null, ""))
	if arc_height <= 0.0:
		errors.append(report.message("TEXT_HAS_NO_VISIBLE_ARC_HEIGHT", [label], null, ""))
	return errors


func instantiate_cannon() -> AdventureCannon:
	var cannon := AdventureCannon.new()
	cannon.mechanism_id = mechanism_id
	cannon.required_trigger_id = required_trigger_id
	cannon.position = position
	cannon.capture_size = capture_size
	cannon.entry_direction = entry_direction.normalized()
	cannon.landing_position = landing_position
	cannon.landing_velocity = landing_velocity
	cannon.intake_seconds = intake_seconds
	cannon.ignition_seconds = ignition_seconds
	cannon.flight_seconds = flight_seconds
	cannon.arc_height = arc_height
	return cannon
