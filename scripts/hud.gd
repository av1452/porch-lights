class_name GameHud
extends CanvasLayer
## On-screen UI, built in code so it's easy to restyle.
## Thoughts (memory text), spoken dialogue, objective, chapter cards, fades.

const SPEAKER_COLOR := "#ffd27a"

var _fade: ColorRect
var _dot: Label
var _prompt: Label
var _objective: Label
var _memory: Label
var _line: RichTextLabel
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

	_memory = _make_label("", 12, Color(1, 0.97, 0.9))
	_memory.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_memory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_memory.offset_left = 60
	_memory.offset_right = -60
	_memory.offset_bottom = -22
	_memory.modulate.a = 0.0

	_line = RichTextLabel.new()
	_line.bbcode_enabled = true
	_line.fit_content = true
	_line.scroll_active = false
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_line.offset_left = 50
	_line.offset_right = -50
	_line.offset_top = -100
	_line.offset_bottom = -62
	_line.add_theme_font_size_override("normal_font_size", 12)
	_line.add_theme_color_override("default_color", Color.WHITE)
	_line.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_line.add_theme_constant_override("outline_size", 4)
	_line.modulate.a = 0.0
	add_child(_line)

	_card_title = _make_label("", 24, Color(1, 0.93, 0.8))
	_card_title.offset_bottom = -14
	_card_title.modulate.a = 0.0
	_card_sub = _make_label("", 11, Color(1, 0.93, 0.8, 0.8))
	_card_sub.offset_top = 26
	_card_sub.modulate.a = 0.0


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
	_memory.text = text
	if _memory_tween:
		_memory_tween.kill()
	_memory_tween = create_tween()
	_memory_tween.tween_property(_memory, "modulate:a", 1.0, 0.6)
	_memory_tween.tween_interval(duration)
	_memory_tween.tween_property(_memory, "modulate:a", 0.0, 1.2)


## A spoken line. Empty speaker = narration.
func show_line(speaker: String, text: String) -> void:
	if speaker == "":
		_line.text = "[center][color=#e8dcc8]%s[/color][/center]" % text
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
	if text != "":
		t.tween_property(_objective, "modulate:a", 1.0, 0.8)


## Chapter title over black. Call while the screen is faded out.
func chapter_card(title: String, subtitle: String, hold: float = 2.5) -> void:
	_card_title.text = title
	_card_sub.text = subtitle
	var t := create_tween()
	t.tween_property(_card_title, "modulate:a", 1.0, 1.2)
	t.parallel().tween_property(_card_sub, "modulate:a", 1.0, 1.8)
	t.tween_interval(hold)
	t.tween_property(_card_title, "modulate:a", 0.0, 1.0)
	t.parallel().tween_property(_card_sub, "modulate:a", 0.0, 1.0)
	await t.finished


func fade(to_alpha: float, time: float, color: Color = Color.BLACK) -> Tween:
	_fade.color = Color(color.r, color.g, color.b, _fade.color.a)
	var t := create_tween()
	t.tween_property(_fade, "color:a", to_alpha, time)
	return t
