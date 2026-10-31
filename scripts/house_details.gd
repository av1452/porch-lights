class_name HouseDetails
## The lived-in layer of the family house, for every chapter set there:
## family photos in every room, the kitchen's toaster and answering machine,
## the hallway's school pictures, Jamie's guitar and burned CDs, Leo's desk
## and his virtual pet, and the front porch dressed for the season.
## Positions are in the house scene's space (scenes/chapter_1_halloween.tscn).

const DARK_WOOD := Color(0.3, 0.2, 0.12)
const WOOD := Color(0.5, 0.36, 0.22)
const GOLD := Color(0.72, 0.58, 0.3)


## `season`: "halloween", "fall" or "christmas".
static func dress(house: Node3D, season: String) -> void:
	var root := Node3D.new()
	root.name = "HouseDetails"
	house.add_child(root)
	_living_room(house, root, season)
	_kitchen(house, root, season)
	_hallway(root)
	_jamie_room(house.get_node("House/JamieRoom/JamieRoomFull") as Node3D)
	_leo_room(house, root)
	_porch(house, root, season)
	Look.upgrade(root)
	Look.upgrade(house.get_node("House/JamieRoom/JamieRoomFull"))


## Something you can look at: an invisible box with a prompt and a thought.
static func _thing(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, prompt: String,
		first: String, again := "") -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt
	it.memory_text = first
	it.repeat_text = again
	it.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	it.add_child(shape)
	parent.add_child(it)
	return it


