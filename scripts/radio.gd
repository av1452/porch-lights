class_name Radio
extends Interactable
## A kitchen radio: a little boombox that plays a playlist of songs from
## audio/music/ (the public-domain holiday songs from tools/compose_music.py),
## through the TV bus so it sounds like a small speaker. Using it skips to the
## next song; after the last one it clicks off, and using it again turns it
## back on.

@export var playlist: PackedStringArray = []
@export var volume_db := -10.0

var _player: AudioStreamPlayer3D
var _index := 0
var _on := true
var _dial: MeshInstance3D


func _ready() -> void:
	prompt = "Change the station"
	_build()
	_player = AudioStreamPlayer3D.new()
	_player.bus = "TV"
	_player.volume_db = volume_db
	_player.unit_size = 2.5
	_player.max_distance = 14.0
	add_child(_player)
	_player.finished.connect(_next)
	used.connect(_on_used)
	if not playlist.is_empty():
		_play(0)


func _on_used(_by: Node) -> void:
	Audio.play_sfx("switch_click", self, -8.0)
	if not _on:
		_on = true
		_play(0)
		return
	if _index + 1 >= playlist.size():
		_on = false
		_player.stop()
		_glow(false)
		return
	_play(_index + 1)


## Loud enough to hear all over the house, like Christmas morning.
func fill_house(volume := -6.0) -> void:
	_player.volume_db = volume
	_player.unit_size = 7.0
	_player.max_distance = 40.0


## Off, quietly (bedtime, dreams). Using it turns it back on.
func turn_off() -> void:
	_on = false
	_player.stop()
	_glow(false)


func _next() -> void:
	if _on and not playlist.is_empty():
		_play((_index + 1) % playlist.size())


func _play(i: int) -> void:
	_index = i
	var stream := Audio.get_stream("music", playlist[i])
	if stream == null:
		return
	# Songs play once each on the radio, then the next one comes on.
	if stream is AudioStreamWAV:
		stream = stream.duplicate()
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_player.stream = stream
	_player.play()
	_glow(true)


func _glow(on: bool) -> void:
	if _dial:
		(_dial.material_override as StandardMaterial3D).emission_energy_multiplier = 1.5 if on else 0.0


## A silver boombox with two speakers and a little orange dial light.
func _build() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.36, 0.2, 0.12)
	shape.shape = box
	shape.position.y = 0.1
	add_child(shape)
	var body := CSGBox3D.new()
	body.size = Vector3(0.34, 0.18, 0.1)
	body.position.y = 0.09
	body.material = Decorations.mat(Color(0.62, 0.63, 0.66))
	add_child(body)
	var handle := CSGBox3D.new()
	handle.size = Vector3(0.24, 0.02, 0.02)
	handle.position = Vector3(0, 0.21, 0)
	handle.material = Decorations.mat(Color(0.2, 0.2, 0.22))
	add_child(handle)
	for side in [-1, 1]:
		var speaker := CSGCylinder3D.new()
		speaker.radius = 0.055
		speaker.height = 0.01
		speaker.rotation_degrees.x = 90.0
		speaker.position = Vector3(side * 0.1, 0.09, 0.05)
		speaker.material = Decorations.mat(Color(0.12, 0.12, 0.13))
		add_child(speaker)
	_dial = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.06, 0.025)
	_dial.mesh = quad
	_dial.position = Vector3(0, 0.15, 0.051)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 0.6, 0.2)
	m.emission_enabled = true
	m.emission = Color(1, 0.6, 0.2)
	_dial.material_override = m
	add_child(_dial)


## Puts a radio on the kitchen counter, facing the room.
static func on_kitchen_counter(house: Node3D, songs: PackedStringArray, volume := -10.0) -> Radio:
	var r := Radio.new()
	r.name = "KitchenRadio"
	r.playlist = songs
	r.volume_db = volume
	r.position = Vector3(6.78, 0.94, 0.25)
	r.rotation_degrees.y = -90.0
	house.add_child(r)
	return r
