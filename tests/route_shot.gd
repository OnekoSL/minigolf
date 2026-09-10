class_name RouteShot
extends RefCounted

var target: Vector2
var speed: float
var wait_ticks: int


func _init(aim: Vector2, strength: float, wait := 0) -> void:
	target = aim
	speed = strength
	wait_ticks = wait
