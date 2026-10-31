class_name Props
## Small modeled things for the house chapters, so a pie looks like a pie and
## not a tan box. Every builder returns a Node3D whose origin is the middle of
## its bottom, sized to roughly the footprint of the box it replaces. Hang one
## on a box_thing() with HouseChapter.dress().

const PAPER := Color(0.95, 0.93, 0.86)
const TIN := Color(0.72, 0.73, 0.75)
const WHITE := Color(0.96, 0.96, 0.94)
const SNOW := Color(0.94, 0.96, 1.0)
const FROSTING := [Color(0.95, 0.95, 0.97), Color(0.9, 0.25, 0.3), Color(0.3, 0.7, 0.4), Color(0.4, 0.6, 0.95)]


# --- Shape helpers -------------------------------------------------------

static func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, rot := Vector3.ZERO, glow := 0.0) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation_degrees = rot
	b.material = Decorations.mat(c, glow)
	parent.add_child(b)
	return b


static func cyl(parent: Node3D, r: float, h: float, pos: Vector3, c: Color, rot := Vector3.ZERO, cone := false) -> CSGCylinder3D:
	var y := CSGCylinder3D.new()
	y.radius = r
	y.height = h
	y.cone = cone
	y.sides = 16
	y.position = pos
	y.rotation_degrees = rot
	y.material = Decorations.mat(c)
	parent.add_child(y)
	return y


static func ball(parent: Node3D, r: float, pos: Vector3, c: Color, squash := Vector3.ONE) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = r
	s.radial_segments = 14
	s.rings = 8
	s.position = pos
	s.scale = squash
	s.material = Decorations.mat(c)
	parent.add_child(s)
	return s


static func ring(parent: Node3D, inner: float, outer: float, pos: Vector3, c: Color, rot := Vector3.ZERO) -> CSGTorus3D:
	var t := CSGTorus3D.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.position = pos
	t.rotation_degrees = rot
	t.material = Decorations.mat(c)
	parent.add_child(t)
	return t


