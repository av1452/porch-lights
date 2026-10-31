class_name GrandmasHouse
## Everything that makes Grandma's house Grandma's, built onto the
## Thanksgiving scene (scenes/chapter_2_thanksgiving.tscn):
## - the den through a doorway in the east wall: wood paneling, the console
##   TV with the game on, the plaid couch, Grandpa's empty recliner
## - the whole dinner on the big table, and the kids' table's version of it
## - her kitchen: the avocado fridge covered in grandkids' drawings, the
##   canisters, the cookie jar, the rooster, the wall phone, the clock
## - real photos on the walls, the needlepoint, the doilies
## Room space: x -4.1..4.1, z -3.1..3.1; the den is x 4.1..8.3, z -2.0..2.6.

const PANELING := Color(0.42, 0.28, 0.16)
const SHAG := Color(0.55, 0.38, 0.18)
const PLAID_A := Color(0.5, 0.22, 0.12)
const PLAID_B := Color(0.3, 0.35, 0.2)
const DEN_DOOR_Z := 0.0
## Where the den's TV is and which way it faces (-X, toward the couch).
const DEN_TV := Vector3(7.95, 0.0, 0.3)
const AVOCADO := Color(0.55, 0.58, 0.25)

## Built pieces the chapter swaps between dinner and evening.
var dinner: Node3D
var evening: Node3D
var den_tv: TvScreen
var den_light: OmniLight3D
var kitchen_clock: Node3D


func build(ch: Node3D) -> void:
	_den(ch)
	_kitchen(ch)
	_walls(ch)
	dinner = Node3D.new()
	dinner.name = "Dinner"
	ch.add_child(dinner)
	_big_table(dinner)
	_kids_table(dinner)
	evening = Node3D.new()
	evening.name = "Evening"
	ch.add_child(evening)
	_after_dinner(evening)
	Look.upgrade(ch.get_node("Den"))
	Look.upgrade(ch.get_node("GrandmasThings"))
	Look.upgrade(dinner)
	Look.upgrade(evening)


static func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, collide := false, rot := Vector3.ZERO) -> CSGBox3D:
	var b := Props.box(parent, size, pos, c, rot)
	b.use_collision = collide
	return b


static func _thing(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, prompt: String,
		first: String, again := "") -> Interactable:
	return HouseDetails._thing(parent, node_name, pos, size, prompt, first, again)


