extends Node
## Autoload "Audio": music, sound effects and voiced lines with subtitles.
## Files live in audio/music, audio/sfx and audio/voice. Spoken text lives in
## data/lines.json. Swap any WAV/OGG for a real recording with the same name.

const LINES_PATH := "res://data/lines.json"
## Line ids with real recordings (written by tools/recordings.py). They play
## at natural pitch; the per-speaker pitch below only nudges TTS voices.
const RECORDED_PATH := "res://data/recorded.json"

## Per-speaker subtitle name, color and playback pitch. Leo's generated voice
## is nudged up so he reads as an 8-year-old (not applied to real recordings).
const SPEAKERS := {
	"leo": { "name": "", "color": Color(1, 0.97, 0.9), "pitch": 1.07, "bus": "Voice" },
	"mom": { "name": "Mom", "color": Color(1, 0.8, 0.75), "pitch": 1.0, "bus": "Voice" },
	"dad": { "name": "Dad", "color": Color(0.75, 0.85, 1), "pitch": 1.0, "bus": "Voice" },
	"sibling": { "name": "Through the door", "color": Color(0.85, 1, 0.75), "pitch": 1.0, "bus": "Muffled" },
	"grandma": { "name": "Grandma", "color": Color(1, 0.8, 0.55), "pitch": 1.0, "bus": "Voice" },
	"kids": { "name": "Kids", "color": Color(1, 0.9, 0.55), "pitch": 1.15, "bus": "Voice" },
	"sammy": { "name": "Little ghost", "color": Color(0.85, 0.9, 1), "pitch": 1.2, "bus": "Voice" },
	"brother": { "name": "Big kid", "color": Color(0.8, 1, 0.8), "pitch": 1.08, "bus": "Voice" },
	"tv": { "name": "TV", "color": Color(0.7, 0.85, 1), "pitch": 1.0, "bus": "TV" },
}

signal line_finished(id: String)

