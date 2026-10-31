class_name GameHud
extends CanvasLayer
## On-screen UI, built in code so it's easy to restyle.
## Thoughts (memory text), spoken dialogue, objective, chapter cards, fades.

const SPEAKER_COLOR := "#ffd27a"

var _fade: ColorRect
var _dot: Label
var _prompt: Label
var _objective: Label
var _memory: RichTextLabel
var _line: RichTextLabel
var _caption: Label
var _caption_tween: Tween
var _card_title: Label
var _card_sub: Label
var _memory_tween: Tween
var _line_tween: Tween
var _target: Interactable


func _ready() -> void:
	add_to_group("hud")
	layer = 10

	# Fade first, so text draws on top of black (cinematic transitions).
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

	_dot = _make_label("•", 10, Color(1, 1, 1, 0.7))
	_prompt = _make_label("", 11, Color(1, 0.95, 0.85))
	_prompt.offset_top = 28

	_objective = _make_label("", 10, Color(1, 0.95, 0.85, 0.85))
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_objective.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_objective.offset_left = 14
	_objective.offset_top = 10
	_objective.modulate.a = 0.0

	# Thoughts (bottom) and spoken lines (just above), each sized to its text
	# and growing upward, so the optional background box hugs the words.
	_memory = _text_block(60, -22, Color(1, 0.97, 0.9))
	_line = _text_block(50, -62, Color.WHITE)

	_caption = _make_label("", 10, Color(0.85, 0.92, 1.0))
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption.offset_top = 32
	_caption.modulate.a = 0.0

	_card_title = _make_label("", 24, Color(1, 0.93, 0.8))
	_card_title.offset_bottom = -14
	_card_title.modulate.a = 0.0
	_card_sub = _make_label("", 11, Color(1, 0.93, 0.8, 0.8))
	_card_sub.offset_top = 26
	_card_sub.modulate.a = 0.0
	apply_settings()


func _text_block(side: float, bottom: float, color: Color) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	r.grow_vertical = Control.GROW_DIRECTION_BEGIN
	r.offset_left = side
	r.offset_right = -side
	r.offset_top = bottom
	r.offset_bottom = bottom
	r.add_theme_color_override("default_color", color)
	r.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	r.add_theme_constant_override("outline_size", 4)
	r.modulate.a = 0.0
	add_child(r)
	return r


## Text size, subtitle background and crosshair, from Game.settings. Called
## at start and whenever a setting changes.
func apply_settings() -> void:
	var k: float = Game.TEXT_SCALES[clampi(int(Game.settings.text_size), 0, Game.TEXT_SCALES.size() - 1)]
	for pair in [[_memory, 12], [_line, 12]]:
		(pair[0] as RichTextLabel).add_theme_font_size_override("normal_font_size", int(round(pair[1] * k)))
	for pair in [[_objective, 10], [_prompt, 11], [_caption, 10]]:
		(pair[0] as Label).add_theme_font_size_override("font_size", int(round(pair[1] * k)))
	var box: StyleBox = StyleBoxEmpty.new()
	if Game.settings.text_background:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0, 0, 0, 0.72)
		flat.set_corner_radius_all(4)
		flat.content_margin_left = 10
		flat.content_margin_right = 10
		flat.content_margin_top = 4
		flat.content_margin_bottom = 4
		box = flat
	for r in [_memory, _line]:
		(r as RichTextLabel).add_theme_stylebox_override("normal", box)
	_caption.add_theme_stylebox_override("normal", box)
	_dot.self_modulate.a = 1.0 if Game.settings.crosshair else 0.0


## A sound, written out ("[Phone ringing]"), when sound captions are on.
func show_caption(text: String) -> void:
	if not Game.settings.sound_captions:
		return
	_caption.text = text
	if _caption_tween:
		_caption_tween.kill()
	_caption_tween = create_tween()
	_caption_tween.tween_property(_caption, "modulate:a", 1.0, 0.2)
	_caption_tween.tween_interval(2.5 * Game.settings.text_hold)
	_caption_tween.tween_property(_caption, "modulate:a", 0.0, 0.8)


