extends SceneTree
## Records the Porch Lights trailer with Godot's Movie Maker: a ~60-second tour
## of the chapters with slow camera moves, title cards and the closing music.
##
##   ~/Downloads/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 \
##       --fixed-fps 30 --write-movie builds/trailer.avi -s res://tools/trailer.gd
##
## The HUD is hidden and voices, TVs and in-scene music are muted, so one music
## track runs underneath. Each shot loads a chapter, sets the moment up behind
## a black screen, then a free camera glides between two points.

const MUSIC := "res://audio/music/ending.mp3"
const ITCH := "aidanbuilds.itch.io/porch-lights"
const SHOT := 5.0
const FADE := 0.35
## Setup behind the black screen runs this many times faster, so a scene that
## needs a few seconds to get into position only costs a few frames of black.
const SETUP_SPEED := 20.0

var ch: Node
var _black: ColorRect
var _card: Label
var _title: Label
var _sub: Label
var _music: AudioStreamPlayer


func _initialize() -> void:
	_overlay()
	await process_frame
	for bus in ["Music", "Voice", "TV", "Muffled"]:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), true)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), -10.0)
	_music = AudioStreamPlayer.new()
	_music.stream = load(MUSIC)
	_music.volume_db = -30.0
	root.add_child(_music)
	_music.play(6.0)
	create_tween().tween_property(_music, "volume_db", -4.0, 3.0)

	# 1. Halloween
	await _shot("res://scenes/chapter_1_halloween.tscn", func() -> void: pass,
		Vector3(1.9, 1.15, 2.3), Vector3(-1.5, 1.0, -1.5), Vector3(0.6, 1.1, 0.9), Vector3(-0.6, 0.9, -2.2), "October 31")
	# 2. The dream hallway (same scene)
	await _shot("", func() -> void: ch._enter_dream(),
		Vector3(2.0, 1.05, -9.0), Vector3(2.0, 0.9, -26.0), Vector3(2.0, 1.0, -19.5), Vector3(2.0, 0.6, -26.0), "Some nights, the hallway keeps going.")
	# 3. Thanksgiving
	await _shot("res://scenes/chapter_2_thanksgiving.tscn", func() -> void: pass,
		Vector3(0.7, 1.25, 1.2), Vector3(-2.3, 0.5, -0.9), Vector3(0.1, 1.15, 0.4), Vector3(-2.3, 0.45, -1.3), "Thanksgiving at Grandma's")
	# 4. The drive home, snow in the headlights
	await _shot("res://scenes/chapter_3_drive_home.tscn", func() -> void: ch._snow.emitting = true,
		Vector3(0.38, 1.0, 0.62), Vector3(-0.6, 0.85, -3.0), Vector3(0.36, 1.0, 0.6), Vector3(0.4, 0.95, -3.0), "The long drive home", "Cabin")
	# 5. "IT'S SNOWING!"
	await _shot("res://scenes/school_class_party.tscn", func() -> void:
			ch._first_snow()
			await create_timer(5.0).timeout,
		Vector3(-1.6, 1.3, 2.4), Vector3(-4.9, 1.5, -0.6), Vector3(-2.4, 1.25, 1.2), Vector3(-4.9, 1.45, -0.8), "\"IT'S SNOWING!\"")
	# 6. The snowy school dream
	await _shot("", func() -> void:
			# The dream clears away the real hallway; give it one to clear.
			ch.hall = load("res://scripts/school_hallway.gd").new()
			ch.add_child(ch.hall)
			ch._enter_dream()
			await create_timer(1.0).timeout,
		Vector3(80, 1.1, -6.0), Vector3(80, 1.0, -70.0), Vector3(80, 1.0, -52.0), Vector3(80, 0.9, -70.0), "")
	# 7. Christmas Eve, night, the tree lit
	await _shot("res://scenes/chapter_5_christmas_eve.tscn", func() -> void:
			ch._nightfall()
			load("res://scripts/decorations.gd").light_tree({"bulbs": ch._bulb_mats, "glow": ch._tree_glow}, true)
			ch.set_porch_light(true)
			ch.tv_screen.channel = "christmas"
			ch.dad.position = Vector3(6.0, 0.0, -0.6)
			ch.mom.position = Vector3(-1.5, 0.0, 0.9)
			ch.mom.rotation.y = deg_to_rad(-150.0)
			ch.jamie.position = Vector3(-0.9, 0.0, -1.1)
			ch.jamie.rotation.y = deg_to_rad(-70.0),
		Vector3(1.7, 1.25, 1.7), Vector3(-2.15, 0.8, -0.65), Vector3(1.1, 1.1, 0.8), Vector3(-2.15, 0.75, -0.65), "Christmas Eve")
	# 8. Winter break: the snowman, Biscuit running laps
	await _shot("res://scenes/winter_break_days.tscn", func() -> void:
			ch.front_door.interact(ch.player)
			ch._on_porch()
			for i in 3:
				ch._snow_pile.interact(ch.player)
			ch.busy = false
			await create_timer(2.0).timeout,
		Vector3(-0.9, 1.35, 4.6), Vector3(-2.1, 0.5, 7.6), Vector3(-2.7, 1.1, 5.4), Vector3(-2.1, 0.6, 7.4), "Winter break")
	# 9. The countdown
	await _shot("res://scenes/chapter_7_new_years_eve.tscn", func() -> void:
			ch.tv_screen.start_countdown()
			await create_timer(6.5).timeout,
		Vector3(0.7, 1.05, 0.6), Vector3(-0.5, 0.95, -2.1), Vector3(0.1, 1.0, -0.8), Vector3(-0.5, 0.95, -2.1), "December 31")
	# 10. Every porch light on, then the title
	await _shot("", func() -> void:
			ch.step = ch.Step.END
			ch._final_dream()
			ch._the_porch(),
		Vector3(-2.1, 1.2, 3.4), Vector3(-2.1, 0.9, 18.0), Vector3(-2.1, 1.15, 5.0), Vector3(-2.1, 1.0, 18.0), "", "", 7.0, true)
	await _fade(1.0, 1.2)
	await create_timer(1.0).timeout
	create_tween().tween_property(_music, "volume_db", -40.0, 1.5)
	await create_timer(1.6).timeout
	quit()


