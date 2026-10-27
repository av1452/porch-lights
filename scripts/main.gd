extends Node3D
## Chapter 1: Halloween night in the living room.
## Lie on the couch to fall asleep. In the dream, the hallway keeps going.
## Waking up hands off to Chapter 2 (scripts/chapter2.gd).
## Debug: run with `-- --chapter=2` to skip straight to chapter 2.

@onready var player: Player = $Player
@onready var hud: GameHud = $HUD
@onready var env: Environment = $WorldEnvironment.environment
@onready var lamp: OmniLight3D = $Lights/Lamp
@onready var tv_glow: OmniLight3D = $Lights/TVGlow
@onready var room: Node3D = $Room
@onready var hall_end_wall: Node3D = $Room/HallEndWall
@onready var dream_hall: Node3D = $DreamHall
@onready var couch: Interactable = $Interactables/Couch
@onready var dream_door: Interactable = $DreamHall/DreamDoor
@onready var tv: Interactable = $Interactables/TV
@onready var tv_screen: TvScreen = $Interactables/TV/ScreenFeed
@onready var dog: Dog = $Biscuit
@onready var blanket: Node3D = $Interactables/Couch/Blanket
@onready var porch_light: OmniLight3D = $Porch/PorchLight
@onready var porch_bulb: CSGShape3D = $Porch/PorchLamp
@onready var front_door: Interactable = $Interactables/FrontDoorHinge/FrontDoor
@onready var porch_switch: Interactable = $Interactables/PorchSwitch
@onready var chapter2: Node = $Chapter2

var chapter := 1
var dreaming := false
var _busy := false
var _awake_state := {}
var _flicker_t := 0.0
var _jingle_done := false
var _crickets: AudioStreamPlayer3D


func _ready() -> void:
	player.target_changed.connect(hud.set_target)
	couch.used.connect(_on_couch_used)
	dream_door.used.connect(_on_dream_door_used)
	tv.used.connect(_on_tv_used)
	front_door.used.connect(_on_front_door_used)
	porch_switch.used.connect(_on_switch_used)
	dog.player = player

	_awake_state = {
		"fog_density": env.fog_density,
		"fog_light_color": env.fog_light_color,
		"ambient_light_color": env.ambient_light_color,
		"ambient_light_energy": env.ambient_light_energy,
		"background_color": env.background_color,
		"lamp_energy": lamp.light_energy,
		"tv_energy": tv_glow.light_energy,
		"tv_color": tv_glow.light_color,
	}
	remove_child(dream_hall) # only exists while dreaming
	blanket.visible = false

	Audio.make_loop("room_tone", self, -18.0, "SFX", false)
	Audio.make_loop("clock_tick", $Room/Clock, -16.0)
	_crickets = Audio.make_loop("crickets", $Porch/Ambience, -6.0) as AudioStreamPlayer3D
	_crickets.unit_size = 8.0
	Audio.make_loop("wind", $Porch/Ambience, -14.0)

	if _start_chapter() == 2:
		chapter2.call("start", true)
		return

	_lock(true)
	await hud.show_title("PORCH LIGHTS", "Chapter 1 - Halloween Night", 2.5).finished
	Audio.play_music("ch1_living_room", 4.0)
	hud.fade(0.0, 2.5)
	_lock(false)
	await get_tree().create_timer(1.5).timeout
	Audio.say("ch1_intro")
	_mom_bedtime()


func _start_chapter() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--chapter="):
			return int(arg.get_slice("=", 1))
	return 1


func _mom_bedtime() -> void:
	await get_tree().create_timer(75.0).timeout
	if chapter == 1 and not dreaming and not _busy:
		Audio.say("ch1_mom_bedtime")


func _exit_tree() -> void:
	# Free whichever pieces are currently detached from the scene.
	if not dream_hall.is_inside_tree():
		dream_hall.free()
	if not hall_end_wall.is_inside_tree():
		hall_end_wall.free()


func _process(delta: float) -> void:
	if dreaming and not _jingle_done and player.global_position.z < -11.0:
		_jingle_done = true
		Audio.play_sfx("dog_tags", Vector3(2.0, 0.4, -20.0), 4.0)
		get_tree().create_timer(1.2).timeout.connect(Audio.say.bind("dream_jingle"))

	# CRT glow flicker, tinted to whatever is on screen.
	_flicker_t -= delta
	if _flicker_t > 0.0:
		return
	_flicker_t = randf_range(0.05, 0.25)
	var base: float = _awake_state.tv_energy * (0.6 if dreaming else 1.0)
	if tv_screen.channel == "off":
		base = 0.0
	tv_glow.light_energy = base * randf_range(0.7, 1.15)
	tv_glow.light_color = tv_glow.light_color.lerp(tv_screen.light_color(), 0.5)


