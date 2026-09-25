class_name TutorialSection
extends Resource

enum Goal { HOLE, STOP_ZONE, HELD_GATE, BANK, SURFACE, PASSAGE, SEESAW }

@export var section_id: StringName
@export var title_key: StringName
@export var hint_key: StringName
@export var hole: HoleDefinition
@export var goal := Goal.HOLE
@export var target_zone := Rect2()
@export var passage := Rect2()
@export var required_surface := -1


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if section_id == &"" or title_key == &"" or hint_key == &"":
		errors.append("Tutorial section requires stable IDs and text keys")
	if hole == null:
		errors.append("Tutorial section requires a hole")
	else:
		errors.append_array(hole.validate())
	if goal == Goal.STOP_ZONE and not target_zone.has_area():
		errors.append("Stop task requires a target zone")
	if goal in [Goal.HELD_GATE, Goal.PASSAGE, Goal.SEESAW] and not passage.has_area():
		errors.append("Passage task requires a passage")
	return errors