static func label(parent: Node3D, text: String, pos: Vector3, size := 0.02, c := Color(0.15, 0.15, 0.2), rot := Vector3(-90, 0, 0)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = size / 32.0
	l.font_size = 32
	l.modulate = c
	l.outline_size = 0
	l.position = pos
	l.rotation_degrees = rot
	l.double_sided = false
	parent.add_child(l)
	return l


static func _root(n: String) -> Node3D:
	var r := Node3D.new()
	r.name = n
	return r


# --- Food ------------------------------------------------------------------

## A round cookie, flat on its back, with a dab of frosting and sprinkles.
static func cookie(parent: Node3D, pos: Vector3, frosting := -1) -> Node3D:
	var c := _root("Cookie")
	c.position = pos
	parent.add_child(c)
	cyl(c, 0.032, 0.01, Vector3(0, 0.005, 0), Color(0.88, 0.7, 0.45))
	if frosting >= 0:
		cyl(c, 0.027, 0.004, Vector3(0, 0.012, 0), FROSTING[frosting % FROSTING.size()])
		for i in 4:
			var a := i * 1.7 + frosting
			box(c, Vector3(0.008, 0.003, 0.003), Vector3(cos(a) * 0.014, 0.015, sin(a) * 0.014),
				Decorations.BULB_COLORS[(i + frosting) % Decorations.BULB_COLORS.size()], Vector3(0, a * 40.0, 0))
	return c


## A baking sheet of sugar cookies, half frosted, and the blue frosting bowl.
static func cookie_tray(decorated := 0) -> Node3D:
	var r := _root("CookieTray")
	box(r, Vector3(0.36, 0.01, 0.26), Vector3(0, 0.005, 0), TIN)
	for i in 6:
		cookie(r, Vector3(-0.11 + (i % 3) * 0.11, 0.01, -0.06 + (i / 3) * 0.12), i if i < decorated else -1)
	var bowl := _root("FrostingBowl")
	bowl.position = Vector3(0.24, 0, 0.04)
	r.add_child(bowl)
	cyl(bowl, 0.05, 0.05, Vector3(0, 0.025, 0), Color(0.25, 0.45, 0.85), Vector3.ZERO, false)
	cyl(bowl, 0.044, 0.004, Vector3(0, 0.05, 0), WHITE)
	box(bowl, Vector3(0.008, 0.004, 0.1), Vector3(0.02, 0.06, 0.02), Color(0.7, 0.7, 0.72), Vector3(25, 20, 0))
	return r


## Two pies in tins: pumpkin, and a pecan under foil (DO NOT TOUCH).
static func pies() -> Node3D:
	var r := _root("Pies")
	for i in 2:
		var x := -0.13 + i * 0.26
		cyl(r, 0.12, 0.035, Vector3(x, 0.0175, 0), TIN)
		cyl(r, 0.125, 0.012, Vector3(x, 0.036, 0), Color(0.82, 0.62, 0.38))
		if i == 0:
			cyl(r, 0.105, 0.006, Vector3(x, 0.04, 0), Color(0.85, 0.48, 0.18))
		else:
			ball(r, 0.12, Vector3(x, 0.035, 0), Color(0.82, 0.83, 0.86), Vector3(1, 0.22, 1))
			label(r, "DO NOT TOUCH", Vector3(x, 0.065, 0), 0.022, Color(0.1, 0.1, 0.12))
	return r


## A plate: three cookies for Santa, a glass of milk, and a folded note.
## `eaten` leaves crumbs, an empty glass and a reply instead.
static func santa_plate(eaten := false) -> Node3D:
	var r := _root("SantaPlate")
	cyl(r, 0.11, 0.012, Vector3(-0.02, 0.006, 0), WHITE)
	if eaten:
		for i in 7:
			ball(r, 0.004, Vector3(-0.05 + randf() * 0.07, 0.014, -0.04 + randf() * 0.07), Color(0.85, 0.68, 0.45))
		cookie(r, Vector3(0.01, 0.012, 0.03), 1).scale = Vector3(0.5, 1, 0.6)
	else:
		for i in 3:
			cookie(r, Vector3(-0.05 + i * 0.035, 0.012 + i * 0.006, -0.02 + (i % 2) * 0.04), i)
	cyl(r, 0.028, 0.1, Vector3(0.1, 0.05, -0.05), Color(0.85, 0.9, 0.95, 1.0))
	if not eaten:
		cyl(r, 0.026, 0.08, Vector3(0.1, 0.042, -0.05), WHITE)
	box(r, Vector3(0.07, 0.003, 0.05), Vector3(0.07, 0.002, 0.08), PAPER, Vector3(0, -15, 0))
	return r


## Three carrots with their green tops still on.
static func carrots(count := 3) -> Node3D:
	var r := _root("Carrots")
	for i in count:
		var z := -0.04 + i * 0.04
		cyl(r, 0.014, 0.17, Vector3(0.0, 0.014, z), Color(1.0, 0.5, 0.1), Vector3(0, 0, 90), true)
		for k in 3:
			box(r, Vector3(0.05, 0.004, 0.008), Vector3(-0.11, 0.016, z + (k - 1) * 0.008), Color(0.3, 0.6, 0.25), Vector3(0, (k - 1) * 20.0, 0))
	return r


## Grandma's fudge: the good round tin with the plaid band, lid off to the side.
static func fudge_tin(full := true) -> Node3D:
	var r := _root("FudgeTin")
	cyl(r, 0.09, 0.05, Vector3(0, 0.025, 0), Color(0.2, 0.35, 0.25))
	cyl(r, 0.092, 0.015, Vector3(0, 0.03, 0), Color(0.7, 0.15, 0.15))
	box(r, Vector3(0.184, 0.004, 0.012), Vector3(0, 0.03, 0), Color(0.12, 0.2, 0.15))
	cyl(r, 0.085, 0.004, Vector3(0, 0.046, 0), Color(0.95, 0.95, 0.92))
	for i in (6 if full else 3):
		box(r, Vector3(0.035, 0.022, 0.035), Vector3(-0.04 + (i % 3) * 0.04, 0.058, -0.02 + (i / 3) * 0.04), Color(0.3, 0.17, 0.1))
	var lid := cyl(r, 0.095, 0.012, Vector3(0.17, 0.006, 0.02), Color(0.2, 0.35, 0.25))
	lid.rotation_degrees.z = 8.0
	ball(r, 0.018, Vector3(0.17, 0.016, 0.02), Color(0.08, 0.08, 0.08), Vector3(1.4, 0.3, 0.8))
	return r


## Leftovers on a plate under a tent of foil, and a ham sandwich.
static func leftovers() -> Node3D:
	var r := _root("Leftovers")
	cyl(r, 0.11, 0.012, Vector3(-0.05, 0.006, 0), WHITE)
	ball(r, 0.1, Vector3(-0.05, 0.012, 0), Color(0.82, 0.83, 0.86), Vector3(1, 0.45, 1))
	box(r, Vector3(0.08, 0.012, 0.08), Vector3(0.1, 0.006, 0.02), Color(0.9, 0.78, 0.55))
	box(r, Vector3(0.075, 0.008, 0.075), Vector3(0.1, 0.016, 0.02), Color(0.9, 0.55, 0.55))
	box(r, Vector3(0.08, 0.012, 0.08), Vector3(0.1, 0.026, 0.02), Color(0.9, 0.78, 0.55))
	return r


## A mug with steam coming off it (cocoa, or Dad's coffee).
static func mug(c := Color(0.85, 0.2, 0.2), filling := Color(0.35, 0.2, 0.12)) -> Node3D:
	var r := _root("Mug")
	cyl(r, 0.04, 0.09, Vector3(0, 0.045, 0), c)
	cyl(r, 0.035, 0.004, Vector3(0, 0.082, 0), filling)
	ring(r, 0.015, 0.025, Vector3(0.045, 0.05, 0), c, Vector3(90, 0, 0))
	return r


## Snowman pancakes on a plate: three blobs, more or less in a stack.
static func pancake(parent: Node3D, pos: Vector3, r := 0.05, cooked := 0.6) -> CSGCylinder3D:
	var p := cyl(parent, r, 0.012, pos, Color(0.95, 0.85, 0.6).lerp(Color(0.75, 0.5, 0.25), cooked))
	p.scale = Vector3(1.0, 1.0, randf_range(0.8, 1.0))
	return p


## A frying pan on the burner.
static func frying_pan() -> Node3D:
	var r := _root("Pan")
	cyl(r, 0.12, 0.03, Vector3(0, 0.015, 0), Color(0.15, 0.15, 0.17))
	cyl(r, 0.11, 0.004, Vector3(0, 0.032, 0), Color(0.25, 0.25, 0.27))
	box(r, Vector3(0.2, 0.02, 0.03), Vector3(-0.2, 0.025, 0), Color(0.1, 0.1, 0.1))
	return r


## Party mix, the little hot dogs, and sparkling cider in fancy glasses.
static func snacks() -> Node3D:
	var r := _root("Snacks")
	cyl(r, 0.08, 0.05, Vector3(-0.13, 0.025, 0), Color(0.85, 0.85, 0.9))
	for i in 10:
		ball(r, 0.012, Vector3(-0.13 + randf_range(-0.05, 0.05), 0.055, randf_range(-0.05, 0.05)),
			[Color(0.75, 0.55, 0.3), Color(0.9, 0.8, 0.55), Color(0.5, 0.3, 0.15)][i % 3])
	cyl(r, 0.1, 0.01, Vector3(0.06, 0.005, 0.02), WHITE)
	for i in 6:
		var dog := cyl(r, 0.009, 0.05, Vector3(0.02 + (i % 3) * 0.035, 0.018, -0.01 + (i / 3) * 0.05), Color(0.7, 0.3, 0.2), Vector3(0, 0, 90))
		dog.rotation_degrees.y = randf_range(-20, 20)
	cyl(r, 0.022, 0.16, Vector3(0.2, 0.08, -0.06), Color(0.3, 0.45, 0.2))
	cyl(r, 0.01, 0.04, Vector3(0.2, 0.18, -0.06), Color(0.85, 0.75, 0.3))
	for side in [-1, 1]:
		var g := Vector3(0.18 + side * 0.04, 0, 0.08)
		cyl(r, 0.004, 0.06, g + Vector3(0, 0.03, 0), Color(0.85, 0.9, 0.95))
		cyl(r, 0.018, 0.045, g + Vector3(0, 0.08, 0), Color(0.95, 0.85, 0.5), Vector3.ZERO, true).rotation_degrees.x = 180
	return r


# --- Presents and paper -----------------------------------------------------

## A wrapped box with a ribbon both ways and a bow on top.
static func present(size: Vector3, paper: Color, ribbon := Color(0.95, 0.85, 0.3), tag := "") -> Node3D:
	var r := _root("Present")
	box(r, size, Vector3(0, size.y / 2, 0), paper)
	box(r, Vector3(size.x + 0.004, size.y + 0.004, 0.03), Vector3(0, size.y / 2, 0), ribbon)
	box(r, Vector3(0.03, size.y + 0.004, size.z + 0.004), Vector3(0, size.y / 2, 0), ribbon)
	for side in [-1, 1]:
		ring(r, 0.012, 0.03, Vector3(side * 0.025, size.y + 0.012, 0), ribbon, Vector3(90, side * 30, 0))
	if tag != "":
		box(r, Vector3(0.05, 0.002, 0.03), Vector3(size.x * 0.25, size.y + 0.003, size.z * 0.3), PAPER, Vector3(0, 20, 0))
	return r


## A present that's been taped about forty times. Rustic.
static func rustic_present(size: Vector3) -> Node3D:
	var r := present(size, Color(0.15, 0.45, 0.25), Color(0.85, 0.1, 0.12), "TO GRANDMA")
	for i in 9:
		box(r, Vector3(0.06, 0.002, 0.018), Vector3(randf_range(-0.1, 0.1), size.y + 0.002, randf_range(-0.08, 0.08)),
			Color(0.95, 0.95, 0.9, 1), Vector3(0, randf_range(0, 180), 0))
	return r


## The wrapping station: a roll of paper, a box waiting, tape and scissors.
static func wrapping_station() -> Node3D:
	var r := _root("Wrapping")
	cyl(r, 0.03, 0.45, Vector3(0, 0.03, -0.12), Color(0.15, 0.45, 0.25), Vector3(0, 0, 90))
	box(r, Vector3(0.4, 0.002, 0.22), Vector3(0.0, 0.001, 0.03), Color(0.15, 0.45, 0.25))
	box(r, Vector3(0.22, 0.12, 0.17), Vector3(-0.02, 0.06, 0.04), Color(0.7, 0.55, 0.35))
	box(r, Vector3(0.06, 0.035, 0.03), Vector3(0.17, 0.018, 0.1), Color(0.85, 0.2, 0.2))
	ring(r, 0.008, 0.016, Vector3(0.17, 0.035, 0.1), Color(0.9, 0.9, 0.85, 1), Vector3(0, 0, 90))
	for side in [-1, 1]:
		box(r, Vector3(0.09, 0.004, 0.012), Vector3(0.14, 0.004, -0.02), Color(0.6, 0.62, 0.65), Vector3(0, side * 10, 0))
	return r


## The big toy catalog, page 47 folded down.
static func catalog() -> Node3D:
	var r := _root("Catalog")
	box(r, Vector3(0.22, 0.02, 0.29), Vector3(0, 0.01, 0), PAPER)
	box(r, Vector3(0.22, 0.003, 0.29), Vector3(0, 0.021, 0), Color(0.85, 0.2, 0.2))
	box(r, Vector3(0.16, 0.002, 0.12), Vector3(0, 0.023, 0.05), Color(0.35, 0.55, 0.9))
	label(r, "TOYS", Vector3(0, 0.024, -0.09), 0.05, WHITE)
	box(r, Vector3(0.05, 0.002, 0.05), Vector3(0.09, 0.025, -0.125), PAPER, Vector3(0, 45, 0))
	return r


## The advent calendar on the wall: a little building with 24 doors.
## (Faces +X, flat against a wall behind it.)
static func advent_calendar() -> Node3D:
	var r := _root("Advent")
	box(r, Vector3(0.02, 0.3, 0.22), Vector3(0, 0.15, 0), Color(0.7, 0.12, 0.15))
	for i in 24:
		var row := i / 4
		var col := i % 4
		box(r, Vector3(0.006, 0.035, 0.035), Vector3(0.012, 0.03 + row * 0.045, -0.075 + col * 0.05), Color(0.35, 0.2, 0.08))
	label(r, "24", Vector3(0.017, 0.255, 0.075), 0.03, Color(0.95, 0.85, 0.3), Vector3(0, 90, 0))
	return r


## Grandma's thank-you note, the yellow marker, and the crayons.
static func letter_and_crayons() -> Node3D:
	var r := _root("Letter")
	box(r, Vector3(0.15, 0.002, 0.2), Vector3(0, 0.001, 0), PAPER)
	label(r, "Dear Grandma,", Vector3(0, 0.003, -0.06), 0.022)
	cyl(r, 0.006, 0.12, Vector3(0.11, 0.006, 0.04), Color(0.95, 0.85, 0.2), Vector3(90, 30, 0))
	for i in 4:
		cyl(r, 0.005, 0.08, Vector3(-0.12 + i * 0.013, 0.005, 0.05), Decorations.BULB_COLORS[i], Vector3(90, 0, 0))
	return r


# --- Stocking and toys --------------------------------------------------------

## A red stocking with a white cuff, hanging on a nail. Faces +Z, sits against a
## wall behind it. `full` gives it lumps and a candy cane sticking out.
static func stocking(full := true) -> Node3D:
	var r := _root("Stocking")
	box(r, Vector3(0.14, 0.26, 0.05 if full else 0.03), Vector3(0, 0.15, 0), Color(0.75, 0.1, 0.12))
	box(r, Vector3(0.18, 0.08, 0.05 if full else 0.03), Vector3(0.03, 0.04, 0), Color(0.75, 0.1, 0.12))
	box(r, Vector3(0.16, 0.07, 0.06), Vector3(0, 0.31, 0), WHITE)
	box(r, Vector3(0.12, 0.02, 0.005), Vector3(0, 0.31, 0.031), Color(0.2, 0.45, 0.25))
	label(r, "LEO", Vector3(0, 0.31, 0.034), 0.035, Color(0.85, 0.1, 0.12), Vector3.ZERO)
	if full:
		ring(r, 0.015, 0.024, Vector3(-0.03, 0.38, 0), Color(0.95, 0.95, 0.95), Vector3(90, 0, 0))
		ball(r, 0.03, Vector3(0.03, 0.36, 0), Color(0.3, 0.6, 0.9))
	return r


## What comes out of the stocking, one at a time.
static func stocking_item(id: String) -> Node3D:
	var r := _root(id.capitalize())
	match id:
		"candy":
			for i in 5:
				var c := cyl(r, 0.012, 0.06, Vector3(-0.04 + i * 0.02, 0.012, randf_range(-0.02, 0.02)),
					Decorations.BULB_COLORS[i % Decorations.BULB_COLORS.size()], Vector3(90, randf_range(-30, 30), 0))
				c.rotation_degrees.y = randf_range(-40, 40)
		"yoyo":
			cyl(r, 0.03, 0.014, Vector3(0, 0.03, -0.008), Color(0.2, 0.4, 0.9), Vector3(90, 0, 0))
			cyl(r, 0.03, 0.014, Vector3(0, 0.03, 0.008), Color(0.2, 0.4, 0.9), Vector3(90, 0, 0))
			box(r, Vector3(0.002, 0.002, 0.12), Vector3(0, 0.002, 0.07), WHITE)
		"cards":
			box(r, Vector3(0.065, 0.012, 0.09), Vector3(0, 0.006, 0), Color(0.95, 0.8, 0.15))
			box(r, Vector3(0.05, 0.002, 0.04), Vector3(0, 0.013, -0.01), Color(0.9, 0.2, 0.2))
			label(r, "TRADING CARDS", Vector3(0, 0.014, 0.03), 0.014)
		"toothbrush":
			box(r, Vector3(0.16, 0.012, 0.014), Vector3(0, 0.006, 0), Color(0.3, 0.75, 0.85))
			box(r, Vector3(0.03, 0.015, 0.014), Vector3(0.065, 0.019, 0), WHITE)
		"orange":
			ball(r, 0.035, Vector3(0, 0.035, 0), Color(1.0, 0.55, 0.1))
			box(r, Vector3(0.01, 0.006, 0.006), Vector3(0, 0.07, 0), Color(0.3, 0.5, 0.2))
	return r


## The Mega Robo Racer: a blue car with a robot sitting up in it.
static func robo_racer() -> Node3D:
	var r := _root("RoboRacer")
	box(r, Vector3(0.26, 0.05, 0.13), Vector3(0, 0.045, 0), Color(0.15, 0.35, 0.8))
	box(r, Vector3(0.08, 0.03, 0.12), Vector3(0.1, 0.075, 0), Color(0.9, 0.85, 0.2))
	box(r, Vector3(0.06, 0.08, 0.07), Vector3(-0.03, 0.11, 0), Color(0.7, 0.72, 0.75))
	box(r, Vector3(0.05, 0.04, 0.05), Vector3(-0.03, 0.17, 0), Color(0.7, 0.72, 0.75))
	for side in [-1, 1]:
		ball(r, 0.008, Vector3(-0.005, 0.175, side * 0.012), Color(1, 0.2, 0.2))
		for x in [-0.08, 0.08]:
			cyl(r, 0.03, 0.025, Vector3(x, 0.03, side * 0.07), Color(0.08, 0.08, 0.08), Vector3(90, 0, 0))
	box(r, Vector3(0.004, 0.05, 0.004), Vector3(-0.03, 0.215, 0), Color(0.2, 0.2, 0.2))
	ball(r, 0.008, Vector3(-0.03, 0.245, 0), Color(1, 0.2, 0.2))
	return r


## The Robo Racer's box, still wrapped: present paper with robots peeking through a tear.
static func racer_box(size: Vector3) -> Node3D:
	var r := present(size, Color(0.15, 0.35, 0.8), Color(0.95, 0.95, 0.95))
	box(r, Vector3(0.1, 0.002, 0.06), Vector3(-0.1, size.y + 0.002, 0.05), Color(0.9, 0.85, 0.2))
	return r


## Two dice with their pips showing.
static func dice() -> Node3D:
	var r := _root("Dice")
	for i in 2:
		var d := _root("Die%d" % i)
		d.position = Vector3(-0.022 + i * 0.044, 0.013, 0)
		d.rotation_degrees.y = 20 + i * 35
		r.add_child(d)
		box(d, Vector3(0.026, 0.026, 0.026), Vector3.ZERO, WHITE)
		var pips := [Vector2(-0.007, -0.007), Vector2(0.007, 0.007), Vector2(0, 0)] if i == 0 else [Vector2(-0.007, -0.007), Vector2(0.007, 0.007), Vector2(-0.007, 0.007), Vector2(0.007, -0.007)]
		for p: Vector2 in pips:
			ball(d, 0.0035, Vector3(p.x, 0.0125, p.y), Color(0.05, 0.05, 0.05))
	return r


# --- Snow and Biscuit ---------------------------------------------------------

## A drift of snow: a few squashed lumps.
static func snow_pile(size: Vector3) -> Node3D:
	var r := _root("SnowPile")
	for i in 5:
		var x := -size.x / 2 + size.x * (i + 0.5) / 5.0
		ball(r, size.z * 0.6, Vector3(x, 0.0, randf_range(-0.05, 0.05)), SNOW,
			Vector3(1.4, size.y / (size.z * 0.6) * randf_range(0.8, 1.2), 1.0))
	return r


## A snowball.
static func snowball() -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = 0.04
	s.radial_segments = 12
	s.rings = 8
	s.material = Decorations.mat(SNOW)
	return s


## Biscuit's red reindeer bandana: a triangle under his collar with little
## antlers printed on it. Safe to call twice.
static func tie_bandana(d: Dog) -> void:
	var torso := d._torso as Node3D
	if torso.has_node("Bandana"):
		return
	var b := _root("Bandana")
	# Just in front of his white chest, under the collar.
	b.position = Vector3(0, 0.03, -0.335)
	b.rotation_degrees.x = -15.0
	torso.add_child(b)
	var cloth := CSGPolygon3D.new()
	cloth.polygon = PackedVector2Array([Vector2(-0.085, 0), Vector2(0.085, 0), Vector2(0, -0.13)])
	cloth.depth = 0.012
	cloth.material = Decorations.mat(Color(0.78, 0.1, 0.12))
	b.add_child(cloth)
	var trim := CSGBox3D.new()
	trim.size = Vector3(0.17, 0.012, 0.014)
	trim.material = Decorations.mat(WHITE)
	b.add_child(trim)
	for side in [-1, 1]:
		var antler := CSGBox3D.new()
		antler.size = Vector3(0.006, 0.03, 0.004)
		antler.position = Vector3(side * 0.012, -0.045, 0.008)
		antler.rotation_degrees.z = side * -25.0
		antler.material = Decorations.mat(Color(0.5, 0.32, 0.18))
		b.add_child(antler)
	var nose := CSGSphere3D.new()
	nose.radius = 0.008
	nose.position = Vector3(0, -0.07, 0.008)
	nose.material = Decorations.mat(Color(1, 0.2, 0.2), 1.0)
	b.add_child(nose)


# --- Getting ready ------------------------------------------------------------

## Leo's puffy coat on a hook, his shoes on the floor under it. Faces +Z,
## flat against a wall behind it.
static func coat_on_hook(drop: float) -> Node3D:
	var r := _root("Coat")
	var blue := Color(0.2, 0.35, 0.6)
	var seam := blue.darkened(0.3)
	cyl(r, 0.008, 0.06, Vector3(0, 0.53, -0.03), Color(0.6, 0.6, 0.62), Vector3(90, 0, 0))
	# The hood, hanging off the hook behind the collar.
	ball(r, 0.09, Vector3(0, 0.47, -0.02), seam, Vector3(1.2, 1.0, 0.6))
	# Body: a puffy rounded box, with the quilted seams across it.
	var body := box(r, Vector3(0.32, 0.4, 0.1), Vector3(0, 0.25, 0.01), blue)
	body.scale = Vector3(1, 1, 1)
	for k in 3:
		box(r, Vector3(0.325, 0.008, 0.104), Vector3(0, 0.13 + k * 0.1, 0.01), seam)
	# Sleeves hanging straight down, a little in front of the body.
	for side in [-1, 1]:
		box(r, Vector3(0.08, 0.36, 0.09), Vector3(side * 0.19, 0.24, 0.02), blue, Vector3(0, 0, side * 4))
		box(r, Vector3(0.082, 0.03, 0.092), Vector3(side * 0.2, 0.07, 0.02), seam, Vector3(0, 0, side * 4))
	box(r, Vector3(0.006, 0.38, 0.004), Vector3(0, 0.25, 0.062), Color(0.75, 0.75, 0.78))
	for side in [-1, 1]:
		box(r, Vector3(0.08, 0.06, 0.18), Vector3(side * 0.06, -drop + 0.03, 0.1), Color(0.85, 0.85, 0.88), Vector3(0, side * 12, 0))
	return r


## A handheld game: a purple clamshell, open, the low-battery light on.
static func handheld() -> Node3D:
	var r := _root("Handheld")
	var purple := Color(0.45, 0.3, 0.6)
	box(r, Vector3(0.13, 0.012, 0.07), Vector3(0, 0.006, 0.03), purple)
	box(r, Vector3(0.13, 0.07, 0.012), Vector3(0, 0.04, -0.01), purple, Vector3(-15, 0, 0))
	box(r, Vector3(0.08, 0.05, 0.002), Vector3(0, 0.042, -0.002), Color(0.55, 0.7, 0.55), Vector3(-15, 0, 0), 0.6)
	box(r, Vector3(0.03, 0.004, 0.01), Vector3(-0.035, 0.014, 0.035), Color(0.15, 0.15, 0.15))
	box(r, Vector3(0.01, 0.004, 0.03), Vector3(-0.035, 0.014, 0.035), Color(0.15, 0.15, 0.15))
	for x in [0.03, 0.045]:
		ball(r, 0.006, Vector3(x, 0.014, 0.035 - (x - 0.03)), Color(0.85, 0.2, 0.3))
	ball(r, 0.003, Vector3(0.05, 0.014, 0.055), Color(1, 0.15, 0.1)).material = Decorations.mat(Color(1, 0.15, 0.1), 3.0)
	return r


## Biscuit's red leash, looped over a hook. Faces +Z against a wall.
static func leash_on_hook() -> Node3D:
	var r := _root("Leash")
	var red := Color(0.8, 0.15, 0.15)
	cyl(r, 0.008, 0.05, Vector3(0, 0.33, -0.02), Color(0.6, 0.6, 0.62), Vector3(90, 0, 0))
	for side in [-1, 1]:
		box(r, Vector3(0.015, 0.3, 0.006), Vector3(side * 0.02, 0.18, 0.0), red, Vector3(0, 0, side * 4))
	ring(r, 0.02, 0.03, Vector3(0, 0.02, 0), red, Vector3(90, 0, 0))
	ball(r, 0.012, Vector3(0, 0.05, 0.008), Color(0.75, 0.75, 0.7))
	return r


# --- Pictures ------------------------------------------------------------

## A framed photo with a real little picture in it (painted in code): faces
## +Z, flat against a wall behind it. `kind`: family, beach, wedding, school,
## baby, dog, lake, grandpa, halloween, snow. `size` is the frame's outside.
static func photo(kind: String, size := Vector2(0.24, 0.18), frame := Color(0.45, 0.3, 0.18)) -> Node3D:
	var r := _root("Photo")
	var border := 0.018
	box(r, Vector3(size.x, size.y, 0.015), Vector3(0, size.y / 2.0, 0.0075), frame)
	box(r, Vector3(size.x - border * 1.4, size.y - border * 1.4, 0.003), Vector3(0, size.y / 2.0, 0.0155), Color(0.95, 0.94, 0.9))
	var pic := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(size.x - border * 2.6, size.y - border * 2.6)
	pic.mesh = quad
	pic.position = Vector3(0, size.y / 2.0, 0.0175)
	var m := StandardMaterial3D.new()
	m.albedo_texture = photo_texture(kind, size.x / size.y)
	m.roughness = 0.35
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	pic.material_override = m
	r.add_child(pic)
	return r


static var _photo_cache := {}


## The picture inside photo(): a tiny snapshot, painted pixel by pixel.
static func photo_texture(kind: String, aspect := 1.33) -> ImageTexture:
	var key := "%s_%.2f" % [kind, aspect]
	if _photo_cache.has(key):
		return _photo_cache[key]
	var h := 48
	var w := int(round(h * aspect))
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"beach":
			_fill(img, 0, 0, w, h * 0.5, Color(0.55, 0.75, 0.95), Color(0.75, 0.88, 1.0))
			_fill(img, 0, h * 0.45, w, h * 0.2, Color(0.15, 0.45, 0.7), Color(0.25, 0.6, 0.8))
			_fill(img, 0, h * 0.65, w, h * 0.35, Color(0.92, 0.82, 0.6), Color(0.85, 0.75, 0.55))
			_disc(img, w * 0.82, h * 0.15, 4, Color(1, 0.95, 0.7))
			_people(img, [[0.35, 0.55, Color(0.9, 0.3, 0.3)], [0.5, 0.6, Color(0.3, 0.5, 0.9)], [0.62, 0.42, Color(0.95, 0.8, 0.2)]], h)
		"wedding":
			_fill(img, 0, 0, w, h, Color(0.82, 0.78, 0.72), Color(0.7, 0.66, 0.6))
			_people(img, [[0.38, 0.85, Color(0.97, 0.97, 0.95)], [0.6, 0.95, Color(0.15, 0.15, 0.18)]], h, true)
			_disc(img, w * 0.36, h * 0.82, 3, Color(0.9, 0.5, 0.6))
		"school":
			# The laser background. Everybody's had one.
			_fill(img, 0, 0, w, h, Color(0.2, 0.15, 0.45), Color(0.05, 0.4, 0.6))
			for i in 6:
				var y0 := rng.randi_range(0, h)
				for x in w:
					var y := y0 + int(x * 0.6) - w / 3
					if y >= 0 and y < h:
						img.set_pixel(x, y, Color(1, 0.4, 0.9))
			_people(img, [[0.5, 1.15, Color(0.3, 0.55, 0.35)]], h)
		"baby":
			_fill(img, 0, 0, w, h, Color(0.85, 0.82, 0.9), Color(0.75, 0.8, 0.9))
			_disc(img, w * 0.5, h * 0.62, 13, Color(0.75, 0.85, 0.95))
			_disc(img, w * 0.5, h * 0.42, 8, Color(0.95, 0.8, 0.7))
		"dog":
			_fill(img, 0, 0, w, h * 0.55, Color(0.6, 0.75, 0.9), Color(0.75, 0.85, 0.95))
			_fill(img, 0, h * 0.55, w, h * 0.45, Color(0.35, 0.6, 0.3), Color(0.3, 0.5, 0.25))
			_disc(img, w * 0.48, h * 0.62, 9, Color(0.8, 0.55, 0.3))
			_disc(img, w * 0.62, h * 0.5, 6, Color(0.8, 0.55, 0.3))
			_disc(img, w * 0.64, h * 0.48, 1, Color(0.1, 0.1, 0.1))
			_people(img, [[0.3, 0.7, Color(0.95, 0.75, 0.2)]], h)
		"lake":
			_fill(img, 0, 0, w, h * 0.4, Color(0.95, 0.7, 0.5), Color(0.6, 0.6, 0.85))
			_fill(img, 0, h * 0.4, w, h * 0.2, Color(0.2, 0.32, 0.22), Color(0.15, 0.28, 0.2))
			_fill(img, 0, h * 0.6, w, h * 0.4, Color(0.3, 0.45, 0.65), Color(0.2, 0.3, 0.5))
			_fill(img, w * 0.2, h * 0.68, w * 0.35, 3, Color(0.6, 0.4, 0.25), Color(0.6, 0.4, 0.25))
			_people(img, [[0.3, 0.4, Color(0.85, 0.2, 0.2)], [0.42, 0.4, Color(0.2, 0.2, 0.25)]], h)
		"grandpa":
			# Black and white, a little faded: Grandpa, young, by his car.
			_fill(img, 0, 0, w, h, Color(0.72, 0.68, 0.6), Color(0.55, 0.52, 0.46))
			_fill(img, w * 0.45, h * 0.6, w * 0.5, h * 0.22, Color(0.25, 0.24, 0.22), Color(0.2, 0.2, 0.18))
			_people(img, [[0.3, 1.0, Color(0.3, 0.29, 0.27)]], h, true)
		"halloween":
			_fill(img, 0, 0, w, h, Color(0.1, 0.08, 0.2), Color(0.25, 0.12, 0.2))
			_people(img, [[0.35, 0.75, Color(0.95, 0.95, 0.95)], [0.6, 1.0, Color(0.1, 0.1, 0.1)]], h)
			_disc(img, w * 0.5, h * 0.88, 4, Color(0.95, 0.5, 0.1))
		"snow":
			_fill(img, 0, 0, w, h * 0.5, Color(0.7, 0.75, 0.85), Color(0.85, 0.88, 0.92))
			_fill(img, 0, h * 0.5, w, h * 0.5, Color(0.95, 0.96, 1.0), Color(0.88, 0.9, 0.95))
			_disc(img, w * 0.65, h * 0.72, 7, Color(0.97, 0.97, 1.0))
			_disc(img, w * 0.65, h * 0.55, 5, Color(0.97, 0.97, 1.0))
			_people(img, [[0.35, 0.8, Color(0.85, 0.2, 0.2)], [0.45, 1.0, Color(0.2, 0.3, 0.7)]], h)
		_:
			# The whole family on the porch, everybody squinting.
			_fill(img, 0, 0, w, h * 0.5, Color(0.65, 0.78, 0.92), Color(0.8, 0.86, 0.9))
			_fill(img, 0, h * 0.5, w, h * 0.5, Color(0.55, 0.45, 0.35), Color(0.45, 0.37, 0.3))
			_people(img, [[0.22, 1.0, Color(0.6, 0.55, 0.75)], [0.4, 1.05, Color(0.6, 0.2, 0.15)], [0.58, 0.85, Color(0.12, 0.12, 0.14)], [0.74, 0.65, Color(0.95, 0.75, 0.2)]], h)
			_disc(img, w * 0.86, h * 0.86, 4, Color(0.8, 0.55, 0.3))
	# A faint warm cast, like a drugstore print.
	for y in h:
		for x in w:
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(1.0, 0.9, 0.75), 0.08))
	var tex := ImageTexture.create_from_image(img)
	_photo_cache[key] = tex
	return tex


