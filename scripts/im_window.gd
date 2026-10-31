class_name IMWindow
extends CanvasLayer
## An early-2000s instant-message window, read over someone's shoulder.
## Built in code like the HUD. Lines appear one at a time, as if typed.
## Usage: var im := IMWindow.new(); add_child(im); await im.play(...); im.queue_free()

const GRAY := Color(0.83, 0.82, 0.78)
const TITLE_BLUE := Color(0.04, 0.14, 0.42)
const ME_COLOR := "#c4161c"
const THEM_COLOR := "#1b3fa8"

var _log: RichTextLabel
var _title: Label


func _ready() -> void:
	layer = 5 # under the HUD, so subtitles and thoughts stay on top

	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = GRAY
	style.set_border_width_all(2)
	style.border_color = Color(0.5, 0.5, 0.48)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	frame.add_theme_stylebox_override("panel", style)
	frame.custom_minimum_size = Vector2(470, 250)
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.position -= frame.custom_minimum_size / 2.0 + Vector2(0, 30)
	add_child(frame)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	frame.add_child(column)

	# Title bar.
	var bar := PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = TITLE_BLUE
	bar_style.content_margin_left = 6
	bar_style.content_margin_top = 2
	bar_style.content_margin_bottom = 2
	bar.add_theme_stylebox_override("panel", bar_style)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 11)
	_title.add_theme_color_override("font_color", Color.WHITE)
	bar.add_child(_title)
	column.add_child(bar)

	# The conversation, on white.
	var paper := PanelContainer.new()
	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = Color.WHITE
	paper_style.set_border_width_all(1)
	paper_style.border_color = Color(0.45, 0.45, 0.43)
	paper_style.content_margin_left = 6
	paper_style.content_margin_right = 6
	paper_style.content_margin_top = 4
	paper.add_theme_stylebox_override("panel", paper_style)
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 11)
	_log.add_theme_font_size_override("bold_font_size", 11)
	_log.add_theme_color_override("default_color", Color(0.05, 0.05, 0.05))
	paper.add_child(_log)
	column.add_child(paper)

	# The empty box you'd type in, and a Send button nobody presses.
	var bottom := HBoxContainer.new()
	var box := Panel.new()
	var box_style := paper_style.duplicate() as StyleBoxFlat
	box.add_theme_stylebox_override("panel", box_style)
	box.custom_minimum_size = Vector2(0, 26)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(box)
	var send := Label.new()
	send.text = " Send "
	send.add_theme_font_size_override("font_size", 11)
	send.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	bottom.add_child(send)
	column.add_child(bottom)


## Shows the chat between `me` (whose computer it is) and `them`, one line at
## a time. Each line is [screen_name, text]. Holds on the last line.
func play(me: String, them: String, lines: Array, hold := 3.0) -> void:
	_title.text = "%s - Instant Message" % them
	_log.clear()
	for i in lines.size():
		var l: Array = lines[i]
		var who: String = l[0]
		var color := ME_COLOR if who == me else THEM_COLOR
		if i > 0:
			_log.append_text("\n")
		_log.append_text("[b][color=%s]%s:[/color][/b] %s" % [color, who, l[1]])
		Audio.play_sfx("im_message", null, -14.0, 0.05)
		await get_tree().create_timer(1.2 + (l[1] as String).length() * 0.05).timeout
	await get_tree().create_timer(hold).timeout
