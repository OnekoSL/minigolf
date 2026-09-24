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
		errors.append(I18n.text("TEXT_COURSE_CATALOG_IS_EMPTY"))
	for course in courses:
		if course == null:
			errors.append(I18n.text("TEXT_COURSE_CATALOG_CONTAINS_AN_EMPTY_ENTRY"))
			continue
		errors.append_array(course.validate(hole_catalog))
		if ids.has(course.course_id):
			errors.append(I18n.text("TEXT_DUPLICATE_COURSE_ID") % course.course_id)
		ids[course.course_id] = true
	return errors


func get_course(course_id: StringName) -> CourseDefinition:
	for course in courses:
		if course != null and course.course_id == course_id:
			return course
	return null