static func _fill(img: Image, x0: float, y0: float, fw: float, fh: float, top: Color, bottom: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(maxi(0, int(y0)), mini(h, int(y0 + fh))):
		var c := top.lerp(bottom, (y - y0) / maxf(fh, 1.0))
		for x in range(maxi(0, int(x0)), mini(w, int(x0 + fw))):
			img.set_pixel(x, y, c)


static func _disc(img: Image, cx: float, cy: float, rad: float, c: Color) -> void:
	for y in range(int(cy - rad), int(cy + rad) + 1):
		for x in range(int(cx - rad), int(cx + rad) + 1):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and Vector2(x - cx, y - cy).length() <= rad:
				img.set_pixel(x, y, c)


## Little people standing on the bottom of the picture: [x (0-1), height
## (1 = a grown-up), shirt color]. `formal` gives everyone dark legs and a
## tidy pose.
static func _people(img: Image, who: Array, h: int, formal := false) -> void:
	var w := img.get_width()
	for p: Array in who:
		var cx: float = p[0] * w
		var tall: float = p[1] * h * 0.62
		var feet := h - 2.0
		var legs := Color(0.15, 0.15, 0.2) if formal else Color(0.25, 0.3, 0.45)
		_fill(img, cx - 2, feet - tall * 0.45, 2, tall * 0.45, legs, legs)
		_fill(img, cx + 1, feet - tall * 0.45, 2, tall * 0.45, legs, legs)
		_fill(img, cx - 3.5, feet - tall * 0.85, 8, tall * 0.42, p[2], (p[2] as Color).darkened(0.2))
		var head := maxf(2.0, tall * 0.11)
		_disc(img, cx + 0.5, feet - tall * 0.85 - head, head, Color(0.92, 0.75, 0.62))
		_fill(img, cx + 0.5 - head, feet - tall * 0.85 - head * 2.1, head * 2.0, head * 0.9, Color(0.3, 0.2, 0.12), Color(0.3, 0.2, 0.12))


# --- 2003 ------------------------------------------------------------------

## Earbuds on a cord down to a portable CD player in Jamie's lap.
## `who` is a seated figure of `height` (Figure.person).
static func discman(who: Node3D, height := 1.62) -> void:
	var head_y := 0.8656 * height - 0.136 * height
	for side in [-1, 1]:
		ball(who, 0.018, Vector3(0.11 * side, head_y - 0.01, 0), Color(0.92, 0.92, 0.9))
	var cord := cyl(who, 0.004, 0.5, Vector3(0.06, head_y - 0.27, -0.06), Color(0.92, 0.92, 0.9), Vector3(12, 0, 0))
	cord.sides = 6
	var player := Node3D.new()
	player.position = Vector3(0.04, head_y - 0.5, 0.16)
	who.add_child(player)
	cyl(player, 0.07, 0.025, Vector3.ZERO, Color(0.7, 0.72, 0.76))
	cyl(player, 0.03, 0.004, Vector3(0, 0.013, 0), Color(0.3, 0.35, 0.45))
	box(player, Vector3(0.025, 0.004, 0.01), Vector3(0.0, 0.013, 0.05), Color(0.2, 0.9, 0.5), Vector3.ZERO, 1.0)
	# The CD wallet next to him, zipped half open.
	box(who, Vector3(0.16, 0.035, 0.16), Vector3(-0.2, head_y - 0.52, 0.18), Color(0.12, 0.12, 0.14))
	box(who, Vector3(0.12, 0.004, 0.12), Vector3(-0.2, head_y - 0.5, 0.18), Color(0.75, 0.78, 0.85))


## A free-trial internet CD in a cardboard sleeve, the kind that came in the mail every week.
static func trial_cd() -> Node3D:
	var r := _root("TrialCD")
	box(r, Vector3(0.13, 0.004, 0.13), Vector3(0, 0.002, 0), Color(0.15, 0.3, 0.75))
	cyl(r, 0.055, 0.002, Vector3(0.01, 0.005, 0.0), Color(0.8, 0.82, 0.88))
	label(r, "500 HOURS\nFREE!", Vector3(-0.03, 0.0045, 0.03), 0.014, Color(1, 0.9, 0.2))
	return r


## A cordless phone in its cradle, and the answering machine with its
## little red number blinking.
static func phone_and_machine(messages := 1) -> Node3D:
	var r := _root("PhoneMachine")
	box(r, Vector3(0.1, 0.03, 0.14), Vector3(-0.08, 0.015, 0), Color(0.88, 0.87, 0.84))
	box(r, Vector3(0.05, 0.18, 0.025), Vector3(-0.08, 0.1, -0.03), Color(0.88, 0.87, 0.84), Vector3(-12, 0, 0))
	box(r, Vector3(0.016, 0.06, 0.004), Vector3(-0.08, 0.17, -0.012), Color(0.3, 0.4, 0.35), Vector3(-12, 0, 0))
	box(r, Vector3(0.14, 0.045, 0.11), Vector3(0.07, 0.022, 0), Color(0.12, 0.12, 0.13))
	box(r, Vector3(0.022, 0.016, 0.004), Vector3(0.1, 0.046, 0.02), Color(0.2, 0.02, 0.02))
	if messages > 0:
		label(r, str(messages), Vector3(0.1, 0.0475, 0.02), 0.014, Color(1, 0.15, 0.1))
	cyl(r, 0.02, 0.004, Vector3(0.04, 0.046, 0.01), Color(0.6, 0.6, 0.62))
	return r


## A wall phone with a long, tangled cord (Grandma's, and the kitchen's).
static func wall_phone(c := Color(0.9, 0.86, 0.75)) -> Node3D:
	var r := _root("WallPhone")
	box(r, Vector3(0.12, 0.2, 0.05), Vector3(0, 0.1, 0.025), c)
	box(r, Vector3(0.05, 0.2, 0.045), Vector3(-0.02, 0.1, 0.07), c)
	for i in 9:
		ring(r, 0.012, 0.02, Vector3(0.03 + sin(i * 0.9) * 0.02, -0.02 - i * 0.045, 0.06), Color(c).darkened(0.1), Vector3(0, 0, 90))
	return r


## A clock radio with red numbers.
static func clock_radio(time := "7:00") -> Node3D:
	var r := _root("ClockRadio")
	box(r, Vector3(0.2, 0.07, 0.1), Vector3(0, 0.035, 0), Color(0.1, 0.1, 0.11), Vector3(-6, 0, 0))
	label(r, time, Vector3(-0.02, 0.04, 0.051), 0.035, Color(1, 0.12, 0.08), Vector3.ZERO).modulate = Color(1, 0.12, 0.08)
	return r


## A video game controller with its cord.
static func controller(cord := 0.6) -> Node3D:
	var r := _root("Controller")
	var g := Color(0.15, 0.15, 0.17)
	box(r, Vector3(0.1, 0.025, 0.05), Vector3(0, 0.0125, 0), g)
	for side in [-1, 1]:
		ball(r, 0.026, Vector3(side * 0.05, 0.012, 0.02), g, Vector3(1, 0.5, 1.4))
	ball(r, 0.006, Vector3(0.035, 0.026, -0.005), Color(0.2, 0.7, 0.3))
	ball(r, 0.006, Vector3(0.05, 0.026, 0.005), Color(0.85, 0.2, 0.2))
	box(r, Vector3(0.02, 0.005, 0.006), Vector3(-0.04, 0.026, 0), Color(0.05, 0.05, 0.05))
	box(r, Vector3(0.006, 0.005, 0.02), Vector3(-0.04, 0.026, 0), Color(0.05, 0.05, 0.05))
	if cord > 0.0:
		box(r, Vector3(0.006, 0.006, cord), Vector3(0, 0.003, -0.025 - cord / 2.0), Color(0.1, 0.1, 0.1))
	return r


# --- Cars --------------------------------------------------------------------

## A parked car, long side along Z, nose toward -Z. `style`: sedan, wagon,
## hatchback, pickup, minivan, suv. Bottom at y = 0.
static func car(style: String, paint: Color) -> Node3D:
	var r := _root("Car")
	var glass := Color(0.12, 0.15, 0.2)
	var black := Color(0.06, 0.06, 0.07)
	var chrome := Color(0.7, 0.72, 0.75)
	# [length, width, body height, cabin start (from nose), cabin length, cabin height, ride]
	var d: Array = {
		"sedan": [4.6, 1.75, 0.55, 1.35, 2.3, 0.45, 0.25],
		"wagon": [4.7, 1.75, 0.55, 1.35, 3.0, 0.48, 0.25],
		"hatchback": [3.9, 1.65, 0.55, 1.1, 2.3, 0.48, 0.22],
		"pickup": [5.2, 1.85, 0.7, 1.6, 1.5, 0.55, 0.38],
		"minivan": [4.9, 1.85, 0.7, 0.95, 3.75, 0.65, 0.25],
		"suv": [4.6, 1.85, 0.75, 1.15, 3.2, 0.6, 0.4],
	}.get(style, [4.6, 1.75, 0.55, 1.35, 2.3, 0.45, 0.25])
	var length: float = d[0]
	var width: float = d[1]
	var body_h: float = d[2]
	var ride: float = d[6]
	var nose := -length / 2.0
	box(r, Vector3(width, body_h, length), Vector3(0, ride + body_h / 2.0, 0), paint)
	# Cabin and its windows (a dark band all around, with pillars in paint).
	var cab_z: float = nose + d[3] + d[4] / 2.0
	var cab_h: float = d[5]
	var cab := box(r, Vector3(width - 0.12, cab_h, d[4]), Vector3(0, ride + body_h + cab_h / 2.0, cab_z), paint)
	box(cab, Vector3(width - 0.1, cab_h * 0.72, d[4] - 0.25), Vector3(0, -0.02, 0), glass)
	box(cab, Vector3(width - 0.3, cab_h * 0.7, d[4] + 0.02), Vector3(0, -0.02, 0), glass)
	if style == "pickup":
		# The bed: open, with a toolbox.
		var bed_z: float = nose + d[3] + d[4] + 0.05
		var bed_len: float = length - d[3] - d[4] - 0.1
		box(r, Vector3(width - 0.1, 0.02, bed_len), Vector3(0, ride + body_h + 0.01, bed_z + bed_len / 2.0), black)
		box(r, Vector3(width - 0.2, 0.25, 0.4), Vector3(0, ride + body_h + 0.13, bed_z + 0.25), Color(0.75, 0.1, 0.1))
	# Wheels, bumpers, lights, plates.
	for x in [-width / 2.0 + 0.05, width / 2.0 - 0.05]:
		for z in [nose + 0.85, length / 2.0 - 0.85]:
			var wheel := cyl(r, 0.32, 0.22, Vector3(x, 0.32, z), black, Vector3(0, 0, 90))
			cyl(wheel, 0.17, 0.23, Vector3.ZERO, chrome)
	box(r, Vector3(width + 0.04, 0.14, 0.12), Vector3(0, ride + 0.07, nose - 0.04), Color(0.25, 0.25, 0.27))
	box(r, Vector3(width + 0.04, 0.14, 0.12), Vector3(0, ride + 0.07, length / 2.0 + 0.04), Color(0.25, 0.25, 0.27))
	for side in [-1, 1]:
		box(r, Vector3(0.32, 0.12, 0.03), Vector3(side * (width / 2.0 - 0.25), ride + body_h - 0.15, nose - 0.01), Color(1.0, 0.97, 0.85))
		box(r, Vector3(0.25, 0.14, 0.03), Vector3(side * (width / 2.0 - 0.2), ride + body_h - 0.15, length / 2.0 + 0.01), Color(0.75, 0.08, 0.06))
	box(r, Vector3(0.6, 0.16, 0.02), Vector3(0, ride + body_h * 0.45, nose - 0.005), black)
	box(r, Vector3(0.32, 0.16, 0.02), Vector3(0, ride + 0.25, length / 2.0 + 0.11), Color(0.95, 0.95, 0.9))
	# Side mirrors and door handles.
	for side in [-1, 1]:
		box(r, Vector3(0.1, 0.1, 0.06), Vector3(side * (width / 2.0 + 0.04), ride + body_h + 0.05, nose + d[3] + 0.1), black)
		box(r, Vector3(0.012, 0.03, 0.12), Vector3(side * (width / 2.0 + 0.005), ride + body_h - 0.12, cab_z - 0.3), chrome)
	return r


# --- Thanksgiving ---------------------------------------------------------

## The turkey on its platter: golden, glossy, drumsticks up, a few slices
## already carved off the near side. Long axis along X.
static func roast_turkey() -> Node3D:
	var r := _root("Turkey")
	cyl(r, 0.22, 0.015, Vector3(0, 0.008, 0), Color(0.93, 0.92, 0.88))
	ring(r, 0.19, 0.23, Vector3(0, 0.014, 0), Color(0.55, 0.62, 0.75))
	var skin := Color(0.72, 0.42, 0.16)
	var body := ball(r, 0.12, Vector3(0, 0.085, 0), skin, Vector3(1.25, 0.75, 1.0))
	body.material = Decorations.mat(skin)
	(body.material as StandardMaterial3D).roughness = 0.35
	for side in [-1, 1]:
		var leg := ball(r, 0.05, Vector3(0.1, 0.11, side * 0.07), Color(0.68, 0.38, 0.14), Vector3(1.4, 0.9, 0.9))
		leg.rotation_degrees.z = 25.0
		cyl(r, 0.012, 0.05, Vector3(0.17, 0.14, side * 0.065), Color(0.95, 0.92, 0.85), Vector3(0, 0, 60))
		ball(r, 0.045, Vector3(-0.02, 0.09, side * 0.1), Color(0.7, 0.4, 0.15), Vector3(1.2, 0.6, 0.6))
	# Carved slices fanned on the platter.
	for i in 4:
		box(r, Vector3(0.07, 0.008, 0.05), Vector3(-0.13 + i * 0.012, 0.022 + i * 0.004, 0.12 - i * 0.015), Color(0.93, 0.85, 0.72), Vector3(0, i * 10, 8))
	# Parsley and cranberries around the edge.
	for i in 6:
		var a := i * TAU / 6.0 + 0.3
		ball(r, 0.018, Vector3(cos(a) * 0.18, 0.02, sin(a) * 0.17), Color(0.2, 0.5, 0.15) if i % 2 else Color(0.7, 0.05, 0.1))
	return r


## A serving dish: potatoes, beans, stuffing, cranberry, corn, butter, gravy.
static func dish(kind: String) -> Node3D:
	var r := _root("Dish")
	match kind:
		"potatoes":
			cyl(r, 0.09, 0.06, Vector3(0, 0.03, 0), Color(0.95, 0.95, 0.93))
			ball(r, 0.085, Vector3(0, 0.06, 0), Color(0.97, 0.95, 0.85), Vector3(1, 0.5, 1))
			ball(r, 0.02, Vector3(0, 0.1, 0), Color(0.97, 0.85, 0.35), Vector3(1, 0.4, 1))
			cyl(r, 0.006, 0.18, Vector3(0.04, 0.12, 0), Color(0.75, 0.75, 0.78), Vector3(0, 0, -40))
		"beans":
			box(r, Vector3(0.22, 0.05, 0.15), Vector3(0, 0.025, 0), Color(0.95, 0.95, 0.93))
			box(r, Vector3(0.2, 0.012, 0.13), Vector3(0, 0.05, 0), Color(0.45, 0.55, 0.3))
			for i in 9:
				ball(r, 0.012, Vector3(-0.08 + (i % 5) * 0.04, 0.058, -0.04 + int(i / 5) * 0.07), Color(0.75, 0.5, 0.2), Vector3(1.5, 0.5, 1))
		"stuffing":
			cyl(r, 0.09, 0.05, Vector3(0, 0.025, 0), Color(0.85, 0.82, 0.75))
			for i in 10:
				var a := i * 2.4
				box(r, Vector3(0.025, 0.02, 0.025), Vector3(cos(a) * (0.02 + i * 0.006), 0.055, sin(a) * (0.02 + i * 0.006)), Color(0.65, 0.45, 0.22), Vector3(i * 17, i * 31, 0))
			ball(r, 0.07, Vector3(0, 0.045, 0), Color(0.6, 0.42, 0.22), Vector3(1.1, 0.3, 1.1))
		"cranberry":
			# The cranberry log: still the shape of the can, ridges and all.
			cyl(r, 0.08, 0.012, Vector3(0, 0.006, 0), Color(0.93, 0.93, 0.9))
			var cran := cyl(r, 0.035, 0.11, Vector3(0, 0.047, 0), Color(0.6, 0.04, 0.12), Vector3(0, 0, 90))
			(cran.material as StandardMaterial3D).roughness = 0.2
			for k in 4:
				ring(r, 0.033, 0.037, Vector3(-0.04 + k * 0.027, 0.047, 0), Color(0.5, 0.03, 0.1), Vector3(0, 0, 90))
		"corn":
			cyl(r, 0.07, 0.05, Vector3(0, 0.025, 0), Color(0.95, 0.95, 0.93))
			ball(r, 0.065, Vector3(0, 0.05, 0), Color(0.98, 0.82, 0.25), Vector3(1, 0.35, 1))
		"butter":
			box(r, Vector3(0.14, 0.012, 0.07), Vector3(0, 0.006, 0), Color(0.93, 0.93, 0.9))
			box(r, Vector3(0.1, 0.03, 0.04), Vector3(0, 0.027, 0), Color(0.98, 0.9, 0.55))
		"gravy":
			cyl(r, 0.07, 0.01, Vector3(0, 0.005, 0), Color(0.93, 0.93, 0.9))
			ball(r, 0.055, Vector3(0, 0.04, 0), Color(0.93, 0.93, 0.9), Vector3(1.5, 0.7, 0.9))
			cyl(r, 0.045, 0.006, Vector3(0, 0.065, 0), Color(0.5, 0.3, 0.12))
			cyl(r, 0.015, 0.05, Vector3(0.075, 0.06, 0), Color(0.93, 0.93, 0.9), Vector3(0, 0, -60))
	return r


## A full plate (food only; it sits on the scene's plates): turkey slices,
## potatoes with a gravy lake, green beans, a dab of cranberry, a roll.
## `kid` cuts everything up and keeps the foods from touching.
static func dinner_plate(kid := false) -> Node3D:
	var r := _root("Plate")
	var s := 0.8 if kid else 1.0
	for i in 2:
		box(r, Vector3(0.07, 0.008, 0.045) * s, Vector3(-0.03 + i * 0.012, 0.004 + i * 0.004, -0.035) * s, Color(0.93, 0.85, 0.72), Vector3(0, i * 15, 5))
	ball(r, 0.035 * s, Vector3(0.035, 0.012, -0.02) * s, Color(0.97, 0.95, 0.85), Vector3(1, 0.5, 1))
	cyl(r, 0.018 * s, 0.004, Vector3(0.035 * s, 0.026 * s, -0.02 * s), Color(0.5, 0.3, 0.12))
	for i in 5:
		box(r, Vector3(0.05, 0.007, 0.007) * s, Vector3(-0.02 + i * 0.006, 0.006, 0.04 + i * 0.008) * s, Color(0.3, 0.5, 0.2), Vector3(0, i * 20 - 30, 0))
	box(r, Vector3(0.025, 0.012, 0.025) * s, Vector3(0.055, 0.006, 0.04) * s, Color(0.6, 0.04, 0.12))
	if not kid:
		ball(r, 0.025, Vector3(-0.06, 0.015, 0.03), Color(0.85, 0.65, 0.35), Vector3(1.2, 0.8, 1))
	return r
