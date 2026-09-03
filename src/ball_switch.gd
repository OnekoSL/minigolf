class_name BallSwitch
extends Area2D

signal activated(trigger_id: StringName, world_position: Vector2)

@export var trigger_id := &"unnamed_trigger"
@export var switch_size := Vector2(28.0, 16.0)

var is_activated := false


func _ready() -> void:
	z_index = 1
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = switch_size
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func reset_state() -> void:
	is_activated = false
	queue_redraw()


func activate() -> void:
	if is_activated:
		return
	is_activated = true
	queue_redraw()
	activated.emit(trigger_id, global_position)


func _on_body_entered(body: Node2D) -> void:
	if body is PrototypeBall and body.moving and not body.is_cannon_sequence_active():
		activate()


func _draw() -> void:
	var rect := Rect2(-switch_size * 0.5, switch_size)
	var fill := Color("#69d38b") if is_activated else Color("#d75b55")
	draw_rect(rect, Color("#1c2930"), true)
	draw_rect(rect.grow(-2.0), fill, true)
	draw_rect(rect, Color("#e6dfb8"), false, 1.0)
	var lamp := Color("#dbff9c") if is_activated else Color("#ff927f")
	draw_circle(Vector2.ZERO, 2.0, lamp)
