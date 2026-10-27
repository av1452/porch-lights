class_name GameHud
extends CanvasLayer
## Minimal on-screen UI, built in code so it's easy to restyle later.

var _fade: ColorRect
var _dot: Label
var _prompt: Label
var _memory: Label
var _memory_tween: Tween


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
	_dot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_prompt = _make_label("", 11, Color(1, 0.95, 0.85))
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt.offset_top = 28

	_memory = _make_label("", 12, Color(1, 0.97, 0.9))
	_memory.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_memory.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_memory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_memory.offset_left = 60
	_memory.offset_right = -60
	_memory.offset_bottom = -24
	_memory.modulate.a = 0.0

	fade(0.0, 2.5)


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	return l


func set_target(target: Interactable) -> void:
	if target:
		_prompt.text = target.prompt
		_dot.modulate = Color(1, 0.85, 0.5)
	else:
		_prompt.text = ""
		_dot.modulate = Color.WHITE


func show_memory(text: String, duration: float = 5.0) -> void:
	_memory.text = text
	if _memory_tween:
		_memory_tween.kill()
	_memory_tween = create_tween()
	_memory_tween.tween_property(_memory, "modulate:a", 1.0, 0.6)
	_memory_tween.tween_interval(duration)
	_memory_tween.tween_property(_memory, "modulate:a", 0.0, 1.2)


func fade(to_alpha: float, time: float, color: Color = Color.BLACK) -> Tween:
	_fade.color = Color(color.r, color.g, color.b, _fade.color.a)
	var t := create_tween()
	t.tween_property(_fade, "color:a", to_alpha, time)
	return t


func set_crosshair_visible(v: bool) -> void:
	_dot.visible = v
	if not v:
		_prompt.text = ""