static func _put(parent: Node3D, prop: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	return HouseDetails._put(parent, prop, pos, yaw)


# --- The den ------------------------------------------------------------------

func _den(ch: Node3D) -> void:
	# A doorway through the east wall, across from the front door.
	var east := ch.get_node("House/Room/WallEast") as CSGBox3D
	east.visible = false
	east.use_collision = false
	var room := ch.get_node("House/Room") as Node3D
	var wall := Color(0.86, 0.78, 0.66)
	_box(room, Vector3(0.1, 2.6, 2.5), Vector3(4.05, 1.3, -1.85), wall, true)
	_box(room, Vector3(0.1, 2.6, 2.5), Vector3(4.05, 1.3, 1.85), wall, true)
	_box(room, Vector3(0.1, 0.5, 1.2), Vector3(4.05, 2.35, DEN_DOOR_Z), wall, true)
	for z in [-0.62, 0.62]:
		_box(room, Vector3(0.14, 2.1, 0.06), Vector3(4.05, 1.05, z), Color(0.55, 0.4, 0.25))
	_box(room, Vector3(0.14, 0.06, 1.3), Vector3(4.05, 2.1, DEN_DOOR_Z), Color(0.55, 0.4, 0.25))

	var den := Node3D.new()
	den.name = "Den"
	ch.add_child(den)
	_box(den, Vector3(4.2, 0.1, 4.6), Vector3(6.2, -0.05, 0.3), SHAG, true)
	_box(den, Vector3(4.2, 0.1, 4.6), Vector3(6.2, 2.45, 0.3), Color(0.9, 0.88, 0.82))
	# Wood paneling, with grooves.
	for w: Array in [[Vector3(4.2, 2.5, 0.1), Vector3(6.2, 1.25, -2.05)], [Vector3(4.2, 2.5, 0.1), Vector3(6.2, 1.25, 2.65)],
			[Vector3(0.1, 2.5, 4.8), Vector3(8.35, 1.25, 0.3)]]:
		_box(den, w[0], w[1], PANELING, true)
	for i in 14:
		_box(den, Vector3(0.012, 2.5, 0.012), Vector3(4.3 + i * 0.3, 1.25, -1.995), Color(0.3, 0.2, 0.11))
		_box(den, Vector3(0.012, 2.5, 0.012), Vector3(4.3 + i * 0.3, 1.25, 2.595), Color(0.3, 0.2, 0.11))
	for i in 15:
		_box(den, Vector3(0.012, 2.5, 0.012), Vector3(8.295, 1.25, -1.8 + i * 0.3), Color(0.3, 0.2, 0.11))
	# The den side of the doorway wall, paneled too.
	_box(den, Vector3(0.02, 2.5, 1.4), Vector3(4.11, 1.25, -1.3), PANELING)
	_box(den, Vector3(0.02, 2.5, 2.0), Vector3(4.11, 1.25, 1.6), PANELING)
	_box(den, Vector3(0.02, 0.4, 1.2), Vector3(4.11, 2.3, DEN_DOOR_Z), PANELING)
	# A window on the south wall, dark now, with heavy curtains.
	_box(den, Vector3(1.0, 0.8, 0.02), Vector3(6.2, 1.45, 2.59), Color(0.05, 0.06, 0.12))
	for x in [5.55, 6.85]:
		_box(den, Vector3(0.35, 1.5, 0.05), Vector3(x, 1.4, 2.56), Color(0.45, 0.35, 0.2))
	# The console TV: a big wooden cabinet with the picture tube in the middle.
	var tv := _put(den, Node3D.new(), DEN_TV, -90.0)
	tv.name = "ConsoleTV"
	_box(tv, Vector3(1.2, 0.75, 0.5), Vector3(0, 0.375, 0), Color(0.36, 0.22, 0.12), true)
	_box(tv, Vector3(1.22, 0.03, 0.52), Vector3(0, 0.76, 0), Color(0.3, 0.18, 0.1))
	_box(tv, Vector3(0.3, 0.55, 0.02), Vector3(0.42, 0.37, 0.25), Color(0.25, 0.18, 0.12))
	for k in 6:
		_box(tv, Vector3(0.28, 0.01, 0.022), Vector3(0.42, 0.15 + k * 0.08, 0.255), Color(0.15, 0.1, 0.06))
	var screen := MeshInstance3D.new()
	screen.name = "Screen"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.56, 0.42)
	screen.mesh = quad
	screen.position = Vector3(-0.15, 0.4, 0.253)
	tv.add_child(screen)
	_box(tv, Vector3(0.64, 0.5, 0.01), Vector3(-0.15, 0.4, 0.248), Color(0.08, 0.08, 0.08))
	den_tv = TvScreen.new()
	den_tv.screen_path = ^"../Screen"
	den_tv.channel = "off"
	tv.add_child(den_tv)
	# On top of the TV: the rabbit ears, a ceramic duck, a photo of Grandpa.
	for side in [-1, 1]:
		_box(tv, Vector3(0.01, 0.4, 0.01), Vector3(-0.15 + side * 0.08, 0.95, 0), Color(0.7, 0.7, 0.72), false, Vector3(0, 0, -side * 25))
	Props.ball(tv, 0.06, Vector3(0.35, 0.82, 0), Color(0.9, 0.88, 0.8), Vector3(1.4, 1, 1))
	Props.ball(tv, 0.035, Vector3(0.42, 0.88, 0), Color(0.3, 0.45, 0.3))
	_put(tv, Props.photo("grandpa", Vector2(0.18, 0.22), Color(0.72, 0.58, 0.3)), Vector3(-0.42, 0.775, -0.05), 0.0).rotation_degrees.x = -10.0
	_thing(den, "DenTV", DEN_TV + Vector3(0, 0.7, 0), Vector3(0.5, 0.6, 1.2), "Grandma's TV",
		"Grandma's TV is furniture. It has legs. You have to get up and turn a dial to change the channel.",
		"The picture's a little green. Uncle Ray says that's how you know it's a good TV.")
	# The plaid couch, facing the TV, and the coffee table with the nut bowl.
	var couch := _put(den, Node3D.new(), Vector3(5.0, 0.0, 0.3), 90.0)
	_couch(couch, 2.0)
	var table := _put(den, Node3D.new(), Vector3(6.25, 0.0, 0.3))
	_box(table, Vector3(0.55, 0.04, 1.0), Vector3(0, 0.4, 0), Color(0.4, 0.26, 0.14), true)
	for x in [-0.24, 0.24]:
		for z in [-0.45, 0.45]:
			_box(table, Vector3(0.04, 0.4, 0.04), Vector3(x, 0.2, z), Color(0.35, 0.22, 0.12))
	Props.cyl(table, 0.12, 0.06, Vector3(0, 0.45, -0.2), Color(0.75, 0.6, 0.35))
	for i in 9:
		Props.ball(table, 0.022, Vector3(cos(i) * 0.06, 0.48, -0.2 + sin(i) * 0.06), [Color(0.55, 0.35, 0.18), Color(0.7, 0.55, 0.35), Color(0.45, 0.3, 0.2)][i % 3])
	_box(table, Vector3(0.02, 0.01, 0.12), Vector3(0.1, 0.43, -0.05), Color(0.7, 0.7, 0.72), false, Vector3(0, 20, 0))
	_box(table, Vector3(0.21, 0.01, 0.28), Vector3(0.05, 0.425, 0.25), Color(0.85, 0.82, 0.7), false, Vector3(0, -10, 0))
	_thing(den, "NutBowl", Vector3(6.25, 0.5, 0.1), Vector3(0.3, 0.12, 0.3), "Nut bowl",
		"Mixed nuts, still in the shell, and the nutcracker shaped like a squirrel. Nobody has ever cracked a nut with it. Not once.")
	# Grandpa's recliner, in the corner, with Grandma's afghan folded on the arm.
	var recliner := _put(den, Node3D.new(), Vector3(5.2, 0.0, -1.45), 60.0)
	_box(recliner, Vector3(0.85, 0.42, 0.8), Vector3(0, 0.21, 0), Color(0.4, 0.3, 0.2), true)
	_box(recliner, Vector3(0.85, 0.75, 0.22), Vector3(0, 0.6, -0.32), Color(0.42, 0.32, 0.22), false, Vector3(-8, 0, 0))
	for x in [-0.36, 0.36]:
		_box(recliner, Vector3(0.14, 0.2, 0.78), Vector3(x, 0.5, 0), Color(0.38, 0.28, 0.18))
	_box(recliner, Vector3(0.3, 0.06, 0.5), Vector3(0.33, 0.62, 0.0), PLAID_A)
	for k in 3:
		_box(recliner, Vector3(0.302, 0.062, 0.03), Vector3(0.33, 0.62, -0.15 + k * 0.15), Color(0.92, 0.85, 0.5))
	_thing(den, "GrandpasChair", Vector3(5.2, 0.6, -1.45), Vector3(0.8, 0.9, 0.8), "Grandpa's chair",
		"Grandpa's chair. Nobody sits in it. Not even Uncle Ray, and Uncle Ray sits everywhere.",
		"It still has the dent where he sat. Grandma folds her afghan on the arm, like she's saving it for him.")
	# A loveseat along the south wall, a floor lamp, beanbags for the cousins.
	var love := _put(den, Node3D.new(), Vector3(6.3, 0.0, 1.95), 150.0)
	_couch(love, 1.4)
	var lamp := _put(den, Node3D.new(), Vector3(7.95, 0.0, 2.25))
	Props.cyl(lamp, 0.14, 0.03, Vector3(0, 0.015, 0), Color(0.6, 0.5, 0.3))
	Props.cyl(lamp, 0.015, 1.5, Vector3(0, 0.75, 0), Color(0.6, 0.5, 0.3))
	Props.cyl(lamp, 0.22, 0.28, Vector3(0, 1.55, 0), Color(0.95, 0.88, 0.7), Vector3.ZERO, true).rotation_degrees.x = 180.0
	for at in [Vector3(6.9, 0.0, -0.95), Vector3(7.3, 0.0, 1.35)]:
		Props.ball(den, 0.38, at + Vector3(0, 0.22, 0), Color(0.75, 0.3, 0.45) if at.z < 0 else Color(0.25, 0.45, 0.7), Vector3(1, 0.6, 1))
	# Needlepoint over the couch, and a cuckoo clock that doesn't cuckoo anymore.
	var stitch := _put(den, Node3D.new(), Vector3(4.17, 1.35, 1.6), 90.0)
	_box(stitch, Vector3(0.7, 0.42, 0.03), Vector3(0, 0.21, 0.015), Color(0.55, 0.38, 0.2))
	_box(stitch, Vector3(0.62, 0.34, 0.005), Vector3(0, 0.21, 0.032), Color(0.95, 0.92, 0.82))
	Props.label(stitch, "HOME SWEET HOME", Vector3(0, 0.25, 0.036), 0.05, Color(0.7, 0.15, 0.15), Vector3.ZERO)
	for i in 5:
		Props.ball(stitch, 0.015, Vector3(-0.2 + i * 0.1, 0.13, 0.036), [Color(0.85, 0.3, 0.4), Color(0.3, 0.6, 0.3)][i % 2], Vector3(1, 1, 0.3))
	_thing(den, "Needlepoint", Vector3(4.2, 1.56, 1.6), Vector3(0.08, 0.45, 0.72), "Needlepoint",
		"HOME SWEET HOME, in red thread. Grandma made it the year your mom was born. One of the flowers is a little crooked. That's how you know she made it.")
	den_light = OmniLight3D.new()
	den_light.light_color = Color(1, 0.85, 0.6)
	den_light.light_energy = 0.3
	den_light.omni_range = 6.0
	den_light.position = Vector3(6.6, 2.1, 0.6)
	den.add_child(den_light)


