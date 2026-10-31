class_name TvShow
extends Node2D
## Placeholder TV programs drawn live at 160x120: a Halloween cartoon special,
## a winter special, a toy commercial, a dream version, a broadcast sign-off,
## static, Thanksgiving football, the Thanksgiving parade, the New Year's Eve
## countdown, "The Night Before" (an original Christmas special) and its dream
## version, the Christmas-morning yule log, and a two-player racing game.
## Replace any of them with a real video via media/<channel>.ogv.

const W := 160.0
const H := 120.0

var channel := "special"
## When the New Year's countdown started (in _t time); -1 = not yet.
var countdown_at := -1.0
var _t := 0.0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta * (0.4 if channel == "dream" or channel == "xmas_dream" else 1.0)
	queue_redraw()


func light_color() -> Color:
	match channel:
		"commercial":
			return Color.from_hsv(fmod(_t * 0.25, 1.0), 0.5, 1.0)
		"dream":
			return Color(0.7, 0.45, 1.0)
		"winter":
			return Color(0.75, 0.85, 1.0)
		"christmas":
			return Color(1.0, 0.8, 0.6) if fmod(_t, 40.0) < 20.0 else Color(0.6, 0.7, 1.0)
		"signoff":
			return Color(0.9, 0.9, 1.0)
		"static":
			return Color(0.8, 0.85, 0.9)
		"football":
			return Color(0.5, 0.9, 0.55)
		"parade":
			return Color(0.85, 0.85, 0.95)
		"yulelog":
			return Color(1.0, 0.55, 0.25) * (0.85 + 0.15 * sin(_t * 9.0) * sin(_t * 5.3))
		"videogame":
			return Color(0.55, 0.8, 1.0) if fmod(_t, 3.0) < 1.5 else Color(0.7, 1.0, 0.6)
		"xmas_dream":
			return Color(0.6, 0.45, 1.0)
		"newyear":
			return Color(0.6, 0.6, 1.0) if countdown_at < 0.0 or _t - countdown_at < 10.0 else Color.from_hsv(fmod(_t * 0.5, 1.0), 0.5, 1.0)
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
		"christmas":
			_draw_christmas()
		"signoff":
			_draw_signoff()
		"static":
			_draw_static(1.0)
		"football":
			_draw_football()
		"parade":
			_draw_parade()
		"yulelog":
			_draw_yulelog()
		"videogame":
			_draw_videogame()
		"xmas_dream":
			_draw_christmas()
			# The same special, but slow and purple, like it's underwater.
			draw_rect(Rect2(0, 0, W, H), Color(0.35, 0.1, 0.55, 0.45))
		"newyear":
			_draw_newyear()
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


## "The Night Before": a 40-second loop in four scenes. A snowy town, a toy
## train around the tree, the sleigh across the moon, and a dog waiting up
## by the window with the porch light on.
func _draw_christmas() -> void:
	var t := fmod(_t, 40.0)
	if t < 10.0:
		_xmas_town(t)
	elif t < 20.0:
		_xmas_tree(t - 10.0)
	elif t < 30.0:
		_xmas_sleigh(t - 20.0)
	else:
		_xmas_window(t - 30.0)
	_xmas_snow(t < 10.0 or t >= 30.0)


func _night_sky() -> void:
	for i in 12:
		draw_rect(Rect2(0, i * 10, W, 10), Color(0.03, 0.05, 0.16).lerp(Color(0.16, 0.18, 0.35), i / 11.0))
	for i in 24:
		var tw := 0.5 + 0.5 * sin(_t * 3.0 + i * 1.7)
		draw_rect(Rect2(fmod(i * 41.0, W), fmod(i * 19.0, 55.0), 1, 1), Color(1, 1, 0.9, tw))


func _xmas_snow(heavy: bool) -> void:
	for i in (70 if heavy else 30):
		var p := Vector2(fmod(i * 53.0 + sin(_t * 0.8 + i) * 6.0, W), fmod(i * 17.0 + _t * (8.0 + i % 5), H))
		draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, 0.85))


