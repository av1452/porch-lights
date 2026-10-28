class_name TvShow
extends Node2D
## Placeholder TV programs drawn live at 160x120: a Halloween cartoon special,
## a winter special, a toy commercial, a dream version, a broadcast sign-off
## and static.
## Replace any of them with a real video via media/<channel>.ogv.

const W := 160.0
const H := 120.0

var channel := "special"
var _t := 0.0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta * (0.4 if channel == "dream" else 1.0)
	queue_redraw()


func light_color() -> Color:
	match channel:
		"commercial":
			return Color.from_hsv(fmod(_t * 0.25, 1.0), 0.5, 1.0)
		"dream":
			return Color(0.7, 0.45, 1.0)
		"winter":
			return Color(0.75, 0.85, 1.0)
		"signoff":
			return Color(0.9, 0.9, 1.0)
		"static":
			return Color(0.8, 0.85, 0.9)
		"off":
			return Color.BLACK
	return Color(0.55, 0.62, 1.0)


func _draw() -> void:
	match channel:
		"special":
			_draw_special(false)
		"dream":
			_draw_special(true)
		"commercial":
			_draw_commercial()
		"winter":
			_draw_winter()
		"signoff":
			_draw_signoff()
		"static":
			_draw_static(1.0)
		_:
			draw_rect(Rect2(0, 0, W, H), Color.BLACK)
			return
	_draw_crt()


func _draw_special(dream: bool) -> void:
	var sky_top := Color(0.05, 0.03, 0.15) if not dream else Color(0.25, 0.05, 0.3)
	var sky_low := Color(0.25, 0.1, 0.3) if not dream else Color(0.05, 0.0, 0.1)
	for i in 12:
		draw_rect(Rect2(0, i * 7, W, 7), sky_top.lerp(sky_low, i / 11.0))
	var moon := Color(1, 0.75, 0.3) if not dream else Color(0.75, 0.9, 1.0)
	draw_circle(Vector2(122, 28), 16, moon)
	draw_circle(Vector2(128, 24), 15 if dream else 0, sky_top)
	# rolling hill and a crooked fence
	var hill := PackedVector2Array([Vector2(0, 85)])
	for x in range(0, 170, 10):
		hill.append(Vector2(x, 82 + sin(x * 0.05 + 1.0) * 6))
	hill.append_array([Vector2(W, H), Vector2(0, H)])
	draw_colored_polygon(hill, Color(0.08, 0.12, 0.08) if not dream else Color(0.1, 0.0, 0.15))
	for x in range(6, 160, 14):
		var lean := sin(x * 1.7) * 2.0
		draw_line(Vector2(x, 86 + sin(x * 0.05 + 1.0) * 6), Vector2(x + lean, 72 + sin(x * 0.05 + 1.0) * 6), Color(0.2, 0.15, 0.1), 2)
	# pumpkins with flickering faces
	for p in [Vector2(30, 96), Vector2(58, 100), Vector2(104, 98)]:
		draw_circle(p, 8, Color(0.95, 0.45, 0.05))
		draw_rect(Rect2(p.x - 1, p.y - 11, 2, 4), Color(0.2, 0.4, 0.1))
		var glow := Color(1, 0.9, 0.3) * (0.7 + 0.3 * sin(_t * 9.0 + p.x))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -2), p + Vector2(-2, -2), p + Vector2(-3.5, -5)]), glow)
		draw_colored_polygon(PackedVector2Array([p + Vector2(2, -2), p + Vector2(5, -2), p + Vector2(3.5, -5)]), glow)
		draw_rect(Rect2(p.x - 4, p.y + 1, 8, 2), glow)
	# bats
	for i in 3:
		var b := Vector2(fmod(_t * 20.0 + i * 55.0, W + 20) - 10, 20 + i * 9 + sin(_t * 3 + i) * 4)
		var flap := sin(_t * 18.0 + i) * 3.0
		draw_polyline(PackedVector2Array([b + Vector2(-5, flap), b, b + Vector2(5, flap)]), Color.BLACK, 1.5)
	# the ghost, drifting (in the dream it stops and stares)
	var gx := 80.0 if dream else fmod(_t * 18.0, W + 40) - 20
	var g := Vector2(gx, 55 + sin(_t * 2.0) * 5)
	var size := 1.8 if dream else 1.0
	var body := PackedVector2Array()
	for a in range(0, 181, 15):
		body.append(g + Vector2(cos(deg_to_rad(180 + a)) * 12, sin(deg_to_rad(180 + a)) * 12) * size)
	for k in 5:
		var x := 12.0 - k * 6.0
		body.append(g + Vector2(x, 14 + (3 if k % 2 == 0 else 0) + sin(_t * 6 + k) * 1.5) * size)
	draw_colored_polygon(body, Color(0.95, 0.95, 1.0, 0.92))
	draw_circle(g + Vector2(-4, -2) * size, 2.2 * size, Color.BLACK)
	draw_circle(g + Vector2(4, -2) * size, 2.2 * size, Color.BLACK)
	draw_circle(g + Vector2(0, 5) * size, (1.0 if dream else 2.5) * size, Color.BLACK)
	if not dream and fmod(_t, 24.0) < 4.0:
		_text("SPOOKY HOLLOW", Vector2(W / 2, 14), 14, Color(1, 0.6, 0.1))
		_text("HALLOWEEN SPECIAL", Vector2(W / 2, 26), 8, Color(1, 1, 1))