## A plaid couch, `width` wide, facing +Z.
static func _couch(at: Node3D, width: float) -> void:
	_box(at, Vector3(width, 0.42, 0.8), Vector3(0, 0.21, 0), PLAID_A, true)
	_box(at, Vector3(width, 0.5, 0.2), Vector3(0, 0.62, -0.32), PLAID_A, true)
	for x in [-width / 2.0 + 0.08, width / 2.0 - 0.08]:
		_box(at, Vector3(0.18, 0.25, 0.8), Vector3(x, 0.52, 0), PLAID_A)
	for k in int(width / 0.25):
		_box(at, Vector3(0.04, 0.43, 0.81), Vector3(-width / 2.0 + 0.12 + k * 0.25, 0.21, 0), PLAID_B)
	for k in 2:
		_box(at, Vector3(width + 0.01, 0.04, 0.81), Vector3(0, 0.12 + k * 0.2, 0), PLAID_B)
	_box(at, Vector3(width * 0.4, 0.06, 0.5), Vector3(-width * 0.2, 0.45, 0.05), Color(0.85, 0.75, 0.55), false, Vector3(0, 5, 0))


# --- Grandma's kitchen ------------------------------------------------------------

func _kitchen(ch: Node3D) -> void:
	var things := Node3D.new()
	things.name = "GrandmasThings"
	ch.add_child(things)
	# The avocado-green fridge at the end of the counter, covered in drawings.
	var fridge := _put(things, Node3D.new(), Vector3(-0.2, 0.0, -2.62))
	_box(fridge, Vector3(0.72, 1.7, 0.7), Vector3(0, 0.85, 0), AVOCADO, true)
	_box(fridge, Vector3(0.73, 0.012, 0.71), Vector3(0, 1.2, 0), Color(0.35, 0.37, 0.15))
	_box(fridge, Vector3(0.03, 0.35, 0.04), Vector3(0.3, 1.45, 0.37), Color(0.8, 0.8, 0.78))
	_box(fridge, Vector3(0.03, 0.5, 0.04), Vector3(0.3, 0.8, 0.37), Color(0.8, 0.8, 0.78))
	var papers := [Color(0.95, 0.95, 0.9), Color(0.95, 0.9, 0.6), Color(0.85, 0.92, 0.95), Color(0.95, 0.85, 0.85)]
	for i in 6:
		var p := _box(fridge, Vector3(0.18, 0.22, 0.004), Vector3(-0.2 + (i % 3) * 0.17, 0.75 + int(i / 3) * 0.5, 0.352), papers[i % 4], false, Vector3(0, 0, (i % 3 - 1) * 7.0))
		Props.ball(p, 0.04, Vector3(0, 0.02, 0.003), Color.from_hsv(fmod(i * 0.29, 1.0), 0.7, 0.85), Vector3(1, 1, 0.1))
		Props.ball(fridge, 0.012, Vector3(-0.2 + (i % 3) * 0.17, 0.85 + int(i / 3) * 0.5, 0.36), Color.from_hsv(fmod(i * 0.41, 1.0), 0.6, 0.9))
	_thing(things, "GrandmasFridge", Vector3(-0.2, 1.0, -2.25), Vector3(0.7, 1.0, 0.06), "Grandma's fridge",
		"Every drawing any grandkid has ever made is on this fridge. There's one from your mom. It's a horse. Probably.",
		"You find yours from last year: the family as stick people, and Biscuit as a very long brown oval. She kept it.")
	# Canisters, the cookie jar, the rooster, the bread box, the recipe box.
	var labels := ["FLOUR", "SUGAR", "COFFEE", "TEA"]
	for i in 4:
		var c := Props.cyl(things, 0.08 - i * 0.012, 0.24 - i * 0.03, Vector3(0.45 + i * 0.19, 1.06 - i * 0.015, -2.9), Color(0.92, 0.9, 0.82))
		Props.cyl(c, 0.08 - i * 0.012 + 0.005, 0.02, Vector3(0, 0.12 - i * 0.015, 0), Color(0.6, 0.35, 0.15))
		Props.label(c, labels[i], Vector3(0, 0.02, 0.081 - i * 0.012), 0.022, Color(0.55, 0.3, 0.12), Vector3.ZERO)
	var jar := _put(things, Node3D.new(), Vector3(3.55, 0.94, -2.8))
	Props.ball(jar, 0.12, Vector3(0, 0.12, 0), Color(0.85, 0.75, 0.55))
	Props.ball(jar, 0.07, Vector3(0, 0.25, 0), Color(0.85, 0.75, 0.55))
	for side in [-1, 1]:
		Props.ball(jar, 0.035, Vector3(side * 0.05, 0.31, 0), Color(0.75, 0.62, 0.42))
	Props.ball(jar, 0.03, Vector3(0, 0.24, 0.07), Color(0.3, 0.2, 0.12))
	_thing(things, "CookieJar", Vector3(3.55, 1.1, -2.8), Vector3(0.26, 0.36, 0.26), "Cookie jar",
		"The bear cookie jar. The lid clinks when you lift it, so Grandma always knows. Today: snickerdoodles.",
		"Clink. 'One!' says Grandma, from wherever she is. She always knows.")
	var rooster := _put(things, Node3D.new(), Vector3(-0.25, 1.7, -2.7), 30.0)
	Props.ball(rooster, 0.06, Vector3(0, 0.06, 0), Color(0.95, 0.93, 0.85), Vector3(1.3, 1, 0.8))
	Props.ball(rooster, 0.035, Vector3(0.06, 0.13, 0), Color(0.95, 0.93, 0.85))
	Props.ball(rooster, 0.02, Vector3(0.06, 0.17, 0), Color(0.85, 0.15, 0.1))
	for k in 3:
		Props.box(rooster, Vector3(0.02, 0.1, 0.06), Vector3(-0.07 - k * 0.01, 0.12 + k * 0.02, 0), [Color(0.2, 0.4, 0.3), Color(0.85, 0.5, 0.1), Color(0.6, 0.15, 0.1)][k], Vector3(0, 0, 25 + k * 15))
	# The wall phone, rotary, with a cord long enough to reach the dining room.
	_put(things, Props.wall_phone(Color(0.55, 0.58, 0.25)), Vector3(-0.7, 1.2, -3.0))
	_thing(things, "RotaryPhone", Vector3(-0.7, 1.3, -2.97), Vector3(0.15, 0.25, 0.1), "Grandma's phone",
		"A phone with a dial. You put your finger in the hole and turn it all the way around. It takes forever. You love it.",
		"The cord is so long Grandma can talk on it from the bathroom. She has.")
	# The clock over the doorway to the den, and a fall wreath on the front door.
	kitchen_clock = _put(things, Node3D.new(), Vector3(3.98, 2.33, 0.0), -90.0)
	Props.cyl(kitchen_clock, 0.17, 0.04, Vector3(0, 0, 0), Color(0.85, 0.6, 0.2), Vector3(90, 0, 0))
	Props.cyl(kitchen_clock, 0.15, 0.045, Vector3(0, 0, 0), Color(0.97, 0.95, 0.88), Vector3(90, 0, 0))
	for i in 12:
		var a := i * TAU / 12.0
		Props.box(kitchen_clock, Vector3(0.008, 0.02, 0.004), Vector3(sin(a), cos(a), 0) * 0.125 + Vector3(0, 0, 0.024), Color(0.2, 0.2, 0.2), Vector3(0, 0, -rad_to_deg(a)))
	Props.box(kitchen_clock, Vector3(0.012, 0.07, 0.004), Vector3.ZERO, Color(0.1, 0.1, 0.1)).name = "Hour"
	Props.box(kitchen_clock, Vector3(0.008, 0.11, 0.004), Vector3.ZERO, Color(0.1, 0.1, 0.1)).name = "Minute"
	set_clock(12, 40)
	var wreath := _put(things, Node3D.new(), Vector3(-3.96, 1.45, 0.0), 90.0)
	Props.ring(wreath, 0.13, 0.22, Vector3.ZERO, Color(0.75, 0.4, 0.12), Vector3(90, 0, 0))
	for i in 10:
		var a := i * TAU / 10.0
		Props.ball(wreath, 0.035, Vector3(cos(a) * 0.18, sin(a) * 0.18, 0.03), [Color(0.85, 0.3, 0.08), Color(0.9, 0.7, 0.15), Color(0.55, 0.2, 0.08)][i % 3], Vector3(1.4, 0.8, 0.5))