func _xmas_town(t: float) -> void:
	_night_sky()
	draw_rect(Rect2(0, 92, W, 28), Color(0.88, 0.92, 1.0))
	var roofs := [Color(0.35, 0.15, 0.15), Color(0.2, 0.25, 0.35), Color(0.3, 0.3, 0.2)]
	for k in 4:
		var x := 6.0 + k * 39.0
		draw_rect(Rect2(x, 70, 30, 22), Color(0.45, 0.32, 0.25).lerp(Color(0.35, 0.35, 0.45), k * 0.25))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 70), Vector2(x + 15, 58), Vector2(x + 33, 70)]), roofs[k % 3])
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 70), Vector2(x + 15, 58), Vector2(x + 33, 70), Vector2(x + 15, 61)]), Color(0.95, 0.97, 1.0))
		draw_rect(Rect2(x + 5, 76, 7, 6), Color(1, 0.8, 0.4))
		draw_rect(Rect2(x + 18, 76, 7, 6), Color(1, 0.8, 0.4) if k % 2 == 0 else Color(0.2, 0.2, 0.3))
		# Christmas lights along the eaves, chasing
		for b in 6:
			var on := int(t * 4.0 + b + k) % 3 != 0
			draw_rect(Rect2(x + 1 + b * 5, 71, 2, 2), [Color.RED, Color.GREEN, Color(0.3, 0.5, 1), Color.YELLOW][b % 4] if on else Color(0.2, 0.2, 0.2))
	if t < 7.0:
		_text("THE NIGHT BEFORE", Vector2(W / 2, 18), 13, Color(1, 0.85, 0.4))
		_text("a Christmas special", Vector2(W / 2, 32), 8, Color.WHITE)


func _xmas_tree(t: float) -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.35, 0.18, 0.15))
	draw_rect(Rect2(0, 92, W, 28), Color(0.25, 0.15, 0.1))
	# the tree
	for k in 3:
		var w := 34.0 - k * 9.0
		var y := 88.0 - k * 18.0
		draw_colored_polygon(PackedVector2Array([Vector2(80 - w, y), Vector2(80, y - 26), Vector2(80 + w, y)]), Color(0.1, 0.4, 0.18))
	draw_rect(Rect2(76, 88, 8, 8), Color(0.35, 0.2, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(80, 24), Vector2(83, 31), Vector2(90, 31), Vector2(84, 35), Vector2(86, 42), Vector2(80, 38), Vector2(74, 42), Vector2(76, 35), Vector2(70, 31), Vector2(77, 31)]), Color(1, 0.85, 0.2))
	for b in 14:
		var by := 40.0 + (b % 7) * 7.0
		var bx := 80.0 + sin(b * 2.3) * (by - 34.0) * 0.7
		var lit := sin(_t * 4.0 + b) > -0.3
		draw_circle(Vector2(bx, by), 1.6, [Color.RED, Color(0.3, 0.5, 1), Color.YELLOW, Color(1, 0.5, 0.9)][b % 4] if lit else Color(0.3, 0.3, 0.3))
	# presents
	for p in [[52, 90, Color(0.8, 0.1, 0.1)], [96, 92, Color(0.2, 0.4, 0.8)], [108, 94, Color(0.9, 0.8, 0.2)]]:
		draw_rect(Rect2(p[0], p[1], 12, 8), p[2])
		draw_rect(Rect2(p[0] + 5, p[1], 2, 8), Color.WHITE)
	# a toy train going round on the floor
	var a := t * 1.2
	var c := Vector2(80 + cos(a) * 52, 106 + sin(a) * 6)
	var front := sin(a) > 0.0
	for car in 3:
		var ca := a - car * 0.22
		var cp := Vector2(80 + cos(ca) * 52, 106 + sin(ca) * 6)
		draw_rect(Rect2(cp.x - 5, cp.y - 5, 10, 6), [Color(0.15, 0.15, 0.2), Color(0.8, 0.15, 0.15), Color(0.15, 0.5, 0.2)][car])
		draw_circle(cp + Vector2(-3, 1), 1.5, Color.BLACK)
		draw_circle(cp + Vector2(3, 1), 1.5, Color.BLACK)
	if front:
		draw_circle(c + Vector2(0, -9 - fmod(_t * 6.0, 4.0)), 2.0, Color(0.85, 0.85, 0.85, 0.7))


