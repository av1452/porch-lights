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
