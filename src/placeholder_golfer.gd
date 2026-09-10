class_name PlaceholderGolfer
extends Control

const ATLAS: Texture2D = preload("res://assets/golfer/allrounder_atlas.png")
const PALETTE_SHADER: Shader = preload("res://assets/golfer/palette.gdshader")
const FRAME_SIZE := Vector2(88, 144)
const BALL_POSITION := Vector2(44, 132)
const FOLLOW_SECONDS := 0.24
const REACTION_SECONDS := 1.25

var shot_state := ShotController.ShotState.AIMING
var reaction := ""
var palette_id := 0
var power_value := 0.0
var swing_progress := 0.0
var contact_seen := false
var animation_paused := false
var _time := 0.0
var _state_time := 0.0
var _reaction_left := 0.0
var _perfect_left := 0.0
var _perfect_pending := false
var _follow_elapsed := 0.0
var _contact_frame_pending := false
var _sprite: Sprite2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	clip_contents = true
	_sprite = Sprite2D.new()
	_sprite.texture = ATLAS
	_sprite.hframes = 4
	_sprite.vframes = 4
	_sprite.centered = false
	_sprite.scale = FRAME_SIZE / (ATLAS.get_size() / 4.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var palette := ShaderMaterial.new()
	palette.shader = PALETTE_SHADER
	_sprite.material = palette
	add_child(_sprite)
	_apply_palette()
	_update_sprite()


func _process(delta: float) -> void:
	# The child can process after shot_committed in the same frame. Keep the
	# contact pose for that render instead of immediately advancing past it.
	if _contact_frame_pending:
		_contact_frame_pending = false
		advance_animation(0.0)
		return
	advance_animation(delta)


func advance_animation(delta: float) -> void:
	if animation_paused:
		return
	var elapsed := maxf(delta, 0.0)
	_time += elapsed
	_state_time += elapsed
	if contact_seen:
		_follow_elapsed += elapsed
	_perfect_left = maxf(0.0, _perfect_left - elapsed)
	_reaction_left = maxf(0.0, _reaction_left - elapsed)
	if _reaction_left <= 0.0:
		reaction = ""
	_update_sprite()


func reset_animation() -> void:
	shot_state = ShotController.ShotState.AIMING
	reaction = ""
	power_value = 0.0
	swing_progress = 0.0
	contact_seen = false
	_perfect_pending = false
	_time = 0.0
	_state_time = 0.0
	_reaction_left = 0.0
	_perfect_left = 0.0
	_follow_elapsed = 0.0
	_contact_frame_pending = false
	_update_sprite()


func set_shot_state(value: int) -> void:
	if shot_state == value:
		return
	if value in [ShotController.ShotState.AIMING, ShotController.ShotState.POWER]:
		reset_animation()
	shot_state = value
	_state_time = 0.0
	_update_sprite()


func set_power(value: float) -> void:
	power_value = clampf(value, 0.0, 1.0)
	_update_sprite()


func set_swing_progress(value: float) -> void:
	swing_progress = clampf(value, 0.0, 1.0)
	_update_sprite()


func notify_ball_contact() -> void:
	# Only the actual shot_committed event may start the inset ball or glint.
	contact_seen = true
	shot_state = ShotController.ShotState.BALL_MOVING
	swing_progress = 1.0
	_follow_elapsed = 0.0
	_contact_frame_pending = true
	_perfect_left = 0.25 if _perfect_pending else 0.0
	_perfect_pending = false
	_update_sprite()


func play_reaction(kind: String) -> void:
	if kind in ["swing", "perfect_swing"]:
		_perfect_pending = kind == "perfect_swing"
	elif kind in ["success", "frustration"]:
		reaction = kind
		_reaction_left = REACTION_SECONDS
	_update_sprite()


func set_palette(value: int) -> void:
	var next_palette := clampi(value, 0, PlayerProfile.PALETTE_COLORS.size() - 1)
	if next_palette == palette_id:
		return
	palette_id = next_palette
	reset_animation()
	_apply_palette()


func _apply_palette() -> void:
	if _sprite != null:
		(_sprite.material as ShaderMaterial).set_shader_parameter("shirt_color", PlayerProfile.PALETTE_COLORS[palette_id])


func get_pose_frame() -> int:
	if reaction == "success":
		return 12 if REACTION_SECONDS - _reaction_left < 0.16 else 13
	if reaction == "frustration":
		return 14 if REACTION_SECONDS - _reaction_left < 0.3 else 15
	match shot_state:
		ShotController.ShotState.POWER, ShotController.ShotState.ACCURACY, ShotController.ShotState.ARMED:
			return _backswing_frame(power_value)
		ShotController.ShotState.SWINGING:
			return _backswing_frame(power_value * (1.0 - swing_progress))
		ShotController.ShotState.BALL_MOVING:
			if contact_seen and _follow_elapsed < FOLLOW_SECONDS:
				if _follow_elapsed < 1.0 / 60.0:
					return 8
				var reach := (0.25 + 0.75 * power_value) * _follow_elapsed / FOLLOW_SECONDS
				return 9 + mini(2, int(reach * 3.0))
			return 3
		ShotController.ShotState.HOLE_COMPLETE:
			return 3
	var cycle := fposmod(_time, 3.6)
	if cycle > 3.42:
		return 1
	return 2 if cycle > 1.0 and cycle < 2.2 else 0


func _backswing_frame(amount: float) -> int:
	if amount < 0.015:
		return 0
	if amount < 0.34:
		return 4
	if amount < 0.68:
		return 5
	return 6


func _update_sprite() -> void:
	if _sprite != null:
		_sprite.frame = get_pose_frame()
	queue_redraw()


func get_inset_ball_position() -> Vector2:
	if contact_seen:
		return BALL_POSITION + Vector2(42.0 * clampf(_follow_elapsed / 0.22, 0.0, 1.0), 0)
	return BALL_POSITION


func is_inset_ball_visible() -> bool:
	if not reaction.is_empty():
		return false
	if shot_state == ShotController.ShotState.BALL_MOVING:
		return contact_seen and _follow_elapsed < 0.22
	return shot_state != ShotController.ShotState.HOLE_COMPLETE


func _draw() -> void:
	if is_inset_ball_visible():
		var at := get_inset_ball_position().round()
		draw_rect(Rect2(at - Vector2(2, 2), Vector2(4, 4)), Color("#fff5d9"))
		draw_rect(Rect2(at - Vector2(1, 2), Vector2(2, 1)), Color.WHITE)
	if _perfect_left > 0.0:
		var at := BALL_POSITION + Vector2(0, -8)
		draw_line(at - Vector2(4, 0), at + Vector2(4, 0), Color("#fff1a4"), 1.0)
		draw_line(at - Vector2(0, 4), at + Vector2(0, 4), Color("#fff1a4"), 1.0)
