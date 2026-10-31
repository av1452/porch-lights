class_name Classroom
extends Node3D
## Mrs. Patterson's third-grade classroom, built in code. Front of the room
## (chalkboard) is -Z; windows on the west wall (-X); door on the east wall.
## Every holiday's crafts are still up: Mrs. Patterson never takes anything down.

const W := 10.0
const D := 8.0
const H := 3.0

## Points of interest other scripts use.
const DOOR := Vector3(4.95, 0.0, -2.6)
const TEACHER_DESK := Vector3(2.6, 0.0, -2.7)
const CRAFT_TABLE := Vector3(-3.6, 0.0, -0.6)
const PARTY_TABLE := Vector3(2.8, 0.0, 3.0)
const RUG := Vector3(-2.8, 0.0, 2.6)
const TV_CART := Vector3(3.9, 0.0, -0.9)
const GIFT_PILE := Vector3(1.2, 0.0, -3.2)
const WINDOW_X := -4.94

## The wall clock (set its text as the afternoon goes on).
var clock_label: Label3D
var tv_screen: TvScreen
var _sky: StandardMaterial3D


func _ready() -> void:
	_room()
	_front_wall()
	_desks()
	_back_of_room()
	_party()
	_lights()


func _mat(c: Color, glow := 0.0, rough := 0.85) -> StandardMaterial3D:
	var m := Decorations.mat(c, glow)
	m.roughness = rough
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, collide := false, parent: Node3D = self) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = mat
	b.use_collision = collide
	parent.add_child(b)
	return b


func _text(t: String, pos: Vector3, size: int, color: Color, yaw := 0.0, pixel := 0.004) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font_size = size
	l.pixel_size = pixel
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.rotation_degrees.y = yaw
	add_child(l)
	return l


func _room() -> void:
	var tile := _mat(Color(0.82, 0.8, 0.72), 0.0, 0.5)
	var floor := _box(Vector3(W, 0.1, D), Vector3(0, -0.05, 0), tile, true)
	floor.set_meta("surface", "wood")
	# speckled school tile: a few darker squares in the pattern
	var fleck := _mat(Color(0.62, 0.6, 0.55), 0.0, 0.5)
	for x in range(-4, 5, 2):
		for z in range(-3, 4, 3):
			_box(Vector3(0.6, 0.004, 0.6), Vector3(x + 0.3, 0.002, z + 0.3), fleck)
	_box(Vector3(W, 0.1, D), Vector3(0, H + 0.05, 0), _mat(Color(0.93, 0.92, 0.88)), true)
	# drop-ceiling grid
	var grid := _mat(Color(0.8, 0.8, 0.78))
	for x in range(-4, 5, 1):
		_box(Vector3(0.02, 0.02, D), Vector3(x * 1.0, H - 0.01, 0), grid)
	for z in range(-3, 4, 1):
		_box(Vector3(W, 0.02, 0.02), Vector3(0, H - 0.01, z * 1.0), grid)
	var block := _mat(Color(0.94, 0.9, 0.74))
	_box(Vector3(W, H, 0.2), Vector3(0, H / 2, -D / 2 - 0.1), block, true)
	_box(Vector3(W, H, 0.2), Vector3(0, H / 2, D / 2 + 0.1), block, true)
	_box(Vector3(0.2, H, D), Vector3(-W / 2 - 0.1, H / 2, 0), block, true)
	_box(Vector3(0.2, H, D), Vector3(W / 2 + 0.1, H / 2, 0), block, true)
	# a painted stripe along the cinder block, school colors
	var stripe := _mat(Color(0.2, 0.35, 0.6))
	_box(Vector3(W, 0.12, 0.02), Vector3(0, 1.0, -D / 2 + 0.01), stripe)
	_box(Vector3(W, 0.12, 0.02), Vector3(0, 1.0, D / 2 - 0.01), stripe)
	_box(Vector3(0.02, 0.12, D), Vector3(W / 2 - 0.01, 1.0, 0), stripe)
	# windows: a heavy gray December sky, and paper snowflakes taped on
	var sky := _mat(Color(0.5, 0.54, 0.6), 0.55)
	_sky = sky
	var frame := _mat(Color(0.85, 0.85, 0.82))
	var paper := _mat(Color(0.98, 0.98, 1.0))
	for z in [-2.4, 0.0, 2.4]:
		_box(Vector3(0.04, 1.3, 1.8), Vector3(WINDOW_X, 1.75, z), sky)
		_box(Vector3(0.06, 1.42, 0.06), Vector3(WINDOW_X + 0.02, 1.75, z - 0.93), frame)
		_box(Vector3(0.06, 1.42, 0.06), Vector3(WINDOW_X + 0.02, 1.75, z + 0.93), frame)
		_box(Vector3(0.06, 0.06, 1.9), Vector3(WINDOW_X + 0.02, 1.07, z), frame)
		for i in 3:
			add_snowflake(Vector3(WINDOW_X + 0.04, 1.4 + (i % 2) * 0.5, z - 0.5 + i * 0.5), paper)
	# the door
	var door := _mat(Color(0.55, 0.42, 0.28))
	_box(Vector3(0.08, 2.1, 0.95), DOOR + Vector3(0, 1.05, 0), door)
	_box(Vector3(0.02, 0.5, 0.3), DOOR + Vector3(-0.05, 1.5, 0), _mat(Color(0.8, 0.9, 1.0), 0.6))
	_text("ROOM 12", DOOR + Vector3(-0.06, 1.95, 0), 24, Color(0.2, 0.2, 0.2), -90.0)


