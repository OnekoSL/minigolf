class_name ValidationReport
extends RefCounted

var issues: Array[ValidationIssue]
var owner: Resource


func _init(destination: Array[ValidationIssue], source: Resource) -> void:
	issues = destination
	owner = source


func message(key: String, args: Array = [], target: Resource = null, marker := "") -> String:
	var issue := ValidationIssue.new(key, args, target if target != null else owner, marker)
	issues.append(issue)
	return issue.message()