## Turns the kitchen clock's hands.
func set_clock(hour: int, minute: int) -> void:
	var hands := [["Hour", ((hour % 12) + minute / 60.0) / 12.0, 0.07], ["Minute", minute / 60.0, 0.11]]
	for h: Array in hands:
		var hand := kitchen_clock.get_node(h[0]) as Node3D
		var a: float = h[1] * TAU
		hand.rotation = Vector3(0, 0, -a)
		hand.position = Vector3(sin(a), cos(a), 0) * h[2] * 0.4 + Vector3(0, 0, 0.026 if h[0] == "Minute" else 0.025)


# --- Walls: real photos and the doilies ---------------------------------------------

func _walls(ch: Node3D) -> void:
	var things := ch.get_node("GrandmasThings") as Node3D
	# The plain frames on the south wall become real pictures.
	for i in 3:
		(ch.get_node("House/Furniture/Frame%d" % i) as Node3D).visible = false
		(ch.get_node("House/Furniture/Photo%d" % i) as Node3D).visible = false
	_put(things, Props.photo("wedding", Vector2(0.3, 0.38), Color(0.72, 0.58, 0.3)), Vector3(1.4, 1.41, 2.99), 180.0)
	_put(things, Props.photo("family", Vector2(0.38, 0.3), Color(0.4, 0.26, 0.14)), Vector3(1.9, 1.45, 2.99), 180.0)
	_put(things, Props.photo("school", Vector2(0.24, 0.3), Color(0.75, 0.75, 0.78)), Vector3(2.4, 1.43, 2.99), 180.0)
	# Over the big table: Grandpa by his car, and the lake.
	_put(things, Props.photo("grandpa", Vector2(0.3, 0.38), Color(0.3, 0.2, 0.12)), Vector3(-2.0, 1.35, -2.99))
	_put(things, Props.photo("lake", Vector2(0.45, 0.32), Color(0.72, 0.58, 0.3)), Vector3(-1.2, 1.38, -2.99))
	_thing(things, "OldPhotos", Vector3(-1.6, 1.55, -2.96), Vector3(1.2, 0.5, 0.06), "Old pictures",
		"Grandpa, way before you were born, leaning on a car like he owns it. He did own it. It was green.",
		"The lake by the cabin. Grandma says you went once, when you were one. You'd like to remember it.")
	# Doilies under the mint dish and on the china cabinet.
	for at in [Vector3(-3.7, 0.652, 1.7), Vector3(-3.8, 1.81, -2.2)]:
		Props.cyl(things, 0.17, 0.004, at, Color(0.97, 0.96, 0.92))
		for i in 12:
			var a := i * TAU / 12.0
			Props.ball(things, 0.022, at + Vector3(cos(a) * 0.17, 0.0, sin(a) * 0.17), Color(0.97, 0.96, 0.92), Vector3(1, 0.15, 1))
	# Leaves along the top of the window, and a GIVE THANKS sign.
	for i in 14:
		Props.ball(things, 0.05, Vector3(-2.15 + i * 0.05 * 1.0 + i * 0.0, 2.08 - absf(i - 6.5) * 0.008, 2.95), [Color(0.85, 0.3, 0.08), Color(0.9, 0.65, 0.12), Color(0.6, 0.18, 0.08)][i % 3], Vector3(1.3, 0.8, 0.3))
	for i in 14:
		Props.ball(things, 0.05, Vector3(-1.45 + i * 0.05, 2.08 - absf(i - 6.5) * 0.008, 2.95), [Color(0.9, 0.65, 0.12), Color(0.6, 0.18, 0.08), Color(0.85, 0.3, 0.08)][i % 3], Vector3(1.3, 0.8, 0.3))
	var sign := _put(things, Node3D.new(), Vector3(0.6, 1.75, 2.995), 180.0)
	_box(sign, Vector3(0.6, 0.18, 0.02), Vector3(0, 0.09, 0.01), Color(0.55, 0.38, 0.2))
	Props.label(sign, "GIVE THANKS", Vector3(0, 0.09, 0.022), 0.07, Color(0.97, 0.92, 0.8), Vector3.ZERO)


