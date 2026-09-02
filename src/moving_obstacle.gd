class_name MovingObstacle
extends AnimatableBody2D

var feedback_kind := &"mechanism"


func get_velocity_at_world_point(_world_point: Vector2) -> Vector2:
	return Vector2.ZERO


func get_contact_normal(_world_point: Vector2) -> Vector2:
	return Vector2.UP


func get_impulse_multiplier() -> float:
	return 1.0


func get_minimum_kick_speed() -> float:
	return 0.0


func reset_motion() -> void:
	pass