## The first snow, falling just past the glass of every window.
func start_snow() -> void:
	for z in [-2.4, 0.0, 2.4]:
		var s := Decorations.snow(Vector3(WINDOW_X + 0.07, 1.75, z), Vector3(0.03, 0.62, 0.86), 160)
		s.preprocess = 0.0
		add_child(s)
	create_tween().tween_property(_sky, "emission_energy_multiplier", 0.7, 3.0)


## A paper snowflake: two crossed six-sided paper cutouts. Public so the
## chapter can tape yours up.
func add_snowflake(pos: Vector3, mat: Material) -> Node3D:
	var flake := Node3D.new()
	flake.position = pos
	add_child(flake)
	for a in 3:
		var arm := CSGBox3D.new()
		arm.size = Vector3(0.005, 0.18, 0.025)
		arm.rotation_degrees.x = a * 60.0
		arm.material = mat
		flake.add_child(arm)
	var middle := CSGCylinder3D.new()
	middle.radius = 0.04
	middle.height = 0.006
	middle.sides = 6
	middle.rotation_degrees.z = 90
	middle.material = mat
	flake.add_child(middle)
	return flake


func _front_wall() -> void:
	var fz := -D / 2 + 0.02
	_box(Vector3(5.2, 1.3, 0.04), Vector3(-0.4, 1.55, fz), _mat(Color(0.12, 0.3, 0.2), 0.0, 0.95))
	_box(Vector3(5.4, 0.06, 0.12), Vector3(-0.4, 0.88, fz + 0.06), _mat(Color(0.6, 0.45, 0.3)))
	_text("Happy Winter Break!", Vector3(-0.4, 1.85, fz + 0.03), 72, Color(0.95, 0.95, 0.9))
	_text("No homework! (Read a book.)\n- Mrs. P", Vector3(-0.4, 1.35, fz + 0.03), 40, Color(0.95, 0.95, 0.85))
	_text("Aa  Bb  Cc  Dd  Ee  Ff  Gg  Hh  Ii  Jj  Kk  Ll  Mm", Vector3(-0.4, 2.55, fz + 0.01), 34, Color(0.15, 0.3, 0.7))
	# clock
	var face := CSGCylinder3D.new()
	face.radius = 0.16
	face.height = 0.04
	face.rotation_degrees.x = 90
	face.position = Vector3(3.2, 2.45, fz + 0.03)
	face.material = _mat(Color(0.97, 0.97, 0.95))
	add_child(face)
	# A digital readout on the face; the party starts after lunch.
	clock_label = _text("1:50", Vector3(3.2, 2.45, fz + 0.06), 28, Color(0.1, 0.1, 0.1))
	# teacher's desk, with the North Pole mailbox on it
	var wood := _mat(Color(0.5, 0.36, 0.22), 0.0, 0.6)
	_box(Vector3(1.5, 0.75, 0.75), TEACHER_DESK + Vector3(0, 0.375, 0), wood, true)
	_box(Vector3(0.3, 0.02, 0.22), TEACHER_DESK + Vector3(-0.45, 0.76, 0.1), _mat(Color(0.95, 0.95, 0.9)))
	_box(Vector3(0.12, 0.14, 0.12), TEACHER_DESK + Vector3(0.55, 0.82, -0.15), _mat(Color(0.85, 0.2, 0.2)))
	# a little classroom tree in the corner
	var corner := Node3D.new()
	corner.position = Vector3(4.2, 0, -3.3) - Decorations.TREE_POS * 0.7
	corner.scale = Vector3.ONE * 0.7
	add_child(corner)
	Decorations.christmas_tree(corner, true)
	# the TV cart (the best thing that can happen in a classroom)
	var cart := _mat(Color(0.2, 0.2, 0.22), 0.0, 0.5)
	_box(Vector3(0.9, 0.05, 0.6), TV_CART + Vector3(0, 0.55, 0), cart, true)
	_box(Vector3(0.9, 0.05, 0.6), TV_CART + Vector3(0, 1.25, 0), cart)
	for x in [-0.42, 0.42]:
		for z in [-0.27, 0.27]:
			_box(Vector3(0.04, 1.25, 0.04), TV_CART + Vector3(x, 0.625, z), cart)
	_box(Vector3(0.6, 0.1, 0.4), TV_CART + Vector3(0, 0.62, 0), _mat(Color(0.1, 0.1, 0.1)))
	var tv := Node3D.new()
	tv.name = "TV"
	tv.position = TV_CART + Vector3(0, 1.55, 0)
	tv.rotation_degrees.y = -50.0
	add_child(tv)
	_box(Vector3(0.7, 0.55, 0.55), Vector3.ZERO, _mat(Color(0.12, 0.12, 0.13), 0.0, 0.4), false, tv)
	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.54, 0.4)
	screen.mesh = quad
	screen.position = Vector3(0, 0.02, 0.28)
	tv.add_child(screen)
	tv_screen = TvScreen.new()
	tv_screen.channel = "off"
	tv.add_child(tv_screen)


