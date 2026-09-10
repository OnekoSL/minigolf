class_name BestScoreResult
extends RefCounted

var best_score: int
var updated: bool
var error: Error


func _init(value := -1, changed := false, failure: Error = OK) -> void:
	best_score = value
	updated = changed
	error = failure
