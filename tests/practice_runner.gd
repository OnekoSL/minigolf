extends Node

var checks := 0
var failures := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	await load("res://tests/practice_test.gd").run(self, _check)
	print("Übung: %d Checks, %d Fehler" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
	else:
		print("  OK  ", label)