func _draw_winter() -> void:
	for i in 12:
		draw_rect(Rect2(0, i * 7, W, 7), Color(0.05, 0.08, 0.2).lerp(Color(0.25, 0.3, 0.5), i / 11.0))
	for i in 20:
		draw_rect(Rect2(fmod(i * 37.0, W), fmod(i * 23.0, 60.0), 1, 1), Color(1, 1, 0.9, 0.6 + 0.4 * sin(_t * 2.0 + i)))
	var hill := PackedVector2Array([Vector2(0, 88)])
	for x in range(0, 170, 10):
		hill.append(Vector2(x, 86 + sin(x * 0.04) * 5))
	hill.append_array([Vector2(W, H), Vector2(0, H)])
	draw_colored_polygon(hill, Color(0.9, 0.93, 1.0))
	# a snowman, and a little house with its light on
	var s := Vector2(46, 86)
	draw_circle(s, 11, Color.WHITE)
	draw_circle(s + Vector2(0, -16), 8, Color.WHITE)
	draw_circle(s + Vector2(0, -28), 6, Color.WHITE)
	draw_rect(Rect2(s.x - 5, s.y - 40, 10, 6), Color(0.1, 0.1, 0.1))
	draw_colored_polygon(PackedVector2Array([s + Vector2(0, -28), s + Vector2(8, -27), s + Vector2(0, -26)]), Color(1, 0.5, 0.1))
	draw_rect(Rect2(108, 66, 30, 20), Color(0.5, 0.25, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(104, 66), Vector2(123, 52), Vector2(142, 66)]), Color(0.3, 0.15, 0.15))
	draw_rect(Rect2(118, 72, 8, 14), Color(0.25, 0.12, 0.08))
	draw_circle(Vector2(129, 70), 2.0, Color(1, 0.75, 0.3))
	for i in 60:
		var p := Vector2(fmod(i * 53.0 + sin(_t + i) * 6.0, W), fmod(i * 17.0 + _t * (10.0 + i % 5), H))
		draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, 0.85))
	if fmod(_t, 20.0) < 4.0:
		_text("A WINTER SPECIAL", Vector2(W / 2, 16), 12, Color(0.9, 0.95, 1.0))


func _draw_commercial() -> void:
	var bg := Color.from_hsv(fmod(_t * 0.25, 1.0), 0.6, 0.9)
	draw_rect(Rect2(0, 0, W, H), bg)
	for i in 8:
		var a := _t * 1.5 + i * TAU / 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(80, 60), Vector2(80, 60) + Vector2(cos(a), sin(a)) * 140, Vector2(80, 60) + Vector2(cos(a + 0.3), sin(a + 0.3)) * 140]), bg.lightened(0.3))
	var x := 80 + sin(_t * 2.0) * 50
	var y := 78 - absf(sin(_t * 4.0)) * 6
	draw_rect(Rect2(x - 22, y - 10, 44, 14), Color(0.85, 0.05, 0.05))
	draw_rect(Rect2(x - 10, y - 20, 22, 11), Color(0.2, 0.2, 0.25))
	draw_rect(Rect2(x - 6, y - 18, 7, 6), Color(0.6, 0.9, 1.0))
	draw_circle(Vector2(x - 13, y + 5), 6, Color.BLACK)
	draw_circle(Vector2(x + 13, y + 5), 6, Color.BLACK)
	draw_circle(Vector2(x - 13, y + 5), 2, Color.SILVER)
	draw_circle(Vector2(x + 13, y + 5), 2, Color.SILVER)
	if fmod(_t, 0.8) < 0.55:
		_text("MEGA ROBO RACER!", Vector2(W / 2, 22), 13, Color.YELLOW)
	_text("batteries not included", Vector2(W / 2, 112), 7, Color.WHITE)


func _draw_signoff() -> void:
	var bars := [Color(0.75, 0.75, 0.75), Color(0.75, 0.75, 0), Color(0, 0.75, 0.75), Color(0, 0.75, 0),
		Color(0.75, 0, 0.75), Color(0.75, 0, 0), Color(0, 0, 0.75)]
	for i in bars.size():
		draw_rect(Rect2(i * W / 7.0, 0, W / 7.0 + 1, H * 0.7), bars[i])
	draw_rect(Rect2(0, H * 0.7, W, H * 0.3), Color(0.05, 0.05, 0.1))
	_text("GOODNIGHT", Vector2(W / 2, H * 0.88), 10, Color.WHITE)


func _draw_static(amount: float) -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.1, 0.1, 0.1))
	for i in 500:
		var v := randf() * amount
		draw_rect(Rect2(randi() % 160, randi() % 120, 2, 1), Color(v, v, v))


func _draw_crt() -> void:
	for y in range(0, 120, 2):
		draw_line(Vector2(0, y), Vector2(W, y), Color(0, 0, 0, 0.25))
	var roll := fmod(_t * 25.0, H + 20) - 10
	draw_rect(Rect2(0, roll, W, 6), Color(1, 1, 1, 0.04))
	for i in 40:
		var v := randf()
		draw_rect(Rect2(randi() % 160, randi() % 120, 1, 1), Color(v, v, v, 0.25))


func _text(s: String, center: Vector2, size: int, color: Color) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := center - Vector2(w / 2.0, -size / 2.0)
	draw_string(_font, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.8))
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