# --- Dinner -----------------------------------------------------------------------

## The big table: the turkey, carved, and everything else, and a full plate
## at every seat.
func _big_table(parent: Node3D) -> void:
	var top := 0.785
	# The turkey on its platter in the middle, the gravy boat next to it.
	_put(parent, Props.roast_turkey(), Vector3(-1.55, top, -1.0), 90.0)
	_put(parent, Props.dish("gravy"), Vector3(-1.2, top, -1.0))
	# Around it, every dish, in the gaps between the plates.
	_put(parent, Props.dish("potatoes"), Vector3(-1.9, top, -1.27))
	_put(parent, Props.dish("beans"), Vector3(-1.1, top, -1.27), 10.0)
	_put(parent, Props.dish("stuffing"), Vector3(-1.1, top, -0.73), -15.0)
	_put(parent, Props.dish("cranberry"), Vector3(-1.9, top, -0.73))
	_put(parent, Props.dish("corn"), Vector3(-2.42, top, -1.0))
	_put(parent, Props.dish("butter"), Vector3(-2.55, top, -0.72))
	# A cornucopia, and the pilgrim salt and pepper shakers.
	var horn := _put(parent, Node3D.new(), Vector3(-0.6, top, -1.05), 30.0)
	for k in 4:
		Props.cyl(horn, 0.07 - k * 0.015, 0.08, Vector3(0, 0.07 - k * 0.012, -k * 0.07), Color(0.7, 0.52, 0.28), Vector3(90 - k * 12, 0, 0))
	for i in 5:
		Props.ball(horn, 0.03, Vector3(-0.04 + i * 0.025, 0.04, 0.06 + (i % 2) * 0.03), [Color(0.85, 0.2, 0.15), Color(0.9, 0.7, 0.15), Color(0.5, 0.2, 0.45), Color(0.9, 0.5, 0.1), Color(0.4, 0.6, 0.2)][i])
	for side in [-1, 1]:
		var shaker := _put(parent, Node3D.new(), Vector3(-0.42 + side * 0.04, top, -0.68))
		Props.cyl(shaker, 0.02, 0.06, Vector3(0, 0.03, 0), Color(0.12, 0.12, 0.14))
		Props.ball(shaker, 0.018, Vector3(0, 0.075, 0), Color(0.95, 0.85, 0.75))
		Props.cyl(shaker, 0.025, 0.012, Vector3(0, 0.1, 0), Color(0.12, 0.12, 0.14))
	# A plate of food at every seat.
	for at in [Vector3(-2.3, top, -1.3), Vector3(-1.5, top, -1.3), Vector3(-0.7, top, -1.3),
			Vector3(-2.3, top, -0.7), Vector3(-1.5, top, -0.7), Vector3(-0.7, top, -0.7)]:
		_put(parent, Props.dinner_plate(), at + Vector3(0, 0.012, 0), randf_range(0, 360))
		Props.cyl(parent, 0.03, 0.1, at + Vector3(0.17, 0.05, -0.05 if at.z < -1.0 else 0.05), Color(0.85, 0.9, 0.95))