func _lock(locked: bool) -> void:
	player.input_locked = locked
	hud.set_crosshair_visible(not locked)


func set_porch_light(on: bool) -> void:
	porch_light.visible = on
	var mat := porch_bulb.material as StandardMaterial3D
	mat.emission_energy_multiplier = 4.0 if on else 0.0


func _on_tv_used(_by: Node) -> void:
	if dreaming or chapter != 1:
		return
	if tv.times_used == 1:
		Audio.say("tv_first")
		return
	tv_screen.channel = "commercial"
	await Audio.say("tv_repeat")
	if tv_screen.channel == "commercial":
		await Audio.say("tv_ad_announcer", tv)
	await get_tree().create_timer(8.0).timeout
	if tv_screen.channel == "commercial":
		tv_screen.channel = "special"


func _on_front_door_used(_by: Node) -> void:
	if chapter == 1:
		Audio.say("front_door_ch1")


func _on_switch_used(_by: Node) -> void:
	if chapter == 1:
		Audio.say("switch_ch1")


func _on_couch_used(_by: Node) -> void:
	if dreaming or _busy:
		return
	if chapter != 1:
		Audio.say("couch_ch2")
		return
	_busy = true
	_lock(true)
	Audio.say("couch")

	# Drift off: the room softens and gets far away.
	var t := create_tween().set_parallel(true)
	t.tween_property(player.camera, "fov", 100.0, 5.0)
	t.tween_property(env, "fog_density", 0.12, 5.0)
	t.tween_property(lamp, "light_energy", 0.3, 5.0)
	Audio.stop_music(5.0)
	await get_tree().create_timer(3.0).timeout
	await hud.fade(1.0, 2.5).finished

	_enter_dream()
	await get_tree().create_timer(1.5).timeout
	await hud.fade(0.0, 3.0).finished
	_lock(false)
	_busy = false
	Audio.say("dream_enter")


func _enter_dream() -> void:
	dreaming = true
	add_child(dream_hall)
	room.remove_child(hall_end_wall)
	dog.set_active(false)
	tv_screen.channel = "dream"
	Audio.set_dreaming(true)
	Audio.play_music("dream_hall", 3.0)
	lamp.light_energy = 0.0
	env.ambient_light_color = Color(0.3, 0.25, 0.5)
	env.ambient_light_energy = 0.5
	env.background_color = Color(0.03, 0.02, 0.07)
	env.fog_light_color = Color(0.2, 0.15, 0.35)
	env.fog_density = 0.06
	player.camera.fov = 90.0
	player.teleport(Vector3(2.0, 0.05, -2.0), 0.0)


func _on_dream_door_used(_by: Node) -> void:
	if not dreaming or _busy:
		return
	_busy = true
	_lock(true)
	Audio.say("dream_door")
	Audio.stop_music(4.0)
	await get_tree().create_timer(2.0).timeout
	var warm := Color(1.0, 0.94, 0.82)
	await hud.fade(1.0, 2.5, warm).finished

	_exit_dream()
	player.teleport(Vector3(0.0, 0.05, 1.1), 0.0)
	# Somebody tucked Leo in and turned things off while he slept.
	blanket.visible = true
	set_porch_light(false)
	lamp.light_energy = _awake_state.lamp_energy * 0.25
	tv_screen.channel = "signoff"
	await get_tree().create_timer(1.0).timeout
	await hud.fade(0.0, 3.0, warm).finished
	_lock(false)
	_busy = false
	await Audio.say("wake")
	chapter2.call("start", false)


func _exit_dream() -> void:
	dreaming = false
	remove_child(dream_hall)
	room.add_child(hall_end_wall)
	dog.set_active(true)
	Audio.set_dreaming(false)
	env.fog_density = _awake_state.fog_density
	env.fog_light_color = _awake_state.fog_light_color
	env.ambient_light_color = _awake_state.ambient_light_color
	env.ambient_light_energy = _awake_state.ambient_light_energy
	env.background_color = _awake_state.background_color
	lamp.light_energy = _awake_state.lamp_energy
	tv_glow.light_color = _awake_state.tv_color
	player.camera.fov = player.base_fov


## Crickets outside, faded in/out by chapter 2.
func fade_crickets(to_db: float, time: float) -> void:
	create_tween().tween_property(_crickets, "volume_db", to_db, time)