func _process(_delta: float) -> void:
	# Prompts can change at runtime ("Knock" -> "Go in"), so keep them fresh.
	if is_instance_valid(_target) and _dot.visible:
		_prompt.text = _target.prompt


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	return l


func set_target(target: Interactable) -> void:
	_target = target
	if target and _dot.visible:
		_prompt.text = target.prompt
		_dot.modulate = Color(1, 0.85, 0.5)
	else:
		_prompt.text = ""
		_dot.modulate = Color.WHITE


func set_crosshair_visible(v: bool) -> void:
	_dot.visible = v
	if not v:
		_prompt.text = ""


## A thought. Fades in, lingers, fades out.
func show_memory(text: String, duration: float = 5.0) -> void:
	_memory.text = "[center]%s[/center]" % text
	duration *= Game.settings.text_hold
	if Game.settings.read_aloud:
		Game.speak_aloud(text)
	if _memory_tween:
		_memory_tween.kill()
	_memory_tween = create_tween()
	_memory_tween.tween_property(_memory, "modulate:a", 1.0, 0.6)
	_memory_tween.tween_interval(duration)
	_memory_tween.tween_property(_memory, "modulate:a", 0.0, 1.2)


## A spoken line. Empty speaker = narration.
func show_line(speaker: String, text: String) -> void:
	# Spoken lines can be turned off in Settings; narration always shows,
	# since it's the only way to hear what Leo's thinking.
	if speaker != "" and not Game.settings.subtitles:
		return
	if speaker == "":
		_line.text = "[center][color=#e8dcc8]%s[/color][/center]" % text
		# Narration has no recorded voice; read it aloud if asked.
		if Game.settings.read_aloud:
			Game.speak_aloud(text)
	else:
		_line.text = "[center][color=%s]%s[/color]   %s[/center]" % [SPEAKER_COLOR, speaker, text]
	if _line_tween:
		_line_tween.kill()
	_line_tween = create_tween()
	_line_tween.tween_property(_line, "modulate:a", 1.0, 0.25)


func clear_line() -> void:
	if _line_tween:
		_line_tween.kill()
	_line_tween = create_tween()
	_line_tween.tween_property(_line, "modulate:a", 0.0, 0.5)


func set_objective(text: String) -> void:
	var t := create_tween()
	t.tween_property(_objective, "modulate:a", 0.0, 0.4)
	t.tween_callback(func() -> void: _objective.text = ("▸ " + text) if text != "" else "")
	if text != "" and Game.settings.read_aloud:
		Game.speak_aloud("Objective: " + text, false)
	if text != "":
		t.tween_property(_objective, "modulate:a", 1.0, 0.8)


## Chapter title over black. Call while the screen is faded out.
func chapter_card(title: String, subtitle: String, hold: float = 2.5) -> void:
	_card_title.text = title
	_card_sub.text = subtitle
	if Game.settings.read_aloud:
		Game.speak_aloud("%s. %s." % [title, subtitle])
	var t := create_tween()
	t.tween_property(_card_title, "modulate:a", 1.0, 1.2)
	t.parallel().tween_property(_card_sub, "modulate:a", 1.0, 1.8)
	t.tween_interval(hold)
	t.tween_property(_card_title, "modulate:a", 0.0, 1.0)
	t.parallel().tween_property(_card_sub, "modulate:a", 0.0, 1.0)
	await t.finished


func fade(to_alpha: float, time: float, color: Color = Color.BLACK) -> Tween:
	# Camera flashes are a quick white pop; with reduced flashing they're a soft glow.
	if Game.settings.reduce_flashing and color.v > 0.9 and color.s < 0.1 and time < 0.2 and to_alpha > 0.3:
		to_alpha = 0.2
		time = 0.4
	_fade.color = Color(color.r, color.g, color.b, _fade.color.a)
	var t := create_tween()
	t.tween_property(_fade, "color:a", to_alpha, time)
	return t