## A prop placed in the house: position, and which way it faces (degrees).
static func _put(parent: Node3D, prop: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	prop.position = pos
	prop.rotation_degrees.y = yaw
	parent.add_child(prop)
	return prop


# --- Living room -------------------------------------------------------------

static func _living_room(house: Node3D, root: Node3D, season: String) -> void:
	# Over the couch: the family on the porch, the beach trip, Leo's baby picture.
	_put(root, Props.photo("family", Vector2(0.42, 0.32)), Vector3(0.0, 1.45, 2.49), 180.0)
	_put(root, Props.photo("beach", Vector2(0.26, 0.2), Color(0.85, 0.82, 0.75)), Vector3(-0.52, 1.55, 2.49), 180.0)
	_put(root, Props.photo("baby", Vector2(0.2, 0.25), GOLD), Vector3(0.5, 1.5, 2.49), 180.0)
	_thing(root, "CouchPhotos", Vector3(0.0, 1.6, 2.45), Vector3(1.3, 0.45, 0.08), "Family photos",
		"The whole family on the porch, everybody squinting. Biscuit is a blur. Biscuit is always a blur.",
		"The beach one is from before you can remember. Jamie's holding you like a sack of potatoes.")
	# By the lamp, the lake picture Dad took and is very proud of.
	_put(root, Props.photo("lake", Vector2(0.4, 0.3), DARK_WOOD), Vector3(2.99, 1.35, 1.25), -90.0)
	# The VCR's clock has been blinking 12:00 since the power went out in August.
	var vcr_clock := Props.label(root, "12:00", Vector3(-0.38, 0.33, -1.92), 0.03, Color(0.3, 1.0, 0.5), Vector3.ZERO)
	_blink(vcr_clock)
	_thing(root, "VCRClock", Vector3(-0.5, 0.32, -1.93), Vector3(0.45, 0.09, 0.04), "VCR",
		"12:00. 12:00. 12:00. It's been blinking since the power went out in August. Nobody knows how to fix it.",
		"Dad says he'll read the manual. The manual is somewhere. The VCR keeps blinking.")
	if season == "christmas":
		# Christmas cards taped around the kitchen doorway.
		var colors := [Color(0.8, 0.15, 0.15), Color(0.2, 0.45, 0.25), Color(0.95, 0.95, 0.9), Color(0.25, 0.35, 0.7), Color(0.85, 0.7, 0.3)]
		for i in 9:
			var y := 0.9 + i * 0.15
			var side := -1.0 if i % 2 == 0 else 1.0
			Props.box(root, Vector3(0.008, 0.12, 0.09), Vector3(3.0 - 0.005, y, side * 0.67), colors[i % colors.size()], Vector3(0, 0, (i % 3 - 1) * 6.0))
		_thing(root, "Cards", Vector3(2.98, 1.5, 0.67), Vector3(0.05, 1.3, 0.12), "Christmas cards",
			"Christmas cards from people you've never met. One has a photo of a family in matching sweaters. You feel bad for them.",
			"Aunt Lisa's card has glitter. The glitter is everywhere now. It'll be there in July.")


static func _blink(label: Label3D) -> void:
	while is_instance_valid(label) and label.is_inside_tree():
		label.visible = not label.visible
		await label.get_tree().create_timer(0.6).timeout


# --- Kitchen -----------------------------------------------------------------

static func _kitchen(house: Node3D, root: Node3D, season: String) -> void:
	# Cereal boxes on top of the fridge, where you can't reach them.
	var cereal := [[Color(0.9, 0.75, 0.15), "O's"], [Color(0.85, 0.2, 0.2), "FLAKES"], [Color(0.3, 0.55, 0.85), "PUFFS"]]
	for i in cereal.size():
		var b := Props.box(root, Vector3(0.07, 0.3, 0.2), Vector3(6.75 - i * 0.12, 1.95, -2.05 + i * 0.07), cereal[i][0], Vector3(0, i * 8 - 8, 0))
		Props.label(b, cereal[i][1], Vector3(-0.036, 0.05, 0), 0.03, Color(1, 1, 0.95), Vector3(0, -90, 0))
	# The toaster, coffee maker and paper towels on the counter.
	var toaster := _put(root, Node3D.new(), Vector3(6.82, 0.94, 1.7), -90.0)
	Props.box(toaster, Vector3(0.26, 0.17, 0.15), Vector3(0, 0.085, 0), Color(0.75, 0.76, 0.78))
	for x in [-0.05, 0.05]:
		Props.box(toaster, Vector3(0.03, 0.01, 0.11), Vector3(x, 0.171, 0), Color(0.1, 0.1, 0.1))
	Props.box(toaster, Vector3(0.02, 0.02, 0.03), Vector3(0.14, 0.12, 0), Color(0.1, 0.1, 0.1))
	var coffee := _put(root, Node3D.new(), Vector3(6.84, 0.94, -0.1), -90.0)
	Props.box(coffee, Vector3(0.18, 0.32, 0.2), Vector3(0, 0.16, -0.02), Color(0.12, 0.12, 0.13))
	Props.cyl(coffee, 0.07, 0.13, Vector3(0, 0.075, 0.03), Color(0.3, 0.2, 0.12)).material = Decorations.mat(Color(0.25, 0.15, 0.08))
	Props.box(coffee, Vector3(0.02, 0.012, 0.004), Vector3(0.06, 0.28, 0.081), Color(1, 0.2, 0.1), Vector3.ZERO, 2.0)
	Props.cyl(root, 0.06, 0.26, Vector3(6.88, 1.07, 1.4), Color(0.97, 0.97, 0.95))
	Props.cyl(root, 0.01, 0.3, Vector3(6.88, 1.09, 1.4), Color(0.5, 0.35, 0.2))
	# A dish towel on the oven door and a mat by the sink.
	Props.box(root, Vector3(0.01, 0.3, 0.18), Vector3(6.37, 0.72, -0.6), Color(0.85, 0.85, 0.9))
	for i in 4:
		Props.box(root, Vector3(0.012, 0.02, 0.182), Vector3(6.37, 0.62 + i * 0.06, -0.6), Color(0.3, 0.45, 0.75))
	Props.box(root, Vector3(0.5, 0.01, 0.8), Vector3(6.15, 0.005, 1.0), Color(0.4, 0.5, 0.35))
	# Cafe curtains over the sink window.
	Props.box(root, Vector3(0.02, 0.18, 1.05), Vector3(6.95, 1.95, 1.0), Color(0.95, 0.9, 0.75))
	for z in [0.62, 1.38]:
		Props.box(root, Vector3(0.015, 0.4, 0.28), Vector3(6.94, 1.62, z), Color(0.95, 0.9, 0.75))
	# Salt and pepper and the napkin holder on the end of the table.
	var shaker := [Color(0.95, 0.95, 0.95), Color(0.2, 0.2, 0.2)]
	for i in 2:
		Props.cyl(root, 0.018, 0.07, Vector3(5.05 + i * 0.05, 0.79, 0.0), Color(0.85, 0.87, 0.9))
		Props.cyl(root, 0.019, 0.015, Vector3(5.05 + i * 0.05, 0.83, 0.0), shaker[i])
	Props.box(root, Vector3(0.12, 0.08, 0.06), Vector3(4.15, 0.795, 0.05), Color(0.7, 0.55, 0.35))
	Props.box(root, Vector3(0.1, 0.07, 0.04), Vector3(4.15, 0.8, 0.05), Color(0.97, 0.97, 0.95))
	# The phone table in the corner: answering machine, phone book, the mail,
	# and this week's free internet CD.
	var table := _put(root, Node3D.new(), Vector3(3.5, 0.0, 2.25))
	Props.box(table, Vector3(0.5, 0.03, 0.36), Vector3(0, 0.72, 0), WOOD)
	for x in [-0.22, 0.22]:
		for z in [-0.15, 0.15]:
			Props.box(table, Vector3(0.03, 0.72, 0.03), Vector3(x, 0.36, z), WOOD)
	Props.box(table, Vector3(0.46, 0.02, 0.32), Vector3(0, 0.25, 0), WOOD)
	Props.box(table, Vector3(0.22, 0.05, 0.28), Vector3(-0.1, 0.285, 0), Color(0.95, 0.85, 0.2))
	_put(table, Props.phone_and_machine(1), Vector3(-0.08, 0.735, 0.0), 180.0)
	_put(table, Props.trial_cd(), Vector3(0.16, 0.735, -0.04), 160.0)
	for i in 3:
		Props.box(table, Vector3(0.16, 0.004, 0.1), Vector3(0.15, 0.74 + i * 0.005, 0.08), [Color(0.95, 0.95, 0.92), Color(0.85, 0.8, 0.65), Color(0.9, 0.9, 0.95)][i], Vector3(0, i * 12 - 10, 0))
	var message := {
		"halloween": "1 new message. It's Grandma: 'Did the kids get a lot of candy? Save me a Mounds. Nobody else likes them.'",
		"fall": "1 new message. It's Grandma, at 6 a.m.: 'Don't forget the folding chairs. And drive safe. And don't forget the chairs.'",
		"christmas": "1 new message. It's Grandma: 'I'm bringing the fudge. Don't tell your father how much. Love you, bye. Is this thing on?'",
	}
	_thing(root, "AnsweringMachine", Vector3(3.45, 0.79, 2.25), Vector3(0.3, 0.12, 0.2), "Answering machine",
		message.get(season, message.christmas),
		"The tape squeaks when it rewinds. Mom says don't press anything. You don't press anything.")
	_thing(root, "TrialCD", Vector3(3.68, 0.75, 2.2), Vector3(0.16, 0.05, 0.16), "Free internet CD",
		"FREE INTERNET! 500 HOURS! A new one comes in the mail every week. Dad uses them as coasters.",
		"Jamie says 500 hours isn't even that much. Jamie would know.")


# --- Hallway -----------------------------------------------------------------

static func _hallway(root: Node3D) -> void:
	# West wall, between Jamie's door and Mom and Dad's: the wedding, the baby, Halloween.
	_put(root, Props.photo("wedding", Vector2(0.24, 0.3), GOLD), Vector3(1.51, 1.45, -5.35), 90.0)
	_put(root, Props.photo("halloween", Vector2(0.26, 0.2)), Vector3(1.51, 1.62, -5.95), 90.0)
	_put(root, Props.photo("grandpa", Vector2(0.22, 0.28), DARK_WOOD), Vector3(1.51, 1.4, -6.5), 90.0)
	_thing(root, "HallPhotos", Vector3(1.53, 1.6, -5.95), Vector3(0.06, 0.6, 1.5), "Pictures",
		"Mom and Dad's wedding. Dad has so much hair. Mom says, 'Don't.'",
		"Grandpa, before anybody you know was born, leaning on a car like he owns it. He did own it.")
	# East wall: school pictures, one per year, and the dog.
	_put(root, Props.photo("school", Vector2(0.2, 0.25), Color(0.75, 0.75, 0.78)), Vector3(2.49, 1.5, -4.4), -90.0)
	_put(root, Props.photo("dog", Vector2(0.26, 0.2), WOOD), Vector3(2.49, 1.55, -5.05), -90.0)
	# The smoke detector, blinking its little green light.
	Props.cyl(root, 0.07, 0.03, Vector3(2.0, 2.585, -5.0), Color(0.95, 0.95, 0.93))
	Props.ball(root, 0.006, Vector3(2.03, 2.57, -5.0), Color(0.2, 1, 0.3)).material = Decorations.mat(Color(0.2, 1, 0.3), 3.0)


# --- Jamie's room --------------------------------------------------------------

static func _jamie_room(room: Node3D) -> void:
	# The guitar, leaning against the wall at the foot of the bed.
	var guitar := _put(room, Node3D.new(), Vector3(0.25, 0.0, -2.72))
	guitar.rotation_degrees = Vector3(12, 10, 0)
	Props.ball(guitar, 0.17, Vector3(0, 0.2, 0), Color(0.75, 0.3, 0.1), Vector3(1, 1, 0.3))
	Props.ball(guitar, 0.13, Vector3(0, 0.42, 0), Color(0.75, 0.3, 0.1), Vector3(1, 1, 0.3))
	Props.cyl(guitar, 0.045, 0.01, Vector3(0, 0.33, 0.05), Color(0.1, 0.08, 0.06), Vector3(90, 0, 0))
	Props.box(guitar, Vector3(0.05, 0.45, 0.025), Vector3(0, 0.75, 0.0), Color(0.3, 0.2, 0.1))
	Props.box(guitar, Vector3(0.07, 0.12, 0.03), Vector3(0, 1.02, 0.0), Color(0.15, 0.1, 0.06))
	_thing(room, "Guitar", Vector3(0.25, 0.5, -2.75), Vector3(0.36, 1.0, 0.2), "Jamie's guitar",
		"Jamie's guitar. He knows four chords. He says that's all you need for punk.",
		"There's a sticker on it that says STATIC PARADE, and a smaller one under it that says JAMIE'S. DON'T.")
	# His skateboard under the desk, his sneakers, his backpack with the pins.
	var deck := _put(room, Node3D.new(), Vector3(0.6, 0.05, -5.15), 30.0)
	Props.box(deck, Vector3(0.2, 0.015, 0.78), Vector3.ZERO, Color(0.12, 0.12, 0.14), Vector3(0, 0, 0))
	for z in [-0.26, 0.26]:
		for x in [-0.07, 0.07]:
			Props.cyl(deck, 0.028, 0.03, Vector3(x, -0.025, z), Color(0.95, 0.9, 0.6), Vector3(0, 0, 90))
	for i in 2:
		Props.box(room, Vector3(0.1, 0.09, 0.28), Vector3(0.95 + i * 0.13, 0.045, -3.0), Color(0.15, 0.15, 0.18), Vector3(0, 15 - i * 30, 0))
		Props.box(room, Vector3(0.102, 0.03, 0.282), Vector3(0.95 + i * 0.13, 0.015, -3.0), Color(0.95, 0.95, 0.95), Vector3(0, 15 - i * 30, 0))
	var pack := _put(room, Node3D.new(), Vector3(-0.35, 0.0, -2.95), 20.0)
	Props.box(pack, Vector3(0.32, 0.4, 0.16), Vector3(0, 0.2, 0), Color(0.2, 0.22, 0.25))
	Props.box(pack, Vector3(0.26, 0.15, 0.06), Vector3(0, 0.13, 0.1), Color(0.18, 0.2, 0.23))
	for k in 3:
		Props.cyl(pack, 0.022, 0.01, Vector3(-0.08 + k * 0.08, 0.3, 0.085), [Color(0.9, 0.2, 0.2), Color(0.95, 0.85, 0.2), Color(0.2, 0.6, 0.9)][k], Vector3(90, 0, 0))
	# Burned CDs with Sharpie titles next to the computer.
	for i in 4:
		Props.box(room, Vector3(0.14, 0.01, 0.125), Vector3(0.05, 0.765 + i * 0.011, -5.5), Color(0.9, 0.92, 0.95) if i % 2 else Color(0.3, 0.3, 0.35), Vector3(0, i * 9 - 12, 0))
	_thing(room, "BurnedCDs", Vector3(0.05, 0.79, -5.5), Vector3(0.18, 0.06, 0.16), "Burned CDs",
		"Burned CDs in Sharpie: 'MIX 4 THE CAR.' 'SAD SONGS DO NOT TOUCH.' 'STATIC PARADE LIVE (BOOTLEG!!!)'",
		"One just says 'LEO???' with a question mark. You don't know what that means. You want to.")
	# Another poster on the wall by the door, and the Discman on the bed.
	var poster := _put(room, Node3D.new(), Vector3(1.39, 1.15, -5.3), -90.0)
	Props.box(poster, Vector3(0.45, 0.62, 0.006), Vector3(0, 0.31, 0), Color(0.08, 0.08, 0.1))
	Props.box(poster, Vector3(0.3, 0.3, 0.003), Vector3(0, 0.3, 0.004), Color(0.75, 0.2, 0.55))
	Props.ball(poster, 0.08, Vector3(0, 0.3, 0.006), Color(0.95, 0.85, 0.2), Vector3(1, 1, 0.1))
	Props.label(poster, "THE GLOW SCOUTS\nSUMMER TOUR '03", Vector3(0, 0.54, 0.005), 0.04, Color(0.95, 0.95, 0.95), Vector3.ZERO)
	var disc := _put(room, Node3D.new(), Vector3(-1.2, 0.5, -4.15), 15.0)
	Props.cyl(disc, 0.07, 0.025, Vector3.ZERO, Color(0.7, 0.72, 0.76))
	Props.cyl(disc, 0.03, 0.004, Vector3(0, 0.013, 0), Color(0.3, 0.35, 0.45))
	Props.ring(disc, 0.04, 0.05, Vector3(0.12, 0.0, 0.02), Color(0.15, 0.15, 0.17), Vector3(0, 0, 90))


# --- Leo's room ----------------------------------------------------------------

static func _leo_room(house: Node3D, root: Node3D) -> void:
	# A low bookshelf by the door: picture books, chapter books, a trophy.
	var shelf := _put(root, Node3D.new(), Vector3(2.76, 0.0, -5.35), 90.0)
	var board := Color(0.88, 0.85, 0.78)
	Props.box(shelf, Vector3(0.8, 0.85, 0.02), Vector3(0, 0.425, -0.13), Color(0.75, 0.72, 0.66))
	for x in [-0.39, 0.39]:
		Props.box(shelf, Vector3(0.02, 0.85, 0.28), Vector3(x, 0.425, 0), board)
	for shelf_y in [0.03, 0.43]:
		Props.box(shelf, Vector3(0.76, 0.02, 0.26), Vector3(0, shelf_y, 0.01), board)
		var x := -0.34
		var i := 0
		while x < 0.32:
			var w := 0.03 + fmod(i * 0.37, 1.0) * 0.03
			var hgt := 0.24 + fmod(i * 0.53, 1.0) * 0.1
			Props.box(shelf, Vector3(w, hgt, 0.18), Vector3(x + w / 2.0, shelf_y + 0.01 + hgt / 2.0, 0.03), Color.from_hsv(fmod(i * 0.23, 1.0), 0.55, 0.75))
			x += w + 0.004
			i += 1
	Props.box(shelf, Vector3(0.8, 0.02, 0.28), Vector3(0, 0.85, 0), board)
	var trophy := _put(shelf, Node3D.new(), Vector3(0.2, 0.86, 0.0))
	Props.box(trophy, Vector3(0.07, 0.04, 0.07), Vector3(0, 0.02, 0), Color(0.2, 0.2, 0.25))
	Props.cyl(trophy, 0.01, 0.08, Vector3(0, 0.08, 0), GOLD)
	Props.ball(trophy, 0.04, Vector3(0, 0.15, 0), GOLD, Vector3(1, 0.8, 1))
	_thing(root, "Trophy", Vector3(2.76, 0.97, -5.15), Vector3(0.12, 0.2, 0.12), "Trophy",
		"PEE WEE SOCCER - PARTICIPANT. Everybody got one. Yours is the shiniest because you polish it.",
		"You scored one goal all season. It was for the other team. It still counts.")
	# Leo's desk under the window: lamp, crayons, a drawing, the virtual pet.
	var desk := _put(root, Node3D.new(), Vector3(4.0, 0.0, -8.33))
	Props.box(desk, Vector3(0.9, 0.03, 0.45), Vector3(0, 0.6, 0), Color(0.95, 0.95, 0.95))
	for x in [-0.42, 0.42]:
		Props.box(desk, Vector3(0.04, 0.6, 0.42), Vector3(x, 0.3, 0), Color(0.3, 0.55, 0.85))
	Props.box(desk, Vector3(0.3, 0.004, 0.22), Vector3(-0.1, 0.617, 0.05), Props.PAPER, Vector3(0, 8, 0))
	Props.ball(desk, 0.035, Vector3(-0.12, 0.62, 0.04), Color(0.95, 0.8, 0.2), Vector3(1, 0.05, 1))
	for k in 6:
		Props.cyl(desk, 0.005, 0.09, Vector3(0.12 + k * 0.014, 0.62, 0.08), Color.from_hsv(k / 6.0, 0.8, 0.9), Vector3(90, 0, 0))
	Props.cyl(desk, 0.06, 0.02, Vector3(0.33, 0.625, -0.1), Color(0.85, 0.2, 0.2))
	Props.cyl(desk, 0.008, 0.25, Vector3(0.33, 0.75, -0.1), Color(0.85, 0.2, 0.2))
	Props.cyl(desk, 0.09, 0.1, Vector3(0.33, 0.88, -0.1), Color(0.95, 0.9, 0.6), Vector3.ZERO, true)
	var pet := _put(desk, Node3D.new(), Vector3(0.18, 0.615, -0.08))
	Props.ball(pet, 0.03, Vector3(0, 0.0, 0), Color(0.55, 0.85, 0.75), Vector3(0.9, 0.35, 1.1))
	Props.box(pet, Vector3(0.025, 0.003, 0.02), Vector3(0, 0.01, -0.004), Color(0.55, 0.65, 0.5))
	_thing(root, "VirtualPet", Vector3(4.18, 0.65, -8.41), Vector3(0.12, 0.08, 0.12), "Your virtual pet",
		"Your virtual pet. His name is Pickles. He's died four times this month, but he always comes back.",
		"He's hungry. He's always hungry. You feed him a little pixel hamburger. He does a little dance.")
	_thing(root, "Drawing", Vector3(3.9, 0.64, -8.28), Vector3(0.32, 0.04, 0.24), "Your drawing",
		"A drawing of the house. You made the porch light extra big, with yellow lines coming out of it so you'd know it's on.")
	# The clock radio on the nightstand, a bear on the bed, sneakers by the door.
	_put(root, Props.clock_radio("7:00"), Vector3(5.63, 0.5, -6.03), -150.0)
	var bear := _put(root, Node3D.new(), Vector3(5.75, 0.52, -8.0), 200.0)
	Props.ball(bear, 0.09, Vector3(0, 0.08, 0), Color(0.6, 0.4, 0.22))
	Props.ball(bear, 0.065, Vector3(0, 0.21, 0.01), Color(0.6, 0.4, 0.22))
	for side in [-1, 1]:
		Props.ball(bear, 0.025, Vector3(side * 0.05, 0.27, 0.0), Color(0.55, 0.36, 0.2))
		Props.ball(bear, 0.03, Vector3(side * 0.07, 0.02, 0.06), Color(0.6, 0.4, 0.22))
	Props.ball(bear, 0.025, Vector3(0, 0.2, 0.065), Color(0.85, 0.7, 0.5))
	for i in 2:
		Props.box(root, Vector3(0.08, 0.07, 0.2), Vector3(2.85 + i * 0.1, 0.035, -7.6), Color(0.3, 0.5, 0.85), Vector3(0, 20 - i * 25, 0))


# --- The front porch -------------------------------------------------------------

static func _porch(house: Node3D, root: Node3D, season: String) -> void:
	# The house number by the door and a welcome mat.
	var plaque := _put(root, Node3D.new(), Vector3(-1.22, 1.55, 2.66))
	Props.box(plaque, Vector3(0.26, 0.11, 0.015), Vector3.ZERO, Color(0.12, 0.12, 0.12))
	Props.label(plaque, "412", Vector3(0, 0, 0.009), 0.07, GOLD, Vector3.ZERO)
	Props.box(root, Vector3(0.8, 0.012, 0.45), Vector3(-2.1, 0.006, 3.0), Color(0.45, 0.3, 0.15))
	# A rocking chair on the far end of the porch.
	var chair := _put(root, Node3D.new(), Vector3(-0.35, 0.0, 3.4), 200.0)
	var white := Color(0.92, 0.92, 0.88)
	Props.box(chair, Vector3(0.48, 0.04, 0.45), Vector3(0, 0.42, 0), white)
	Props.box(chair, Vector3(0.48, 0.55, 0.04), Vector3(0, 0.72, -0.22), white, Vector3(-10, 0, 0))
	for x in [-0.22, 0.22]:
		Props.box(chair, Vector3(0.03, 0.04, 0.7), Vector3(x, 0.03, 0), white, Vector3(-5, 0, 0))
		for z in [-0.18, 0.18]:
			Props.box(chair, Vector3(0.03, 0.4, 0.03), Vector3(x, 0.22, z), white)
	# The mailbox at the end of the walk.
	var mailbox := _put(root, Node3D.new(), Vector3(-1.3, -0.45, 11.1))
	Props.box(mailbox, Vector3(0.08, 1.05, 0.08), Vector3(0, 0.52, 0), Color(0.35, 0.25, 0.15))
	Props.box(mailbox, Vector3(0.2, 0.2, 0.45), Vector3(0, 1.15, 0), Color(0.15, 0.15, 0.17))
	Props.box(mailbox, Vector3(0.02, 0.14, 0.04), Vector3(0.11, 1.2, -0.12), Color(0.85, 0.12, 0.1))
	match season:
		"halloween":
			for at in [Vector3(-2.95, 0.0, 4.55), Vector3(-1.2, 0.0, 4.6)]:
				var p := Props.ball(root, 0.17, at + Vector3(0, 0.15, 0), Color(0.9, 0.42, 0.06), Vector3(1, 0.85, 1))
				p.material = Decorations.mat(Color(0.9, 0.42, 0.06), 0.5)
				Props.cyl(root, 0.015, 0.06, at + Vector3(0, 0.31, 0), Color(0.3, 0.4, 0.15))
			# A fake spiderweb in the corner by the lamp.
			for i in 6:
				var a := i * PI / 10.0
				Props.box(root, Vector3(0.006, 0.55, 0.006), Vector3(0.05 - sin(a) * 0.27, 2.4 - cos(a) * 0.27, 2.68), Color(0.95, 0.95, 0.95), Vector3(0, 0, rad_to_deg(a)))
		"fall":
			# Mums by the steps, pumpkins and a hay bale, corn stalks on the posts.
			for at in [Vector3(-2.95, 0.0, 4.6), Vector3(-1.2, 0.0, 4.6)]:
				Props.cyl(root, 0.16, 0.22, at + Vector3(0, 0.11, 0), Color(0.55, 0.3, 0.15))
				Props.ball(root, 0.22, at + Vector3(0, 0.3, 0), Color(0.8, 0.45, 0.1), Vector3(1, 0.7, 1))
			Props.box(root, Vector3(0.75, 0.38, 0.45), Vector3(-0.6, 0.19, 4.55), Color(0.85, 0.72, 0.4))
			for k in 3:
				Props.ball(root, 0.13 - k * 0.025, Vector3(-0.85 + k * 0.25, 0.48 - k * 0.02, 4.55), [Color(0.92, 0.48, 0.08), Color(0.95, 0.9, 0.8), Color(0.88, 0.55, 0.1)][k], Vector3(1, 0.8, 1))
			for x in [-2.75, -1.45]:
				for k in 5:
					Props.box(root, Vector3(0.03, 1.4, 0.03), Vector3(x + (k - 2) * 0.04, 0.7, 5.03), Color(0.75, 0.62, 0.35), Vector3(0, 0, (k - 2) * 4.0))
		"christmas":
			# A wreath on the front door (it swings open with the door).
			var door := house.get_node("House/LivingRoom/Things/FrontDoor") as Node3D
			var wreath := Node3D.new()
			wreath.position = Vector3(0, 1.4, 0.05)
			door.add_child(wreath)
			Props.ring(wreath, 0.12, 0.22, Vector3.ZERO, Color(0.1, 0.32, 0.15), Vector3(90, 0, 0))
			for i in 8:
				var a := i * TAU / 8.0
				Props.ball(wreath, 0.018, Vector3(cos(a) * 0.17, sin(a) * 0.17, 0.04), Color(0.85, 0.1, 0.1))
			Props.box(wreath, Vector3(0.14, 0.08, 0.03), Vector3(0, -0.18, 0.04), Color(0.85, 0.1, 0.12))
			Look.upgrade(wreath)
			# Garland with red bows along the front of the porch rail.
			for seg in [[-3.0, 0.5], [-0.65, 1.6]]:
				var g := Props.cyl(root, 0.045, seg[1], Vector3(seg[0], 0.8, 5.0), Color(0.12, 0.35, 0.16), Vector3(0, 0, 90))
				g.sides = 8
				Props.box(root, Vector3(0.12, 0.1, 0.03), Vector3(seg[0], 0.76, 5.04), Color(0.85, 0.1, 0.12))
			# Colored lights along the edge of the porch roof.
			var colors := [Color(1, 0.2, 0.2), Color(0.2, 1, 0.35), Color(0.35, 0.5, 1), Color(1, 0.8, 0.25)]
			var x := -3.3
			var i := 0
			while x <= 0.2:
				var b := Props.ball(root, 0.03, Vector3(x, 2.58, 5.0), colors[i % colors.size()])
				b.material = Decorations.mat(colors[i % colors.size()], 3.0)
				x += 0.25
				i += 1
			# Light-up candy canes on either side of the steps.
			for at in [Vector3(-2.8, -0.45, 5.75), Vector3(-1.4, -0.45, 5.75)]:
				var cane := _put(root, Node3D.new(), at)
				for k in 6:
					Props.cyl(cane, 0.03, 0.12, Vector3(0, 0.06 + k * 0.12, 0), Color(0.95, 0.1, 0.1) if k % 2 == 0 else Color(0.97, 0.97, 0.97)).material = Decorations.mat(Color(0.95, 0.1, 0.1) if k % 2 == 0 else Color(0.97, 0.97, 0.97), 1.2)
				Props.ring(cane, 0.06, 0.09, Vector3(0.075, 0.74, 0), Color(0.95, 0.1, 0.1), Vector3(90, 0, 0))
