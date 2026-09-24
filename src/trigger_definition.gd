class_name TriggerDefinition
extends Resource

enum TriggerType { BALL_SWITCH }

@export var trigger_type := TriggerType.BALL_SWITCH
@export var trigger_id := &"unnamed_trigger"
@export var position := Vector2.ZERO
@export var size := Vector2(28.0, 16.0)
@export var target_ids: Array[StringName] = []


func validate(label: String, issues: Array[ValidationIssue] = []) -> PackedStringArray:
	var report := ValidationReport.new(issues, self)
	var errors := PackedStringArray()
	if trigger_id == &"" or trigger_id == &"unnamed_trigger":
		errors.append(report.message("TEXT_HAS_NO_UNIQUE_TRIGGER_ID", [label], null, ""))
	if size.x <= 0.0 or size.y <= 0.0:
		errors.append(report.message("TEXT_HAS_AN_INVALID_TRIGGER_SIZE", [label], null, ""))
	if target_ids.is_empty():
		errors.append(report.message("TEXT_HAS_NO_TRIGGER_TARGET", [label], null, ""))
	return errors


func instantiate_trigger() -> BallSwitch:
	var trigger := BallSwitch.new()
	trigger.trigger_id = trigger_id
	trigger.position = position
	trigger.switch_size = size
	return trigger
