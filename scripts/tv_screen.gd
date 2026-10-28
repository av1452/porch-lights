class_name TvScreen
extends Node
## Puts a live picture on the TV: renders a SubViewport onto the Screen mesh.
## Plays res://media/<channel>.ogv if you add one (Ogg Theora video),
## otherwise draws a built-in animated placeholder (scripts/tv_show.gd).

const CHANNEL_SOUND := {
	"special": "tv_show", "commercial": "tv_ad", "dream": "tv_show",
	"signoff": "tv_signoff", "static": "tv_static", "off": "", "winter": "",
}

@export var screen_path: NodePath = ^"../Screen"
@export var channel := "special":
	set(v):
		channel = v
		if is_inside_tree():
			_apply_channel()

var _viewport: SubViewport
var _show: TvShow
var _video: VideoStreamPlayer
var _sound: AudioStreamPlayer3D
var _material: StandardMaterial3D


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(160, 120)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_show = TvShow.new()
	_viewport.add_child(_show)

	_video = VideoStreamPlayer.new()
	_video.size = Vector2(160, 120)
	_video.expand = true
	_video.bus = "TV"
	_video.finished.connect(func(): _video.play())
	_viewport.add_child(_video)

	# A QuadMesh, so the picture maps 0..1 across the glass.
	var screen := get_node(screen_path) as MeshInstance3D
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color.BLACK
	_material.albedo_texture = _viewport.get_texture()
	_material.emission_enabled = true
	_material.emission_texture = _viewport.get_texture()
	_material.emission_energy_multiplier = 1.6
	_material.roughness = 0.15
	_material.metallic_specular = 0.8
	screen.material_override = _material

	# The TV is still adding its children here, so the speaker lives under us.
	_sound = Audio.make_loop("tv_show", self, -6.0, "TV") as AudioStreamPlayer3D
	_sound.global_position = (get_parent() as Node3D).global_position
	_apply_channel()


func _apply_channel() -> void:
	if _show.channel != channel:
		Audio.play_sfx("tv_off" if channel == "off" else "tv_zap", get_parent(), -8.0)
	_show.channel = channel
	var video_path := "res://media/%s.ogv" % channel
	var has_video := ResourceLoader.exists(video_path)
	if has_video:
		_video.stream = load(video_path)
		_video.visible = true
		_video.play()
	else:
		_video.stop()
		_video.visible = false
	_material.emission_energy_multiplier = 0.0 if channel == "off" else 1.6
	var sound: String = CHANNEL_SOUND.get(channel, "")
	if sound == "" or has_video:
		_sound.stop()
	else:
		_sound.stream = Audio.get_stream("sfx", sound, true)
		_sound.pitch_scale = 0.8 if channel == "dream" else 1.0
		_sound.play()


## Average screen color, so the room's TV light can match the picture.
func light_color() -> Color:
	return _show.light_color()
