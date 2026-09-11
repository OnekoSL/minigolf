class_name LegacyCourseFixtures
extends RefCounted

# Frozen geometry regression cases from before the eight-world course replacement.
# These resources are excluded from exports and never registered in the live game.
static func holes() -> HoleCatalog:
	return load("res://tests/fixtures/legacy/holes/hole_catalog.tres") as HoleCatalog


static func courses() -> CourseCatalog:
	return load("res://tests/fixtures/legacy/course_catalog.tres") as CourseCatalog