func _desks() -> void:
	var top := _mat(Color(0.75, 0.62, 0.42), 0.0, 0.4)
	var metal := _mat(Color(0.55, 0.55, 0.58), 0.0, 0.4)
	var chair := _mat(Color(0.15, 0.35, 0.75), 0.0, 0.5)
	for x in [-2.4, -0.8, 0.8, 2.4]:
		for z in [-1.4, 0.0, 1.4]:
			var desk := Vector3(x, 0, z)
			_box(Vector3(0.62, 0.04, 0.46), desk + Vector3(0, 0.62, 0), top, true)
			_box(Vector3(0.56, 0.14, 0.4), desk + Vector3(0, 0.53, 0), metal)
			for lx in [-0.27, 0.27]:
				_box(Vector3(0.03, 0.5, 0.03), desk + Vector3(lx, 0.25, -0.18), metal)
				_box(Vector3(0.03, 0.5, 0.03), desk + Vector3(lx, 0.25, 0.18), metal)
			_box(Vector3(0.38, 0.04, 0.36), desk + Vector3(0, 0.38, 0.42), chair)
			_box(Vector3(0.38, 0.32, 0.04), desk + Vector3(0, 0.58, 0.6), chair)
	# paper and markers on a few desks
	var colors := [Color(0.9, 0.2, 0.2), Color(0.2, 0.6, 0.25), Color(1, 0.85, 0.3)]
	for i in 6:
		_box(Vector3(0.22, 0.004, 0.28), Vector3(-2.4 + (i % 4) * 1.6, 0.645, -1.4 + (i / 4) * 1.4), _mat(colors[i % 3].lerp(Color.WHITE, 0.5)))
	# the craft table: construction paper, glue, a cup of safety scissors
	_box(Vector3(1.2, 0.04, 0.7), CRAFT_TABLE + Vector3(0, 0.62, 0), top, true)
	for lx in [-0.55, 0.55]:
		for lz in [-0.3, 0.3]:
			_box(Vector3(0.04, 0.6, 0.04), CRAFT_TABLE + Vector3(lx, 0.3, lz), metal)
	for i in 4:
		_box(Vector3(0.25, 0.004 + i * 0.004, 0.32), CRAFT_TABLE + Vector3(-0.35 + i * 0.05, 0.645 + i * 0.004, 0.0), _mat(colors[i % 3]))
	var cup := CSGCylinder3D.new()
	cup.radius = 0.05
	cup.height = 0.1
	cup.position = CRAFT_TABLE + Vector3(0.35, 0.69, 0.1)
	cup.material = _mat(Color(0.95, 0.85, 0.2))
	add_child(cup)


