class_name FeedbackEffects
extends Node2D

var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var _sand_elapsed := 0.0
var _dust_serial := 0


func _ready() -> void:
	z_index = 2


func _process(delta: float) -> void:
	for index in range(particles.size() - 1, -1, -1):
		var particle := particles[index]
		particle["life"] = float(particle["life"]) - delta
		particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
		particle["velocity"] = Vector2(particle["velocity"]) * exp(-5.0 * delta)
		if float(particle["life"]) <= 0.0:
			particles.remove_at(index)
	for index in range(rings.size() - 1, -1, -1):
		var ring := rings[index]
		ring["delay"] = float(ring["delay"]) - delta
		if float(ring["delay"]) <= 0.0:
			ring["life"] = float(ring["life"]) - delta
		if float(ring["life"]) <= 0.0:
			rings.remove_at(index)
	queue_redraw()


func update_ball(position: Vector2, speed: float, surface_type: int, moving: bool, delta: float) -> void:
	if not moving or surface_type != SurfaceZone.SurfaceType.SAND or speed < 40.0:
		_sand_elapsed = 0.0
		return
	_sand_elapsed += delta
	if _sand_elapsed < 0.12:
		return
	_sand_elapsed = 0.0
	_dust_serial += 1
	var side := -1.0 if _dust_serial % 2 == 0 else 1.0
	_add_particle(position + Vector2(side * 2.0, 1.0), Vector2(side * 8.0, -8.0), 0.24, Color("#d8bb7b"), 1.5)
	_add_particle(position - Vector2(side * 2.0, 0.0), Vector2(-side * 5.0, -5.0), 0.20, Color("#8d6b3e"), 1.0)


func spawn_wall(position: Vector2, normal: Vector2, intensity: float, kind: StringName) -> void:
	if intensity < 120.0:
		return
	var direction := normal.normalized() if normal != Vector2.ZERO else Vector2.UP
	var tangent := direction.orthogonal()
	var color := Color("#ddd2ad")
	if kind == &"windmill":
		color = Color("#f0cf72")
	elif kind == &"gate":
		color = Color("#8ed7e5")
	var speed := clampf(intensity * 0.10, 14.0, 42.0)
	for spread in [-0.75, -0.25, 0.25, 0.75]:
		_add_particle(position, (direction + tangent * spread).normalized() * speed, 0.22, color, 1.0)


func spawn_water(position: Vector2) -> void:
	_add_ring(position, 0.0, 0.46, 3.0, 14.0, Color("#8ed7e5"))
	_add_ring(position, 0.10, 0.48, 2.0, 18.0, Color("#5db5d1"))


func spawn_hole(position: Vector2) -> void:
	_add_ring(position, 0.0, 0.34, 4.0, 16.0, Color("#f6e899"))


func spawn_perfect(position: Vector2) -> void:
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		_add_particle(position, direction * 22.0, 0.25, Color("#fff1a3"), 1.5)


func clear() -> void:
	particles.clear()
	rings.clear()
	queue_redraw()


func _add_particle(position: Vector2, velocity: Vector2, life: float, color: Color, size: float) -> void:
	particles.append({
		"position": position, "velocity": velocity, "life": life,
		"total": life, "color": color, "size": size,
	})


func _add_ring(position: Vector2, delay: float, life: float, start_radius: float, end_radius: float, color: Color) -> void:
	rings.append({
		"position": position, "delay": delay, "life": life, "total": life,
		"start": start_radius, "end": end_radius, "color": color,
	})


func _draw() -> void:
	for particle in particles:
		var ratio := clampf(float(particle["life"]) / float(particle["total"]), 0.0, 1.0)
		var color: Color = particle["color"]
		color.a *= ratio
		draw_circle(Vector2(particle["position"]), float(particle["size"]), color)
	for ring in rings:
		if float(ring["delay"]) > 0.0:
			continue
		var ratio := clampf(float(ring["life"]) / float(ring["total"]), 0.0, 1.0)
		var progress := 1.0 - ratio
		var color: Color = ring["color"]
		color.a *= ratio
		var radius := lerpf(float(ring["start"]), float(ring["end"]), progress)
		draw_arc(Vector2(ring["position"]), radius, 0.0, TAU, 24, color, 1.0)
