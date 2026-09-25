class_name TutorialCatalog
extends Resource

@export var lessons: Array[TutorialLesson] = []


static func load_default() -> TutorialCatalog:
	return load("res://data/tutorial/catalog.tres") as TutorialCatalog


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	for lesson in lessons:
		if lesson == null or lesson.sections.is_empty() or lesson.lesson_id == &"":
			errors.append("Invalid tutorial lesson")
			continue
		if ids.has(lesson.lesson_id):
			errors.append("Duplicate tutorial ID")
		ids[lesson.lesson_id] = true
		for section in lesson.sections:
			if section == null:
				errors.append("Missing tutorial section")
				continue
			if ids.has(section.section_id):
				errors.append("Duplicate tutorial ID")
			ids[section.section_id] = true
			errors.append_array(section.validate())
	return errors
