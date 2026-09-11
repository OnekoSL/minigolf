extends Node

var failures := 0
var checks := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await load("res://tests/world_routes_test.gd").run(self,_check,true)
	print("Weltenaudit: %d Checks, %d Fehler" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FEHLER ",message)
