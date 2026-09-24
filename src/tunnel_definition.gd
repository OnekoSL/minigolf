class_name TunnelDefinition
extends Resource

const HOLE_RADIUS := 7.0

@export var endpoint_a := Vector2.ZERO
@export var endpoint_b := Vector2.ZERO


func validate(label: String, issues: Array[ValidationIssue] = []) -> PackedStringArray:
	var report := ValidationReport.new(issues, self)
	var errors := PackedStringArray()
	if endpoint_a.distance_to(endpoint_b) <= HOLE_RADIUS * 2.0:
		errors.append(report.message("TEXT_DOES_NOT_CONNECT_TWO_SEPARATE_HOLES", [label], null, ""))
	return errors


func get_other_endpoint(entry_position: Vector2) -> Vector2:
	if entry_position.distance_squared_to(endpoint_a) <= entry_position.distance_squared_to(endpoint_b):
		return endpoint_b
	return endpoint_a

