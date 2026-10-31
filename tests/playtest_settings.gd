extends SceneTree
# Accessibility and settings: turns each option on and checks it takes
# effect. Run headless: godot --headless -s res://tests/playtest_settings.gd
var ch
func axis(a: JoyAxis, v: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = a
	ev.axis_value = v
	Input.parse_input_event(ev)
func set_setting(k: String, v: Variant) -> void:
	var game = root.get_node("Game")
	game.settings[k] = v
	game.apply_settings()
func _initialize():
	var game = root.get_node("Game")
	Engine.time_scale = 6.0
	ch = load("res://scenes/chapter_1_halloween.tscn").instantiate()
	root.add_child(ch)
	current_scene = ch
	await create_timer(9.0).timeout
	Engine.time_scale = 1.0
	var hud = ch.hud
	var p = ch.player
	# Mono
	set_setting("mono", true)
	var master := AudioServer.get_bus_index("Master")
	var has_mono := false
	for i in AudioServer.get_bus_effect_count(master):
		has_mono = has_mono or AudioServer.get_bus_effect(master, i) is AudioEffectStereoEnhance
	print("mono effect=", has_mono)
	set_setting("mono", false)
	# Text size + background
	var small: int = hud._line.get_theme_font_size("normal_font_size")
	set_setting("text_size", 3)
	print("text size grows=", hud._line.get_theme_font_size("normal_font_size") > small)
	set_setting("text_background", true)
	print("background box=", hud._line.get_theme_stylebox("normal") is StyleBoxFlat)
	# Captions
	set_setting("sound_captions", true)
	root.get_node("Audio").play_sfx("phone_ring")
	await create_timer(0.4).timeout
	print("caption=", hud._caption.text, " visible=", hud._caption.modulate.a > 0.5)
	# Reduced flashing: a camera flash tops out low.
	set_setting("reduce_flashing", true)
	await hud.fade(0.85, 0.05, Color.WHITE).finished
	print("flash softened=", hud._fade.color.a <= 0.21)
	await hud.fade(0.0, 0.1).finished
	# Toggle crouch
	set_setting("toggle_crouch", true)
	var ev := InputEventAction.new()
	ev.action = "crouch"; ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.2).timeout
	ev = ev.duplicate(); ev.pressed = false
	Input.parse_input_event(ev)
	await create_timer(0.3).timeout
	print("toggle crouch stays down after release=", p.crouching)
	set_setting("toggle_crouch", false)
	await create_timer(0.2).timeout
	# Invert look
	set_setting("invert_y", true)
	var pitch0: float = p.head.rotation.x
	axis(JOY_AXIS_RIGHT_Y, -1.0)
	await create_timer(0.3).timeout
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	print("inverted: stick up looks down=", p.head.rotation.x < pitch0)
	# FOV
	set_setting("fov", 90.0)
	print("fov=", p.camera.fov)
	# Settings menu builds, with all five tabs.
	var panel = load("res://scripts/ui.gd").settings_panel(func() -> void: pass)
	root.add_child(panel)
	var tabs: TabContainer = panel.find_children("*", "TabContainer", true, false)[0]
	print("tabs=", range(tabs.get_tab_count()).map(func(i): return tabs.get_tab_title(i)))
	game.restore_defaults()
	print("defaults restored: fov=", game.settings.fov, " text_size=", game.settings.text_size)
	quit()