func _xmas_sleigh(t: float) -> void:
	_night_sky()
	draw_circle(Vector2(80, 50), 28, Color(0.95, 0.93, 0.8))
	draw_rect(Rect2(0, 98, W, 22), Color(0.85, 0.9, 1.0))
	# the sleigh and reindeer, in silhouette, across the moon
	var x := -60.0 + t * 26.0
	var y := 46.0 - sin(t * 0.5) * 10.0
	var dark := Color(0.06, 0.05, 0.1)
	for r in 4:
		var rx := x + 40.0 - r * 9.0
		var leg := sin(_t * 10.0 + r) * 2.0
		draw_rect(Rect2(rx, y - 2, 7, 3), dark)
		draw_line(Vector2(rx + 7, y - 2), Vector2(rx + 9, y - 6), dark, 1.5)
		draw_line(Vector2(rx + 9, y - 6), Vector2(rx + 8, y - 9), dark, 1.0)
		draw_line(Vector2(rx + 9, y - 6), Vector2(rx + 11, y - 8), dark, 1.0)
		draw_line(Vector2(rx + 1, y + 1), Vector2(rx + leg, y + 5), dark, 1.0)
		draw_line(Vector2(rx + 6, y + 1), Vector2(rx + 6 - leg, y + 5), dark, 1.0)
	draw_line(Vector2(x + 14, y), Vector2(x + 33, y), dark, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x, y - 6), Vector2(x + 14, y - 6), Vector2(x + 16, y + 2), Vector2(x - 2, y + 2)]), dark)
	draw_line(Vector2(x - 3, y + 4), Vector2(x + 18, y + 4), dark, 1.5)
	draw_circle(Vector2(x + 5, y - 9), 3.0, dark)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 9, y - 10), Vector2(x + 14, y - 13), Vector2(x + 13, y - 7)]), dark)
	if t > 6.0:
		_text("He's on his way!", Vector2(W / 2, 110), 9, Color.WHITE)


func _xmas_window(t: float) -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.3, 0.2, 0.25))
	# the window, with the night and the snow outside
	draw_rect(Rect2(30, 14, 100, 70), Color(0.08, 0.1, 0.25))
	draw_circle(Vector2(108, 32), 9, Color(0.95, 0.93, 0.8))
	draw_rect(Rect2(30, 70, 100, 14), Color(0.9, 0.93, 1.0))
	draw_rect(Rect2(28, 12, 104, 3), Color(0.9, 0.85, 0.7))
	draw_rect(Rect2(28, 84, 104, 4), Color(0.9, 0.85, 0.7))
	draw_rect(Rect2(79, 12, 3, 74), Color(0.9, 0.85, 0.7))
	# the porch light, on
	draw_circle(Vector2(42, 40), 6, Color(1, 0.8, 0.4, 0.35))
	draw_circle(Vector2(42, 40), 2.5, Color(1, 0.85, 0.5))
	# a little dog, waiting up, tail going
	var d := Vector2(70, 98)
	draw_circle(d, 9, Color(0.7, 0.48, 0.28))
	draw_circle(d + Vector2(0, -11), 6, Color(0.7, 0.48, 0.28))
	draw_circle(d + Vector2(0, -8), 3, Color(0.95, 0.92, 0.85))
	draw_rect(Rect2(d.x - 7, d.y - 15, 3, 6), Color(0.35, 0.22, 0.12))
	draw_rect(Rect2(d.x + 4, d.y - 15, 3, 6), Color(0.35, 0.22, 0.12))
	var wag := sin(_t * 12.0) * 4.0
	draw_line(d + Vector2(8, 2), d + Vector2(14, -4 + wag), Color(0.7, 0.48, 0.28), 2.0)
	if t > 4.0:
		_text("MERRY CHRISTMAS", Vector2(W / 2, 8), 11, Color(1, 0.85, 0.4))
		_text("to all, and to all a good night", Vector2(W / 2, 112), 7, Color.WHITE)


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