func _back_of_room() -> void:
	var bz := D / 2 - 0.02
	# cubbies with everyone's backpacks
	var cubby := _mat(Color(0.7, 0.55, 0.35), 0.0, 0.6)
	_box(Vector3(4.0, 0.9, 0.4), Vector3(-2.6, 0.45, bz - 0.2), cubby, true)
	var packs := [Color(0.8, 0.15, 0.2), Color(0.2, 0.4, 0.8), Color(0.3, 0.6, 0.3), Color(0.6, 0.3, 0.7), Color(0.95, 0.6, 0.15)]
	for i in 8:
		_box(Vector3(0.32, 0.3, 0.22), Vector3(-4.2 + i * 0.46, 1.06, bz - 0.25), _mat(packs[i % packs.size()]))
	# the bulletin board: every holiday since September
	var cork := _mat(Color(0.72, 0.55, 0.38))
	var ex := W / 2 - 0.02
	_box(Vector3(0.03, 1.2, 3.4), Vector3(ex, 1.7, 1.2), cork)
	_text("We Are Thankful For...", Vector3(ex - 0.02, 2.2, 1.2), 40, Color(0.6, 0.2, 0.1), -90.0)
	var turkey := [Color(0.9, 0.5, 0.15), Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.55, 0.35, 0.2)]
	for i in 6:
		var p := Vector3(ex - 0.03, 1.55 + (i % 2) * 0.35, 0.0 + i * 0.45)
		for f in 4:
			var finger := CSGBox3D.new()
			finger.size = Vector3(0.006, 0.12, 0.035)
			finger.rotation_degrees.x = -40.0 + f * 27.0
			finger.position = p + Vector3(0, 0.03, 0)
			finger.material = _mat(turkey[f])
			add_child(finger)
		_box(Vector3(0.008, 0.08, 0.06), p, _mat(Color(0.5, 0.3, 0.15)))
	# Halloween bats nobody took down
	var bat := _mat(Color(0.08, 0.08, 0.1))
	for i in 4:
		var b := _box(Vector3(0.006, 0.05, 0.22), Vector3(ex - 0.03, 2.55, -1.5 + i * 0.7), bat)
		b.rotation_degrees.x = 8.0 * (1 if i % 2 else -1)
	# the reading rug, a rainbow of squares
	var rug_colors := [Color(0.85, 0.2, 0.2), Color(0.95, 0.6, 0.15), Color(0.95, 0.85, 0.25), Color(0.25, 0.6, 0.3), Color(0.2, 0.4, 0.8), Color(0.55, 0.3, 0.7)]
	for i in 6:
		for j in 4:
			_box(Vector3(0.5, 0.012, 0.5), RUG + Vector3(-1.25 + i * 0.5, 0.006, -0.75 + j * 0.5), _mat(rug_colors[(i + j) % 6]))
	# a paper-chain garland swooping across the room
	var chain := [Color(0.85, 0.15, 0.15), Color(0.15, 0.6, 0.25)]
	for i in 34:
		var t := float(i) / 33.0
		var link := CSGTorus3D.new()
		link.inner_radius = 0.02
		link.outer_radius = 0.035
		link.position = Vector3(-4.6 + t * 9.2, H - 0.25 - sin(t * PI) * 0.45, -0.8)
		link.rotation_degrees = Vector3(90, 0, 90 if i % 2 else 0)
		link.material = _mat(chain[i % 2])
		add_child(link)


