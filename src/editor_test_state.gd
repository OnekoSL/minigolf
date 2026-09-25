class_name EditorTestState
extends RefCounted

# In-memory only. No objects or executable data are deserialized from files.
# Script state on this fixed runtime tree includes transport clocks and link state;
# engine-owned transforms/collision flags are captured explicitly as well.
var nodes: Array[Dictionary] = []
var strokes := 0
var pending_perfect := false


static func capture(game: PrototypeMain) -> EditorTestState:
	var state := EditorTestState.new()
	state.strokes = game.strokes
	state.pending_perfect = game._pending_perfect
	state._capture_node(game.ball)
	state._capture_node(game.hole)
	state._capture_node(game.shot_controller)
	return state


func _capture_node(node: Node) -> void:
	var values := {}
	for property in node.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = node.get(property.name)
			# Resources, node bindings and static typed definition arrays retain identity.
			if value is Array or value is Dictionary:
				value = value.duplicate()
			values[property.name] = value
	if node is Node2D:
		values["transform"] = node.transform
		values["visible"] = node.visible
	if node is CharacterBody2D:
		values["velocity"] = node.velocity
	if node is CollisionObject2D:
		values["collision_layer"] = node.collision_layer
		values["collision_mask"] = node.collision_mask
	if node is CollisionShape2D:
		values["disabled"] = node.disabled
		if node.shape != null:
			values["shape"] = node.shape.duplicate()
	nodes.append({"node": node, "values": values})
	for child in node.get_children():
		_capture_node(child)


func restore(game: PrototypeMain) -> void:
	game.ball.cancel_hole_animation()
	# Invalidate outstanding water-return coroutines before restoring simulation state.
	var hazard_generation := game.ball._hazard_generation + 1
	for entry in nodes:
		var node: Node = entry.node
		if not is_instance_valid(node):
			continue
		# AnimatableBody2D otherwise queues a visual transform which the physics
		# server can replace with the old pose on the next synchronization frame.
		var synchronized: bool = node is AnimatableBody2D and node.sync_to_physics
		if synchronized:
			node.sync_to_physics = false
		for key in entry.values:
			var value: Variant = entry.values[key]
			if value is Array or value is Dictionary:
				value = value.duplicate()
			if key == "shape" and value is Shape2D:
				value = value.duplicate()
			node.set(key, value)
		if synchronized:
			node.sync_to_physics = true
		if node is CanvasItem:
			node.queue_redraw()
	game.ball._hazard_generation = hazard_generation
	game.strokes = strokes
	game._pending_perfect = pending_perfect
	game._attempt_reported = false
	game.hud.hide_result()
	game.hud.golfer.reset_animation()
	game.hud.play_golfer_reaction("perfect_swing" if pending_perfect else "swing")
	if game.feedback_effects != null:
		game.feedback_effects.clear()
	game._update_hud()
	game._update_camera_focus()
	game.course_camera.snap_to_target()