## Thanksgiving football: the stands, the field, a play every few seconds,
## and the score banner. Made-up teams.
func _draw_football() -> void:
	var pan := sin(_t * 0.25) * 24.0
	draw_rect(Rect2(0, 0, W, H), Color(0.15, 0.42, 0.17))
	# The stands, a blur of coats.
	draw_rect(Rect2(0, 0, W, 20), Color(0.18, 0.16, 0.2))
	for i in 90:
		var x := fmod(i * 37.0 - pan * 0.5, W + 10.0)
		var y := 2.0 + fmod(i * 13.0, 15.0)
		draw_rect(Rect2(x, y, 2, 2), Color.from_hsv(fmod(i * 0.17, 1.0), 0.4, 0.6))
	draw_rect(Rect2(0, 20, W, 2), Color(0.9, 0.9, 0.9))
	# Mowed stripes and yard lines, leaning for a broadcast angle.
	for i in range(-1, 12):
		var x := fmod(i * 20.0 - pan + 400.0, 240.0) - 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 22), Vector2(x + 10, 22), Vector2(x + 2, H), Vector2(x - 8, H)]), Color(0.17, 0.47, 0.19))
		draw_line(Vector2(x, 22), Vector2(x - 8, H), Color(1, 1, 1, 0.75), 1.0)
	# A play: line up, snap, run, tackle, line up again.
	var p := fmod(_t, 7.0) / 7.0
	var go := clampf((p - 0.3) / 0.5, 0.0, 1.0)
	var line := 78.0 - pan
	var runner := Vector2(line - 12.0 + go * 46.0, 70.0 + sin(go * 5.0) * 8.0)
	for i in 7:
		var y := 40.0 + i * 10.0
		var o := Vector2(line - 4.0 + go * 10.0, y)
		var d := Vector2(line + 5.0 + go * 6.0, y).lerp(runner + Vector2(4, (i - 3) * 3.0), go * 0.8)
		_player_dot(o, Color(0.8, 0.12, 0.12))
		_player_dot(d, Color(0.95, 0.95, 0.95))
	_player_dot(runner, Color(0.8, 0.12, 0.12))
	draw_circle(runner + Vector2(2, -1), 1.2, Color(0.45, 0.25, 0.1))
	# The score banner.
	draw_rect(Rect2(6, 103, 148, 12), Color(0.05, 0.1, 0.3, 0.92))
	_text("RIVERTON 14   LAKESIDE 10   4TH  8:42", Vector2(W / 2, 106), 7, Color.WHITE)


## New Year's Eve, live: the city at night, the glowing ball, the countdown,
## then confetti.
func _draw_newyear() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.03, 0.1))
	for i in 14:
		var bh := 30.0 + fmod(i * 23.0, 45.0)
		draw_rect(Rect2(i * 12.0 - 2.0, H - bh, 11, bh), Color(0.08, 0.08, 0.16))
		for k in 6:
			if int(i * 7 + k * 3) % 4 != 0:
				draw_rect(Rect2(i * 12.0 + 1.0 + (k % 2) * 4.0, H - bh + 4.0 + int(k / 2) * 7.0, 2, 3), Color(1, 0.85, 0.5, 0.8))
	var since := _t - countdown_at if countdown_at >= 0.0 else -1.0
	var drop := clampf(since / 10.0, 0.0, 1.0) if since >= 0.0 else 0.0
	draw_line(Vector2(W / 2, 8), Vector2(W / 2, 80), Color(0.5, 0.5, 0.6), 1.0)
	var ball := Vector2(W / 2, 14 + drop * 58.0)
	draw_circle(ball, 7.0, Color(0.9, 0.95, 1.0))
	draw_circle(ball, 4.0, Color(1, 1, 1))
	if since < 0.0:
		_text("NEW YEAR'S EVE LIVE", Vector2(W / 2, 96), 9, Color.WHITE)
		_text("11:58 PM", Vector2(W / 2, 108), 7, Color(1, 0.9, 0.5))
	elif since < 10.0:
		_text(str(10 - int(since)), Vector2(W / 2, 92), 26, Color.WHITE)
	else:
		for i in 60:
			var x := fmod(i * 37.0 + _t * (8.0 + i % 5), W)
			var y := fmod(i * 19.0 + _t * (20.0 + i % 7), H)
			draw_rect(Rect2(x, y, 2, 2), Color.from_hsv(fmod(i * 0.13, 1.0), 0.7, 1.0))
		_text("HAPPY NEW YEAR!", Vector2(W / 2, 90), 14, Color(1, 0.9, 0.4))
		_text("2004", Vector2(W / 2, 106), 12, Color.WHITE)


