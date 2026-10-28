extends Control
## Title screen: a quiet night street with one porch light on, snow falling,
## and the lullaby. Continue, New Game, Chapters, Photo Album, Settings, Quit.

var _menu: Control
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Game.current = -1
	_add_snow()
	Audio.play_music("ch1_living_room", 2.0, -4.0)
	_show_main()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## The backdrop, drawn like the TV shows: sky, houses, and our porch light.
func _draw() -> void:
	var s := size
	for i in 24:
		draw_rect(Rect2(0, s.y * i / 24.0, s.x, s.y / 24.0 + 1), Color(0.02, 0.03, 0.08).lerp(Color(0.12, 0.09, 0.16), i / 23.0))
	draw_circle(Vector2(s.x * 0.82, s.y * 0.16), 18, Color(1, 0.97, 0.88, 0.9))
	var ground := s.y * 0.78
	# snow at night: blue-gray, a little brighter toward our porch light
	for i in 10:
		draw_rect(Rect2(0, ground + (s.y - ground) * i / 10.0, s.x, (s.y - ground) / 10.0 + 1),
			Color(0.42, 0.46, 0.58).lerp(Color(0.25, 0.27, 0.36), i / 9.0))
	# a row of houses; ours is the one in the middle with its light on
	for i in 5:
		var w := s.x * 0.17
		var x := s.x * (0.02 + i * 0.2)
		var h := s.y * (0.16 + 0.03 * (i % 2))
		var body := Rect2(x, ground - h, w, h)
		draw_rect(body, Color(0.07, 0.07, 0.11))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, ground - h), Vector2(x + w / 2, ground - h - s.y * 0.09), Vector2(x + w + 6, ground - h)]), Color(0.05, 0.05, 0.08))
		draw_rect(Rect2(x + w * 0.15, ground - h * 0.7, w * 0.22, h * 0.3), Color(1, 0.75, 0.4, 0.8 if i == 2 else 0.18))
		draw_rect(Rect2(x + w * 0.55, ground - h * 0.6, w * 0.16, h * 0.6), Color(0.15, 0.1, 0.08))
		if i == 2:
			var lamp := Vector2(x + w * 0.78, ground - h * 0.62)
			var pulse := 1.0 + sin(_t * 1.3) * 0.06
			for r in range(60, 0, -6):
				draw_circle(lamp, r * pulse, Color(1, 0.75, 0.4, 0.035))
			draw_circle(lamp, 4, Color(1, 0.9, 0.7))
	# a soft shade on the left so the menu text sits on something
	for i in 12:
		draw_rect(Rect2(s.x * 0.04 * i, 0, s.x * 0.04, s.y), Color(0, 0, 0, 0.4 * (1.0 - i / 12.0)))


func _add_snow() -> void:
	var snow := CPUParticles2D.new()
	snow.amount = 160
	snow.lifetime = 12.0
	snow.preprocess = 12.0
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(600, 4)
	snow.position = Vector2(400, -10)
	snow.direction = Vector2(0.15, 1)
	snow.spread = 20.0
	snow.gravity = Vector2(4, 12)
	snow.initial_velocity_min = 10.0
	snow.initial_velocity_max = 25.0
	snow.scale_amount_min = 1.0
	snow.scale_amount_max = 2.2
	snow.color = Color(1, 1, 1, 0.8)
	add_child(snow)


func _swap(content: Control) -> void:
	if _menu:
		_menu.queue_free()
	_menu = content
	add_child(_menu)


func _show_main() -> void:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 36)
	root.add_theme_constant_override("margin_top", 40)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	root.add_child(box)
	box.add_child(UI.label("Porch Lights", 30, UI.CREAM))
	box.add_child(UI.label("Halloween to winter break, 2003", 11, UI.GOLD))
	var gap := Control.new()
	gap.custom_minimum_size.y = 20
	box.add_child(gap)
	var first: Button = null
	if Game.reached > 0:
		first = UI.button("Continue: " + Game.CHAPTERS[Game.reached].title, func() -> void: Game.start_chapter(Game.reached))
		box.add_child(first)
	var new_game := UI.button("New Game", Game.new_game)
	box.add_child(new_game)
	box.add_child(UI.button("Chapters", _show_chapters))
	box.add_child(UI.button("Photo Album", func() -> void: _swap(UI.centered(UI.album(_show_main)))))
	box.add_child(UI.button("Settings", func() -> void: _swap(UI.centered(UI.settings_panel(_show_main)))))
	box.add_child(UI.button("Quit", func() -> void: get_tree().quit()))
	_swap(root)
	(first if first else new_game).grab_focus()


func _show_chapters() -> void:
	var p := UI.panel(Vector2(320, 0))
	var box := VBoxContainer.new()
	p.add_child(box)
	box.add_child(UI.label("Chapters", 16, UI.GOLD))
	var unlocked := Game.CHAPTERS.size() if Game.finished else Game.reached + 1
	for i in Game.CHAPTERS.size():
		var c: Dictionary = Game.CHAPTERS[i]
		if i < unlocked:
			box.add_child(UI.button("%s  ·  %s" % [c.date, c.title], func() -> void: Game.start_chapter(i)))
		else:
			box.add_child(UI.label("   ? ? ?", 13, Color(1, 0.93, 0.8, 0.3)))
	box.add_child(UI.button("Back", _show_main))
	_swap(UI.centered(p))