func _party() -> void:
	var table := _mat(Color(0.85, 0.85, 0.82), 0.0, 0.5)
	_box(Vector3(2.0, 0.05, 0.8), PARTY_TABLE + Vector3(0, 0.66, 0), table, true)
	_box(Vector3(2.05, 0.01, 0.85), PARTY_TABLE + Vector3(0, 0.69, 0), _mat(Color(0.8, 0.15, 0.15)))
	var metal := _mat(Color(0.55, 0.55, 0.58))
	for lx in [-0.95, 0.95]:
		for lz in [-0.35, 0.35]:
			_box(Vector3(0.04, 0.66, 0.04), PARTY_TABLE + Vector3(lx, 0.33, lz), metal)
	var frosting := [Color(0.3, 0.8, 0.35), Color(0.95, 0.95, 0.95), Color(0.9, 0.3, 0.4)]
	for i in 12:
		var cake := CSGCylinder3D.new()
		cake.radius = 0.04
		cake.height = 0.05
		cake.position = PARTY_TABLE + Vector3(-0.8 + (i % 6) * 0.12, 0.72, -0.2 + (i / 6) * 0.12)
		cake.material = _mat(Color(0.95, 0.85, 0.6))
		add_child(cake)
		var top := CSGSphere3D.new()
		top.radius = 0.042
		top.position = cake.position + Vector3(0, 0.03, 0)
		top.material = _mat(frosting[i % 3])
		add_child(top)
	var boxes := [Color(0.95, 0.5, 0.1), Color(0.6, 0.2, 0.6), Color(0.2, 0.5, 0.9)]
	for i in 9:
		_box(Vector3(0.06, 0.1, 0.04), PARTY_TABLE + Vector3(0.2 + (i % 3) * 0.1, 0.745, -0.15 + (i / 3) * 0.1), _mat(boxes[i % 3]))
	# the Secret Santa pile
	var wraps := [Color(0.8, 0.1, 0.15), Color(0.15, 0.55, 0.25), Color(0.2, 0.35, 0.8), Color(0.9, 0.75, 0.2)]
	for i in 7:
		var g := _box(Vector3(0.22, 0.15 + (i % 3) * 0.04, 0.18), GIFT_PILE + Vector3(-0.4 + (i % 4) * 0.26, 0.08 + (i / 4) * 0.17, (i % 2) * 0.12), _mat(wraps[i % 4]))
		g.rotation_degrees.y = i * 17.0


func _lights() -> void:
	var panel := _mat(Color(0.95, 0.97, 1.0), 2.5)
	for x in [-2.5, 0.0, 2.5]:
		for z in [-2.0, 1.5]:
			_box(Vector3(1.2, 0.03, 0.6), Vector3(x, H - 0.02, z), panel)
			var l := OmniLight3D.new()
			l.light_color = Color(0.95, 0.97, 1.0)
			l.light_energy = 0.55
			l.omni_range = 6.0
			l.position = Vector3(x, H - 0.3, z)
			add_child(l)
	var window_light := OmniLight3D.new()
	window_light.light_color = Color(0.85, 0.9, 1.0)
	window_light.light_energy = 0.8
	window_light.omni_range = 7.0
	window_light.position = Vector3(-4.0, 1.8, 0.0)
	add_child(window_light)