## Thanksgiving morning: the big parade downtown. Buildings, a crowd behind
## the barricades, a marching band, and a giant turkey balloon drifting by.
func _draw_parade() -> void:
	draw_rect(Rect2(0, 0, W, 60), Color(0.62, 0.7, 0.82))
	for i in 9:
		var bh := 34.0 + fmod(i * 29.0, 26.0)
		var x := i * 19.0 - 4.0
		draw_rect(Rect2(x, 62 - bh, 17, bh), Color(0.5, 0.45, 0.48).lerp(Color(0.62, 0.58, 0.55), fmod(i * 0.37, 1.0)))
		for k in 8:
			draw_rect(Rect2(x + 2 + (k % 3) * 5, 64 - bh + 4 + int(k / 3) * 8, 3, 4), Color(0.75, 0.8, 0.88))
	draw_rect(Rect2(0, 62, W, 58), Color(0.38, 0.38, 0.4))
	# The crowd, bundled up, behind blue barricades.
	for i in 70:
		var x := fmod(i * 23.0, W)
		var y := 60.0 + fmod(i * 7.0, 8.0)
		draw_rect(Rect2(x, y, 3, 5), Color.from_hsv(fmod(i * 0.21, 1.0), 0.55, 0.7))
		draw_circle(Vector2(x + 1.5, y - 1), 1.3, Color(0.85, 0.7, 0.55))
	draw_rect(Rect2(0, 70, W, 2), Color(0.2, 0.35, 0.8))
	# The marching band, stepping in time.
	for i in 12:
		var bx := fmod(i * 13.0 + _t * 9.0, W + 30.0) - 15.0
		var by := 92.0 + (i % 3) * 8.0 + (1.0 if int(_t * 4.0 + i) % 2 == 0 else 0.0)
		draw_rect(Rect2(bx - 2, by - 5, 4, 7), Color(0.75, 0.1, 0.12))
		draw_rect(Rect2(bx - 2, by - 8, 4, 3), Color(0.95, 0.95, 0.95))
		draw_rect(Rect2(bx + 2, by - 4, 3, 1), Color(0.95, 0.8, 0.2))
	# The turkey balloon: a round brown body, a fan of tail feathers, ropes.
	var tx := fmod(_t * 6.0, W + 90.0) - 45.0
	var ty := 30.0 + sin(_t * 0.8) * 2.0
	var feathers := [Color(0.85, 0.25, 0.1), Color(0.95, 0.6, 0.1), Color(0.95, 0.85, 0.2), Color(0.55, 0.3, 0.12)]
	for f in 7:
		var a := deg_to_rad(-160.0 + f * 23.0)
		draw_circle(Vector2(tx, ty) + Vector2(cos(a), sin(a)) * 15.0, 7.0, feathers[f % feathers.size()])
	draw_circle(Vector2(tx, ty + 3), 12.0, Color(0.5, 0.3, 0.15))
	draw_circle(Vector2(tx + 9, ty - 6), 5.0, Color(0.55, 0.33, 0.17))
	draw_circle(Vector2(tx + 11, ty - 7), 1.2, Color.BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(tx + 13, ty - 6), Vector2(tx + 18, ty - 4), Vector2(tx + 13, ty - 3)]), Color(0.95, 0.75, 0.1))
	draw_circle(Vector2(tx + 13, ty - 2), 1.8, Color(0.85, 0.1, 0.1))
	for r in 4:
		draw_line(Vector2(tx - 8 + r * 5, ty + 14), Vector2(tx - 14 + r * 7, 88), Color(0.2, 0.2, 0.2, 0.6), 1.0)
	if fmod(_t, 18.0) < 5.0:
		draw_rect(Rect2(0, 0, W, 16), Color(0.55, 0.15, 0.08, 0.9))
		_text("THANKSGIVING DAY PARADE", Vector2(W / 2, 6), 9, Color(1, 0.9, 0.6))
	else:
		_text("LIVE", Vector2(16, 8), 8, Color(1, 0.3, 0.3))