## Loads `path` (or keeps the current chapter if ""), runs `setup` behind black,
## then glides a free camera from A to B with an optional card.
func _shot(path: String, setup: Callable, from: Vector3, from_look: Vector3, to: Vector3, to_look: Vector3,
		card: String, parent_path := "", length := SHOT, title := false) -> void:
	Engine.time_scale = SETUP_SPEED
	if path != "":
		if ch:
			ch.queue_free()
			await process_frame
		ch = load(path).instantiate()
		root.add_child(ch)
		current_scene = ch
	await create_timer(0.5).timeout
	ch.get_node("HUD").visible = false
	await setup.call()
	ch.get_node("HUD").visible = false
	# The drive-home camera rides inside the van's cabin, so it bounces with it.
	var parent: Node3D = ch.car.get_node("Cabin") if parent_path == "Cabin" else ch
	var cam := Camera3D.new()
	cam.fov = 70.0
	parent.add_child(cam)
	cam.position = from
	cam.look_at(_global(parent, from_look))
	cam.make_current()
	var start_basis := cam.transform.basis
	var end := Transform3D(Basis(), to)
	cam.position = to
	cam.look_at(_global(parent, to_look))
	end = cam.transform
	cam.transform = Transform3D(start_basis, from)
	Engine.time_scale = 1.0
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(cam, "transform", end, length)
	await _fade(0.0, FADE)
	if card != "":
		_show(_card, card, length - FADE * 2.0 - 0.4)
	if title:
		await create_timer(2.5).timeout
		_show(_title, "PORCH LIGHTS", length)
		await create_timer(0.8).timeout
		_show(_sub, "Free to play on itch.io  ·  " + ITCH, length)
		await create_timer(length - 3.3).timeout
		return
	await create_timer(length - FADE * 2.0).timeout
	await _fade(1.0, FADE)
	cam.queue_free()


func _global(parent: Node3D, local_point: Vector3) -> Vector3:
	return parent.global_transform * local_point if parent != ch else local_point


func _fade(to: float, time: float) -> void:
	await create_tween().tween_property(_black, "color:a", to, time).finished


func _show(l: Label, text: String, hold: float) -> void:
	l.text = text
	var t := create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.6)
	t.tween_interval(maxf(hold, 0.5))
	t.tween_property(l, "modulate:a", 0.0, 0.6)


func _overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	root.add_child(layer)
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 1)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_black)
	_card = _label(layer, 20, Color(1, 0.93, 0.8), Control.PRESET_BOTTOM_WIDE, -70.0)
	_title = _label(layer, 46, Color(1, 0.88, 0.6), Control.PRESET_CENTER, -24.0)
	_sub = _label(layer, 14, Color(1, 0.95, 0.88), Control.PRESET_CENTER, 34.0)


func _label(layer: CanvasLayer, size: int, color: Color, preset: Control.LayoutPreset, y: float) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(preset)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	l.offset_top += y
	l.offset_bottom += y
	l.modulate.a = 0.0
	layer.add_child(l)
	return l
