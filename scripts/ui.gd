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
	var p := panel(Vector2(300, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	p.add_child(box)
	box.add_child(label("Settings", 16, GOLD))
	for row in [["Master volume", "master"], ["Music", "music"], ["Voices", "voice"], ["Sound effects", "sfx"],
			["Mouse sensitivity", "sensitivity"]]:
		var h := HBoxContainer.new()
		var name := label(row[0], 11)
		name.custom_minimum_size.x = 120
		h.add_child(name)
		var s := HSlider.new()
		s.min_value = 0.0 if row[1] != "sensitivity" else 0.2
		s.max_value = 1.0 if row[1] != "sensitivity" else 2.5
		s.step = 0.05
		s.value = Game.settings[row[1]]
		s.custom_minimum_size.x = 150
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var key: String = row[1]
		s.value_changed.connect(func(v: float) -> void:
			Game.settings[key] = v
			Game.apply_settings())
		h.add_child(s)
		box.add_child(h)
	for row in [["Subtitles", "subtitles"], ["Fullscreen", "fullscreen"]]:
		var c := CheckBox.new()
		c.text = row[0]
		c.button_pressed = Game.settings[row[1]]
		c.add_theme_font_size_override("font_size", 11)
		c.add_theme_color_override("font_color", CREAM)
		var key: String = row[1]
		c.toggled.connect(func(on: bool) -> void:
			Game.settings[key] = on
			Game.apply_settings())
		box.add_child(c)
	box.add_child(button("Back", func() -> void:
		Game.save_game()
		on_back.call()))
	return p


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
		for photo in Game.photos:
			grid.add_child(print_card(photo))
		scroll.add_child(grid)
		box.add_child(scroll)
	box.add_child(button("Back", on_back))
	return p