## Christmas morning: a log fire, filling the whole screen, on a loop forever.
func _draw_yulelog() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.08, 0.04, 0.03))
	# Brick around the firebox.
	for row in 12:
		for col in 9:
			var x := col * 20.0 - (10.0 if row % 2 else 0.0)
			draw_rect(Rect2(x + 1, row * 10.0 + 1, 18, 8), Color(0.45, 0.18, 0.12).lerp(Color(0.3, 0.12, 0.09), fmod(row * 0.31 + col * 0.17, 1.0)))
	draw_rect(Rect2(18, 22, 124, 86), Color(0.05, 0.03, 0.02))
	# Flames: layered tongues that lick and flicker.
	for layer in 3:
		var c: Color = [Color(0.85, 0.25, 0.05), Color(1.0, 0.55, 0.1), Color(1.0, 0.85, 0.35)][layer]
		for i in 9:
			var x := 30.0 + i * 12.5 + sin(_t * 3.0 + i) * 2.0
			var h := (46.0 - layer * 12.0) * (0.75 + 0.25 * sin(_t * (7.0 + i) + i * 2.1))
			var w := 9.0 - layer * 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - w, 92), Vector2(x + sin(_t * 5.0 + i) * 4.0, 92 - h), Vector2(x + w, 92)]), c)
	# Logs and glowing embers.
	draw_rect(Rect2(28, 90, 104, 9), Color(0.3, 0.17, 0.08))
	draw_rect(Rect2(38, 96, 88, 8), Color(0.38, 0.22, 0.1))
	for i in 14:
		var glow := 0.6 + 0.4 * sin(_t * 4.0 + i * 1.3)
		draw_rect(Rect2(30 + i * 7.0, 103 + (i % 2) * 2.0, 3, 2), Color(1.0, 0.45, 0.1) * glow)
	# Sparks drifting up.
	for i in 6:
		var y := 90.0 - fmod(_t * 18.0 + i * 15.0, 70.0)
		draw_rect(Rect2(60 + sin(_t + i) * 20.0 + i * 6.0, y, 1, 1), Color(1, 0.8, 0.4))
	if fmod(_t, 30.0) < 3.0:
		_text("MERRY CHRISTMAS FROM CHANNEL 7", Vector2(W / 2, 12), 7, Color(1, 0.95, 0.85))


## Player one and player two, split screen: a kart race on a looping track.
func _draw_videogame() -> void:
	for half in 2:
		var y0 := half * 60.0
		var t := _t * (1.0 if half == 0 else 0.93) + half * 2.0
		draw_rect(Rect2(0, y0, W, 24), Color(0.45, 0.7, 1.0) if half == 0 else Color(0.95, 0.6, 0.4))
		for k in 3:
			draw_circle(Vector2(fmod(k * 60.0 - t * 6.0, W + 40.0) - 20.0, y0 + 8 + k * 3), 6, Color(1, 1, 1, 0.85))
		draw_rect(Rect2(0, y0 + 24, W, 36), Color(0.3, 0.7, 0.3))
		# The road, curving with the track.
		var bend := sin(t * 0.7) * 30.0
		var road := PackedVector2Array([Vector2(W / 2 - 6 + bend, y0 + 24), Vector2(W / 2 + 6 + bend, y0 + 24), Vector2(W / 2 + 60, y0 + 60), Vector2(W / 2 - 60, y0 + 60)])
		draw_colored_polygon(road, Color(0.35, 0.35, 0.38))
		for k in 5:
			var d := fmod(k * 0.2 + t * 0.9, 1.0)
			var yy := y0 + 24 + d * d * 36.0
			var xx := W / 2 + bend * (1.0 - d)
			draw_rect(Rect2(xx - 1 - d * 2, yy, 2 + d * 4, 1 + d * 2), Color(1, 1, 1))
		# Your kart (red for player one, blue for player two) and the other one ahead.
		var kc := Color(0.9, 0.15, 0.15) if half == 0 else Color(0.2, 0.4, 0.95)
		var other := Color(0.2, 0.4, 0.95) if half == 0 else Color(0.9, 0.15, 0.15)
		var ox := W / 2 + bend * 0.6 + sin(t * 1.3) * 6.0
		draw_rect(Rect2(ox - 3, y0 + 33, 6, 3), other)
		var kx := W / 2 + sin(t * 2.0) * 10.0
		draw_rect(Rect2(kx - 10, y0 + 46, 20, 8), kc)
		draw_rect(Rect2(kx - 5, y0 + 41, 10, 6), Color(0.95, 0.85, 0.7))
		draw_rect(Rect2(kx - 12, y0 + 52, 5, 5), Color.BLACK)
		draw_rect(Rect2(kx + 7, y0 + 52, 5, 5), Color.BLACK)
		_text("P%d" % (half + 1), Vector2(10, y0 + 4), 8, Color.WHITE)
		_text(["1ST", "4TH"][half] if fmod(_t, 12.0) < 9.0 else ["2ND", "1ST"][half], Vector2(W - 14, y0 + 4), 8, Color(1, 0.9, 0.2))
		_text("LAP %d/3" % (1 + int(_t / 20.0) % 3), Vector2(W / 2, y0 + 4), 7, Color.WHITE)
	draw_rect(Rect2(0, 59, W, 2), Color.BLACK)


func _player_dot(at: Vector2, jersey: Color) -> void:
	draw_rect(Rect2(at.x - 2, at.y - 3, 4, 5), jersey)
	draw_circle(at + Vector2(0, -4), 1.6, Color(0.85, 0.85, 0.85))


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
