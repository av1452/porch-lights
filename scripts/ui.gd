class_name UI
## Shared menu pieces, built in code like the HUD: the look (warm text on dark
## panels, like a DVD menu from 2003), the settings panel, and the photo album.

const CREAM := Color(1, 0.93, 0.8)
const GOLD := Color(1, 0.8, 0.45)
const PANEL := Color(0.06, 0.05, 0.08, 0.92)
## The orange date stamp disposable cameras printed in the corner.
const STAMP := Color(1.0, 0.55, 0.15)


static func label(text: String, size: int, color := CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 3)
	return l


static func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(on_press)
	b.mouse_entered.connect(b.grab_focus)
	return b


static func panel(min_size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = Color(1, 0.8, 0.45, 0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = min_size
	return p


static func centered(child: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(child)
	return c


# ---------------------------------------------------------------- settings

static func settings_panel(on_back: Callable) -> Control:
	var p := panel(Vector2(470, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	p.add_child(box)
	box.add_child(label("Settings", 16, GOLD))
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(450, 250)
	tabs.add_theme_font_size_override("font_size", 11)
	box.add_child(tabs)

	var audio := _tab(tabs, "Audio")
	_slider(audio, "Master volume", "master", 0.0, 1.0)
	_slider(audio, "Music", "music", 0.0, 1.0)
	_slider(audio, "Voices", "voice", 0.0, 1.0)
	_slider(audio, "Sound effects", "sfx", 0.0, 1.0)
	_check(audio, "Mono audio", "mono", "Left and right channels play in both ears.")

	var display := _tab(tabs, "Display")
	_check(display, "Fullscreen", "fullscreen")
	_slider(display, "Field of view", "fov", 60.0, 100.0, 1.0)
	_check(display, "Crosshair", "crosshair", "The dot in the middle of the screen. Prompts still show.")

	var controls := _tab(tabs, "Controls")
	_slider(controls, "Look sensitivity", "sensitivity", 0.2, 2.5)
	_check(controls, "Invert look up/down", "invert_y")
	_check(controls, "Toggle run", "toggle_run", "Tap Run once instead of holding it.")
	_check(controls, "Toggle crouch", "toggle_crouch", "Tap Crouch once instead of holding it.")
	controls.add_child(label("Move: WASD / left stick   Look: mouse / right stick\nInteract: E, click / A   Run: Shift / L3   Crouch: C / B   Pause: Esc / Start", 9, Color(1, 0.93, 0.8, 0.7)))

	var text := _tab(tabs, "Text")
	_check(text, "Subtitles for spoken lines", "subtitles", "Narration and Leo's thoughts always show.")
	_choice(text, "Text size", "text_size", Game.TEXT_SIZE_NAMES)
	_check(text, "Background behind text", "text_background", "A dark box behind subtitles, thoughts and captions.")
	_check(text, "Sound captions", "sound_captions", "Writes out important sounds: [Phone ringing], [Biscuit barks].")
	_slider(text, "Text stays on screen", "text_hold", 1.0, 2.5, 0.25, "x")

	var access := _tab(tabs, "Accessibility")
	_check(access, "Read text aloud", "read_aloud", "The system voice reads narration, thoughts, objectives and chapter titles.")
	_check(access, "Narrate menus", "narrate_menus", "The system voice reads each menu item as you select it.")
	_check(access, "Head bob and road shake", "head_bob", "Turn off if movement makes you feel sick.")
	_check(access, "Reduce flashing", "reduce_flashing", "Camera flashes become a soft glow.")
	access.add_child(label("No timed sections, no fail states, and the game pauses anywhere.", 9, Color(1, 0.93, 0.8, 0.7)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(button("Back", func() -> void:
		Game.save_game()
		on_back.call()))
	row.add_child(button("Restore defaults", func() -> void:
		Game.restore_defaults()
		var parent := p.get_parent()
		if parent:
			var fresh := settings_panel(on_back)
			parent.add_child(fresh)
			p.queue_free()))
	box.add_child(row)
	var bar := tabs.get_tab_bar()
	bar.focus_mode = Control.FOCUS_ALL
	_focus_when_shown(p, bar)
	return p


static func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = title
	v.add_theme_constant_override("separation", 4)
	tabs.add_child(v)
	return v


static func _apply(key: String, value: Variant) -> void:
	Game.settings[key] = value
	Game.apply_settings()


static func _slider(parent: Control, text: String, key: String, lo: float, hi: float, step := 0.05, suffix := "") -> void:
	var h := HBoxContainer.new()
	var name := label(text, 11)
	name.custom_minimum_size.x = 170
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_child(name)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Game.settings[key])
	s.custom_minimum_size.x = 170
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.tooltip_text = text
	h.add_child(s)
	var shown := label("", 10)
	shown.custom_minimum_size.x = 50
	var fmt := func(v: float) -> String:
		if suffix == "x":
			return "%.2fx" % v
		if hi > 10.0:
			return "%d" % int(v)
		return "%d%%" % int(round(v * 100.0))
	shown.text = fmt.call(s.value)
	h.add_child(shown)
	s.value_changed.connect(func(v: float) -> void:
		shown.text = fmt.call(v)
		_apply(key, v)
		if Game.settings.narrate_menus:
			Game.speak_aloud(shown.text))
	parent.add_child(h)


## Checkbox icons drawn here, so an unticked box is visible on the dark panel.
static var _box_icons := {}


static func _check_icon(ticked: bool) -> Texture2D:
	if _box_icons.has(ticked):
		return _box_icons[ticked]
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 14:
		for e in [0, 1, 12, 13]:
			img.set_pixel(i, e, CREAM)
			img.set_pixel(e, i, CREAM)
	if ticked:
		for i in range(4, 10):
			for j in range(4, 10):
				img.set_pixel(i, j, GOLD)
	_box_icons[ticked] = ImageTexture.create_from_image(img)
	return _box_icons[ticked]


static func _check(parent: Control, text: String, key: String, help := "") -> void:
	var c := CheckBox.new()
	c.add_theme_icon_override("unchecked", _check_icon(false))
	c.add_theme_icon_override("checked", _check_icon(true))
	c.text = text
	c.button_pressed = bool(Game.settings[key])
	c.add_theme_font_size_override("font_size", 11)
	c.add_theme_color_override("font_color", CREAM)
	c.add_theme_color_override("font_focus_color", GOLD)
	c.tooltip_text = help
	c.toggled.connect(func(on: bool) -> void:
		_apply(key, on)
		if Game.settings.narrate_menus:
			Game.speak_aloud("%s, %s" % [text, "on" if on else "off"]))
	parent.add_child(c)
	if help != "":
		var l := label("    " + help, 9, Color(1, 0.93, 0.8, 0.6))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		parent.add_child(l)


static func _choice(parent: Control, text: String, key: String, options: Array) -> void:
	var h := HBoxContainer.new()
	var name := label(text, 11)
	name.custom_minimum_size.x = 170
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_child(name)
	var o := OptionButton.new()
	for opt in options:
		o.add_item(opt)
	o.selected = int(Game.settings[key])
	o.add_theme_font_size_override("font_size", 11)
	o.tooltip_text = text
	o.item_selected.connect(func(i: int) -> void:
		_apply(key, i)
		if Game.settings.narrate_menus:
			Game.speak_aloud(options[i]))
	h.add_child(o)
	parent.add_child(h)


## Controllers need something selected the moment a screen opens.
static func _focus_when_shown(screen: Control, target: Control) -> void:
	screen.tree_entered.connect(func() -> void: target.grab_focus.call_deferred(), CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- album

## One developed print: white border, the picture, the orange date stamp,
## and a caption written underneath like on the back of the envelope.
static func print_card(photo: Dictionary) -> Control:
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.95, 0.92)
	sb.set_content_margin_all(5)
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 3
	frame.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	frame.add_child(v)
	var pic := Control.new()
	pic.custom_minimum_size = Vector2(128, 72)
	v.add_child(pic)
	var tex: Texture2D = null
	if photo.file != "" and FileAccess.file_exists(photo.file):
		var img := Image.load_from_file(ProjectSettings.globalize_path(photo.file))
		if img:
			tex = ImageTexture.create_from_image(img)
	if tex:
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Drugstore film: a little warm, a little faded.
		r.modulate = Color(1.0, 0.95, 0.86)
		pic.add_child(r)
	else:
		var blank := ColorRect.new()
		blank.color = Color(0.2, 0.18, 0.16)
		blank.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.add_child(blank)
	var stamp := label(photo.stamp, 7, STAMP)
	stamp.add_theme_constant_override("outline_size", 0)
	stamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	stamp.offset_right = -4
	stamp.offset_bottom = -2
	pic.add_child(stamp)
	var cap := label(photo.caption, 8, Color(0.25, 0.22, 0.3))
	cap.add_theme_constant_override("outline_size", 0)
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.custom_minimum_size.x = 128
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	return frame


static func album(on_back: Callable, heading := "Photo Album") -> Control:
	var p := panel(Vector2(560, 300))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)
	box.add_child(label(heading, 16, GOLD))
	if Game.photos.is_empty():
		box.add_child(label("No pictures yet. Somebody always has a disposable camera on the holidays.", 11))
	else:
		box.add_child(label("%d of 27 exposures. Developed at the drugstore, one-hour photo." % Game.photos.size(), 9, Color(1, 0.93, 0.8, 0.7)))
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(540, 230)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 18)
		grid.add_theme_constant_override("v_separation", 14)
		scroll.follow_focus = true
		for photo in Game.photos:
			var card := print_card(photo)
			# Focusable, so a controller can scroll through the prints.
			card.focus_mode = Control.FOCUS_ALL
			grid.add_child(card)
		scroll.add_child(grid)
		box.add_child(scroll)
	var back := button("Back", on_back)
	box.add_child(back)
	_focus_when_shown(p, back)
	return p