var lines := {}
var recorded := {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_name := ""
var _voice: AudioStreamPlayer
var _voice_3d: AudioStreamPlayer3D
var _line_serial := 0
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_load_lines()
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_voice = _make_player("Voice")
	_voice_3d = AudioStreamPlayer3D.new()
	_voice_3d.unit_size = 4.0
	add_child(_voice_3d)


func _setup_buses() -> void:
	if AudioServer.get_bus_index("Music") != -1:
		return
	for bus in ["Music", "SFX", "Voice", "TV", "Muffled"]:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus)
		AudioServer.set_bus_send(i, "Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -8.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("TV"), -4.0)

	var room := AudioEffectReverb.new()
	room.room_size = 0.35
	room.damping = 0.7
	room.wet = 0.12
	AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"), room)

	var voice_room := AudioEffectReverb.new()
	voice_room.room_size = 0.2
	voice_room.wet = 0.06
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Voice"), voice_room)

	var tv_band := AudioEffectBandPassFilter.new()
	tv_band.cutoff_hz = 1800.0
	tv_band.resonance = 0.6
	AudioServer.add_bus_effect(AudioServer.get_bus_index("TV"), tv_band)
	var tv_dist := AudioEffectDistortion.new()
	tv_dist.mode = AudioEffectDistortion.MODE_LOFI
	tv_dist.drive = 0.3
	AudioServer.add_bus_effect(AudioServer.get_bus_index("TV"), tv_dist)

	var muffle := AudioEffectLowPassFilter.new()
	muffle.cutoff_hz = 700.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Muffled"), muffle)


## Dream mode: everything gets a big, far-away reverb.
func set_dreaming(on: bool) -> void:
	for bus in ["SFX", "Voice"]:
		var fx := AudioServer.get_bus_effect(AudioServer.get_bus_index(bus), 0) as AudioEffectReverb
		fx.room_size = 0.9 if on else (0.35 if bus == "SFX" else 0.2)
		fx.wet = 0.45 if on else (0.12 if bus == "SFX" else 0.06)


func _load_lines() -> void:
	var f := FileAccess.open(LINES_PATH, FileAccess.READ)
	if f == null:
		push_error("Missing " + LINES_PATH)
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		lines = data
	if FileAccess.file_exists(RECORDED_PATH):
		var ids = JSON.parse_string(FileAccess.get_file_as_string(RECORDED_PATH))
		if ids is Array:
			for id in ids:
				recorded[id] = true


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


## Loads a stream once. `folder` is "music", "sfx" or "voice".
func get_stream(folder: String, name: String, loop := false) -> AudioStream:
	var key := folder + "/" + name
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStream = null
	for ext in [".ogg", ".mp3", ".wav"]:
		var path := "res://audio/%s/%s%s" % [folder, name, ext]
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream and loop:
		if stream is AudioStreamWAV:
			var wav := stream as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
	_cache[key] = stream
	return stream


# ---------------------------------------------------------------- music

func play_music(name: String, fade_time := 2.0, volume_db := 0.0) -> void:
	if name == _music_name:
		return
	_music_name = name
	var incoming := _music_b if _music_a.playing else _music_a
	var old := _music_a if incoming == _music_b else _music_b
	var stream := get_stream("music", name, true)
	if stream:
		incoming.stream = stream
		incoming.volume_db = -40.0
		incoming.play()
		create_tween().tween_property(incoming, "volume_db", volume_db, fade_time)
	if old.playing:
		var t := create_tween()
		t.tween_property(old, "volume_db", -40.0, fade_time)
		t.tween_callback(old.stop)


func stop_music(fade_time := 2.0) -> void:
	_music_name = ""
	for p in [_music_a, _music_b]:
		if p.playing:
			var t := create_tween()
			t.tween_property(p, "volume_db", -40.0, fade_time)
			t.tween_callback(p.stop)


# ---------------------------------------------------------------- sfx

## One-shot sound. Pass `at` for positional 3D sound. `variants` picks
## name_1..name_N at random (footsteps, barks).
func play_sfx(name: String, at: Variant = null, volume_db := 0.0, pitch_jitter := 0.0, variants := 0) -> void:
	if SEQUENCES.has(name):
		_play_sequence(name, at, volume_db, pitch_jitter)
		return
	var file := name
	if variants > 0:
		file = "%s_%d" % [name, randi_range(1, variants)]
	var stream := get_stream("sfx", file)
	if stream == null:
		return
	if at is Vector3 or at is Node3D:
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.bus = "SFX"
		p3.volume_db = volume_db
		p3.unit_size = 3.0
		p3.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
		get_tree().current_scene.add_child(p3)
		p3.global_position = at if at is Vector3 else (at as Node3D).global_position
		p3.play()
		p3.finished.connect(p3.queue_free)
	else:
		var p2 := AudioStreamPlayer.new()
		p2.stream = stream
		p2.bus = "SFX"
		p2.volume_db = volume_db
		p2.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
		add_child(p2)
		p2.play()
		p2.finished.connect(p2.queue_free)


## Sounds made of several hits: plays name_1, name_2... at these times.
const SEQUENCES := {
	"knock": [0.0, 0.26, 0.5],
}


func _play_sequence(name: String, at: Variant, volume_db: float, pitch_jitter: float) -> void:
	var times: Array = SEQUENCES[name]
	for i in times.size():
		if i > 0:
			await get_tree().create_timer(times[i] - times[i - 1]).timeout
		play_sfx("%s_%d" % [name, i + 1], at, volume_db, pitch_jitter)


## A looping positional ambience (TV, crickets, clock). Returns the player so
## the caller can move, retune or stop it.
func make_loop(name: String, parent: Node, volume_db := 0.0, bus := "SFX", positional := true) -> Node:
	var stream := get_stream("sfx", name, true)
	var p: Node
	if positional:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 3.0
		p3.volume_db = volume_db
		p3.bus = bus
		p3.stream = stream
		p = p3
	else:
		var p2 := AudioStreamPlayer.new()
		p2.volume_db = volume_db
		p2.bus = bus
		p2.stream = stream
		p = p2
	parent.add_child(p)
	if stream:
		p.call("play")
	return p


# ---------------------------------------------------------------- voice

func has_line(id: String) -> bool:
	return lines.has(id)


func line_text(id: String) -> String:
	return lines.get(id, {}).get("text", "")


## Speaks a line (and anything chained with "next"), showing subtitles.
## Interrupts whatever was being said. Await it to wait for the whole chain.
func say(id: String, at: Node3D = null) -> void:
	_line_serial += 1
	var serial := _line_serial
	var current := id
	while current != "" and serial == _line_serial:
		var line: Dictionary = lines.get(current, {})
		if line.is_empty():
			push_warning("Unknown line id: " + current)
			return
		var spk: Dictionary = SPEAKERS.get(line.get("speaker", "leo"), SPEAKERS.leo)
		var text: String = line.get("text", "")
		var stream := get_stream("voice", current)
		var length := 1.2 + text.length() * 0.06
		var pitch: float = 1.0 if recorded.has(current) else spk.pitch
		_voice.stop()
		_voice_3d.stop()
		if stream:
			var player: Node = _voice
			if at:
				_voice_3d.global_position = at.global_position
				player = _voice_3d
			player.set("stream", stream)
			player.set("bus", spk.bus)
			player.set("pitch_scale", pitch)
			player.call("play")
			length = stream.get_length() / pitch
		get_tree().call_group("hud", "show_line", spk.name, text, spk.color, length + 1.5)
		await get_tree().create_timer(length + 0.35).timeout
		if serial != _line_serial:
			return
		line_finished.emit(current)
		current = line.get("next", "")


func stop_voice() -> void:
	_line_serial += 1
	_voice.stop()
	_voice_3d.stop()
