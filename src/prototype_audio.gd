class_name PrototypeAudio
extends Node

const SAMPLE_RATE := 22050

var players: Dictionary = {}
var roll_player: AudioStreamPlayer
var roll_streams: Dictionary = {}
var current_roll_profile := &""


func _ready() -> void:
	players["hit"] = _make_player(_make_stream(&"tone", 0.09, 190.0, 105.0, 0.38))
	players["wall"] = _make_player(_make_stream(&"tone", 0.06, 430.0, 300.0, 0.24))
	players["windmill"] = _make_player(_make_stream(&"metal", 0.09, 780.0, 510.0, 0.25))
	players["gate"] = _make_player(_make_stream(&"metal", 0.08, 310.0, 220.0, 0.28))
	players["water"] = _make_player(_make_stream(&"water", 0.30, 135.0, 68.0, 0.28))
	players["hole"] = _make_player(_make_stream(&"hole", 0.28, 660.0, 880.0, 0.22))
	players["phase"] = _make_player(_make_stream(&"tone", 0.045, 360.0, 300.0, 0.11))
	players["perfect"] = _make_player(_make_stream(&"metal", 0.14, 940.0, 1180.0, 0.14))
	for player in players.values():
		add_child(player)
	roll_streams[&"grass"] = _make_stream(&"roll_grass", 0.16, 90.0, 90.0, 0.09, true)
	roll_streams[&"sand"] = _make_stream(&"roll_sand", 0.16, 58.0, 58.0, 0.11, true)
	roll_streams[&"slope"] = _make_stream(&"roll_slope", 0.16, 112.0, 112.0, 0.08, true)
	roll_player = AudioStreamPlayer.new()
	roll_player.volume_db = -40.0
	add_child(roll_player)


func play_phase(state: int) -> void:
	var pitch := 0.0
	match state:
		ShotController.ShotState.POWER:
			pitch = 0.85
		ShotController.ShotState.ACCURACY:
			pitch = 1.05
		ShotController.ShotState.ARMED:
			pitch = 1.28
	if pitch > 0.0:
		_play_one_shot("phase", -12.0, pitch)


func play_hit(speed: float, perfect: bool) -> void:
	var normalized := clampf(inverse_lerp(60.0, 420.0, speed), 0.0, 1.0)
	_play_one_shot("hit", lerpf(-9.0, -2.0, normalized), lerpf(0.82, 1.18, normalized))
	if perfect:
		_play_one_shot("perfect", -8.0, 1.0)


func play_wall(intensity: float, kind: StringName) -> void:
	var normalized := clampf(inverse_lerp(35.0, 420.0, intensity), 0.0, 1.0)
	if kind == &"windmill":
		_play_one_shot("windmill", lerpf(-11.0, -3.0, normalized), lerpf(0.9, 1.15, normalized))
	elif kind == &"gate":
		_play_one_shot("gate", lerpf(-12.0, -3.0, normalized), lerpf(0.88, 1.08, normalized))
	else:
		_play_one_shot("wall", lerpf(-13.0, -4.0, normalized), lerpf(0.82, 1.16, normalized))


func play_water() -> void:
	_play_one_shot("water", -4.0, 1.0)


func play_hole() -> void:
	_play_one_shot("hole", -4.0, 1.0)


func update_roll(speed: float, surface_type: int, moving: bool) -> void:
	var profile := roll_profile(surface_type, speed, moving)
	if not bool(profile["audible"]):
		current_roll_profile = &""
		if roll_player.playing:
			roll_player.stop()
		return
	var profile_name: StringName = profile["profile"]
	if profile_name != current_roll_profile:
		current_roll_profile = profile_name
		roll_player.stream = roll_streams[profile_name]
		roll_player.play()
	elif not roll_player.playing:
		roll_player.play()
	roll_player.volume_db = float(profile["volume_db"])
	roll_player.pitch_scale = float(profile["pitch_scale"])


func set_game_paused(value: bool) -> void:
	if value and roll_player != null:
		roll_player.stop()


static func roll_profile(surface_type: int, speed: float, moving: bool) -> Dictionary:
	if not moving or speed < 8.0:
		return {"audible": false, "profile": &"", "volume_db": -80.0, "pitch_scale": 1.0}
	var normalized := clampf(inverse_lerp(8.0, 420.0, speed), 0.0, 1.0)
	var profile := &"grass"
	var pitch := lerpf(0.84, 1.15, normalized)
	var volume := lerpf(-34.0, -21.0, normalized)
	if surface_type == SurfaceZone.SurfaceType.SAND:
		profile = &"sand"
		pitch *= 0.72
		volume += 1.0
	elif surface_type == SurfaceZone.SurfaceType.SLOPE:
		profile = &"slope"
		pitch *= 1.18
	return {"audible": true, "profile": profile, "volume_db": volume, "pitch_scale": pitch}


func _play_one_shot(name: String, volume_db: float, pitch_scale: float) -> void:
	var player: AudioStreamPlayer = players.get(name)
	if player == null:
		return
	player.stop()
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _make_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	return player


func _make_stream(
	kind: StringName,
	duration: float,
	start_frequency: float,
	end_frequency: float,
	amplitude: float,
	looped := false
) -> AudioStreamWAV:
	var sample_count := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in range(sample_count):
		var progress := float(index) / float(sample_count)
		var time := float(index) / float(SAMPLE_RATE)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		var noise := fposmod(sin(float(index) * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0
		var sample := sin(TAU * frequency * time)
		match kind:
			&"metal":
				sample = sample * 0.68 + sin(TAU * frequency * 2.07 * time) * 0.32
			&"water":
				sample = noise * 0.48 + sin(TAU * frequency * time) * 0.52
			&"hole":
				var note := start_frequency if progress < 0.48 else end_frequency
				sample = sin(TAU * note * time) * 0.75 + sin(TAU * note * 2.0 * time) * 0.25
			&"roll_grass":
				sample = noise * 0.25 + sin(TAU * frequency * time) * 0.18
			&"roll_sand":
				sample = noise * 0.62 + sin(TAU * frequency * time) * 0.12
			&"roll_slope":
				sample = noise * 0.18 + sin(TAU * frequency * time) * 0.26
		var envelope := 1.0 if looped else (1.0 - progress)
		if not looped:
			envelope *= minf(1.0, progress / 0.015)
		bytes.encode_s16(index * 2, int(clampf(sample * envelope * amplitude, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream
