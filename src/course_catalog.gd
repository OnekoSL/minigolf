class_name CourseCatalog
extends Resource

const DEFAULT_CATALOG_PATH := "res://data/course_catalog.tres"

@export var courses: Array[CourseDefinition] = []


static func load_default() -> CourseCatalog:
	return load(DEFAULT_CATALOG_PATH) as CourseCatalog


func validate(hole_catalog: HoleCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	if courses.is_empty():
		errors.append("Kurskatalog ist leer")
	for course in courses:
		if course == null:
			errors.append("Kurskatalog enthaelt einen leeren Eintrag")
			continue
		errors.append_array(course.validate(hole_catalog))
		if ids.has(course.course_id):
			errors.append("Doppelte Kurs-ID: %s" % course.course_id)
		ids[course.course_id] = true
	return errors


func get_course(course_id: StringName) -> CourseDefinition:
	for course in courses:
		if course != null and course.course_id == course_id:
			return course
	return null
