class_name WallDefinition
extends Resource

@export var center := Vector2.ZERO
@export var size := Vector2(8.0, 8.0)
@export_range(-180.0, 180.0, 0.1) var rotation_degrees := 0.0


func validate(label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if size.x <= 0.0 or size.y <= 0.0:
		errors.append("%s besitzt keine gueltige Groesse" % label)
	return errors