## The kids' table: the same dinner, cut up smaller, juice instead of
## grown-up drinks, a sippy cup for Ben, the paper turkeys and crayons.
func _kids_table(parent: Node3D) -> void:
	var top := 0.705
	for at in [Vector3(-1.5, top, 1.47), Vector3(-1.93, top, 1.9), Vector3(-1.07, top, 1.9), Vector3(-1.5, top, 2.33)]:
		_put(parent, Props.dinner_plate(true), at + Vector3(0, 0.012, 0), randf_range(0, 360))
	for at in [Vector3(-1.7, top, 1.55), Vector3(-1.95, top, 2.1), Vector3(-1.05, top, 1.7)]:
		Props.cyl(parent, 0.03, 0.09, at + Vector3(0, 0.045, 0), Color(0.95, 0.6, 0.15))
		Props.cyl(parent, 0.028, 0.004, at + Vector3(0, 0.08, 0), Color(0.95, 0.75, 0.3))
	var sippy := _put(parent, Node3D.new(), Vector3(-1.3, top, 2.4))
	Props.cyl(sippy, 0.035, 0.1, Vector3(0, 0.05, 0), Color(0.4, 0.75, 0.95))
	Props.cyl(sippy, 0.036, 0.03, Vector3(0, 0.11, 0), Color(0.95, 0.4, 0.5))
	Props.box(sippy, Vector3(0.02, 0.03, 0.02), Vector3(0, 0.135, 0.015), Color(0.95, 0.4, 0.5))
	for k in 5:
		Props.cyl(parent, 0.005, 0.09, Vector3(-1.25 + k * 0.015, top + 0.006, 2.05), Color.from_hsv(k / 5.0, 0.8, 0.9), Vector3(90, 0, 15))
	# The kids get the cranberry log too. It's still in the shape of the can.
	_put(parent, Props.dish("cranberry"), Vector3(-1.5, top, 1.9))


