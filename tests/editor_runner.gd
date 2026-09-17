extends Node

var failures := 0
var checks := 0


func _ready() -> void:
	await load("res://tests/editor_test.gd").run(self, _check)
	print("Editor: %d Checks, %d Fehler" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
