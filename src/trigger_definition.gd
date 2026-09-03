class_name TriggerDefinition
extends Resource

enum TriggerType { BALL_SWITCH }

@export var trigger_type := TriggerType.BALL_SWITCH
@export var trigger_id := &"unnamed_trigger"
@export var position := Vector2.ZERO
@export var size := Vector2(28.0, 16.0)
@export var target_ids: Array[StringName] = []


func validate(label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if trigger_id == &"" or trigger_id == &"unnamed_trigger":
		errors.append("%s besitzt keine eindeutige Trigger-ID" % label)
	if size.x <= 0.0 or size.y <= 0.0:
		errors.append("%s besitzt keine gueltige Triggergroesse" % label)
	if target_ids.is_empty():
		errors.append("%s besitzt kein Triggerziel" % label)
	return errors


func instantiate_trigger() -> BallSwitch:
	var trigger := BallSwitch.new()
	trigger.trigger_id = trigger_id
	trigger.position = position
	trigger.switch_size = size
	return trigger