## After dinner: the dishes in the sink, the leftovers lined up on the
## counter, and the pies (one with a slice gone).
func _after_dinner(parent: Node3D) -> void:
	for k in 5:
		Props.cyl(parent, 0.12, 0.012, Vector3(2.1 + randf_range(-0.03, 0.03), 0.95 + k * 0.014, -2.75), Color(0.95, 0.95, 0.92))
	for i in 3:
		var tub := _put(parent, Node3D.new(), Vector3(2.75 + i * 0.25, 0.94, -2.6))
		Props.box(tub, Vector3(0.18, 0.08, 0.14), Vector3(0, 0.04, 0), [Color(0.9, 0.9, 0.85), Color(0.95, 0.85, 0.75), Color(0.85, 0.85, 0.9)][i])
		Props.box(tub, Vector3(0.185, 0.015, 0.145), Vector3(0, 0.085, 0), [Color(0.2, 0.5, 0.9), Color(0.9, 0.3, 0.3), Color(0.3, 0.7, 0.4)][i])
	var pie := _put(parent, Node3D.new(), Vector3(-1.5, 0.785, -1.0))
	Props.cyl(pie, 0.15, 0.035, Vector3(0, 0.018, 0), Color(0.85, 0.55, 0.25))
	Props.cyl(pie, 0.14, 0.004, Vector3(0, 0.037, 0), Color(0.82, 0.45, 0.12))
	Props.box(pie, Vector3(0.09, 0.04, 0.09), Vector3(0.07, 0.02, 0.07), Color(0.9, 0.88, 0.85), Vector3(0, 45, 0))
	Props.cyl(parent, 0.07, 0.06, Vector3(-1.25, 0.815, -0.85), Color(0.97, 0.97, 0.97))
	Props.cyl(parent, 0.072, 0.012, Vector3(-1.25, 0.85, -0.85), Color(0.2, 0.4, 0.85))
