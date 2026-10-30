extends HouseChapter
## Thanksgiving, getting ready — November. Thanksgiving morning at home, then
## the drive to Grandma's.
## Wake up → get Biscuit's leash (your coat and handheld are there too, if
## you want them) while Mom guards the pies, Dad loads the van and Jamie
## protests the hour → out the front door → the drive: autumn trees, the parade
## on the radio, "over the river" → Thanksgiving at Grandma's.

enum Step { GATHER, LEAVE, DRIVE, END }

## Far from the house, so the road and fields don't show through its windows.
const DRIVE_AT := Vector3(1000.0, 0.0, 0.0)
## Same seat as the drive home (scripts/chapter_3_drive_home.gd).
const LEO_SEAT := Vector3(0.38, 0.14, 0.62)
const BISCUIT_SEAT := Vector3(-0.04, 0.42, 0.66)

var mom: Interactable
var jamie: Interactable
var car: CarRide
var _things := {}
## What each thing is called in the checklist, in the order it's listed.
const THING_NAMES := { "leash": "Biscuit's leash" }
## Where Biscuit waits once he's on his leash: by the front door, out of its swing.
const DOOR_WAIT := Vector3(-1.5, 0.05, 1.25)


func _ready() -> void:
	super._ready()
	_morning()
	tv_screen.channel = "special"
	set_porch_light(false)

	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	mom.position = Vector3(5.4, 0.0, 1.5)
	mom.rotation.y = deg_to_rad(150.0)
	# On open floor by the kitchen doorway, arms full of folding chairs (not in the couch).
	dad.position = Vector3(2.0, 0.0, 1.3)
	dad.rotation.y = deg_to_rad(-120.0)
	# Slumped on the couch, protesting the hour (not in the hallway, which is one kid wide).
	jamie = Figure.person(self, "Jamie", Vector3(0.5, 0.0, 2.05), 180.0, 1.62, Figure.JAMIE, true)

	add_chatter(mom, "Mom", [
		"Do not touch the pies. I counted them. I'll know.",
		"Shoes, coat, and something to do in the car. Two hours is two hours.",
		"Did you brush your teeth? Breathe on me. ...Okay, go.",
	])
	add_chatter(dad, "Dad", [
		"Who wants to help me load the van? Nobody? Great. Love that.",
		"Grandma said noon. Grandma means eleven-thirty.",
		"I'm bringing the folding chairs. Every year, and every year we don't use them.",
	])
	add_chatter(jamie, "Jamie", [
		"It's nine a.m. On a holiday. This is a crime.",
		"Grandma's house doesn't have the internet. I'm bringing every CD I own.",
		"If Uncle Ray asks about school, I'm 'fine.' That's all he gets.",
	])

	# Thanksgiving things around the house.
	var pies := box_thing("Pies", Vector3(4.6, 0.8, 0.4), Vector3(0.5, 0.06, 0.32), Color(0.85, 0.75, 0.6), "Pies",
		"Two pumpkin pies and a pecan, under foil. Mom wrote DO NOT TOUCH on the foil. Mostly on the pecan.",
		"You can smell the cinnamon through the foil. It's a trap. You walk away.")
	dress(pies, Props.pies())
	# Optional: nice to look at, not needed to leave.
	var coat := box_thing("Coat", Vector3(-1.4, 1.2, 2.42), Vector3(0.4, 0.55, 0.12), Color(0.2, 0.35, 0.6), "Coat and shoes",
		"Your puffy coat, the one that swishes. Shoes on the wrong feet, then the right ones.",
		"You zip the coat all the way up. Now you can't turn your head. Worth it.")
	dress(coat, Props.coat_on_hook(0.95), 180.0)
	var handheld := box_thing("Handheld", Vector3(5.2, 0.55, -7.15), Vector3(0.14, 0.04, 0.09), Color(0.45, 0.3, 0.6), "Your handheld game",
		"Your handheld. Fresh batteries from the junk drawer. Two hours is a long time.",
		"You check the batteries again. Still fresh. Still two hours.")
	dress(handheld, Props.handheld(), 200.0)
	_things["leash"] = box_thing("Leash", Vector3(3.0, 1.25, 2.44), Vector3(0.12, 0.35, 0.05), Color(0.8, 0.15, 0.15),
		"Biscuit's leash")
	dress(_things["leash"], Props.leash_on_hook(), 180.0)
	for id in _things:
		(_things[id] as Interactable).used.connect(_on_thing.bind(id))
	front_door.used.connect(_on_front_door)
	add_trigger(Vector3(-1.55, 1.0, 4.1), Vector3(3.3, 2.0, 1.6), _on_porch)

	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Leaves all over the yard. Dad says he'll rake them this weekend. He said that last weekend."
	window.repeat_text = "The neighbors' van is already gone. Everybody's going somewhere today."
	($House/Kitchen/Furniture/CalendarMonth as Label3D).text = "NOVEMBER"
	house_text({
		"Clock": ["9:05 in the morning. On a holiday. Jamie's right, it's a crime.",
			"Dad wanted to leave at nine. Dad always wants to leave at nine."],
		"Fridge": ["No room for anything. It's all whipped cream, a bag of rolls, and the green bean casserole for Grandma's.",
			"You're not allowed to touch anything in here. Mom has a list."],
		"CalendarI": ["NOVEMBER. Today's box just says GRANDMA'S in Mom's handwriting, underlined twice."],
		"Coats": ["Everybody's coat is off the hooks and on the arm of the couch, ready to go."],
		"KidWindow": ["Gray out. The neighbors' inflatable ghost is finally gone. There's a paper turkey in their window now."],
		"Backpack": ["No school till Monday. The backpack can wait. The backpack can always wait."],
	})

	player.teleport(Vector3(4.6, 0.05, -7.0), 90.0)
	await open_chapter("November", "Thanksgiving: Getting Ready")
	hud.show_memory("Thanksgiving. The whole house smells like the pies Mom baked last night.", 5.0)
	await wait(3.0)
	_checklist()


## A gray late-November morning; the street's porch lights are off.
func _morning() -> void:
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = Color(0.5, 0.58, 0.7)
	sky.sky_horizon_color = Color(0.82, 0.78, 0.7)
	sky.ground_horizon_color = Color(0.6, 0.55, 0.45)
	sky.ground_bottom_color = Color(0.35, 0.3, 0.25)
	env.ambient_light_color = Color(0.9, 0.85, 0.78)
	env.ambient_light_energy = 0.65
	env.fog_light_color = Color(0.75, 0.72, 0.68)
	env.fog_density = 0.008
	var sun := lights.get_node("Moon") as DirectionalLight3D
	sun.light_color = Color(1, 0.92, 0.8)
	sun.light_energy = 0.9
	for e in street.porch_lights + [street.far_light]:
		street.kill_light(e, 0.01)
	set_window_daylight(true)


# --- Step 0: gathering your things ---------------------------------------

func _on_thing(_by: Node, id: String) -> void:
	if busy or step != Step.GATHER:
		return
	var it := _things[id] as Interactable
	it.enabled = false
	it.visible = false
	if id == "leash":
		_leash_biscuit()
	_things.erase(id)
	_checklist()
	if _things.is_empty():
		step = Step.LEAVE
		objective("Head out to the van")
		await wait(2.0)
		await say([["Dad", "Van's warmed up! Let's roll, everybody. Jamie, that means you."]])


func _on_front_door(_by: Node) -> void:
	if step == Step.GATHER:
		hud.show_memory("Not yet. You still need %s." % _missing(), 4.0)
		return
	if step != Step.LEAVE or not front_door.enabled:
		return
	open_front_door()


## The objective lists what you still need, so you always know what's left.
func _checklist() -> void:
	if step != Step.GATHER or _things.is_empty():
		return
	objective("Get " + "  ·  ".join(_things.keys().map(func(k: String) -> String: return THING_NAMES[k])))


func _missing() -> String:
	var names: Array = _things.keys().map(func(k: String) -> String: return THING_NAMES[k])
	if names.size() == 1:
		return names[0]
	return ", ".join(names.slice(0, names.size() - 1)) + " and " + names[-1]


## Biscuit hears the leash, comes running, gets clipped on, and waits by the
## front door with his leash on.
func _leash_biscuit() -> void:
	hud.show_memory("Biscuit hears the leash jingle from across the house. He's ready before you are.", 4.5)
	dog.greet()
	dog.bark(2)
	_put_leash_on(dog)
	dog.go_to([DOOR_WAIT], true, front_door.global_position)
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)


## A red leash, clipped to the collar and trailing on the floor.
func _put_leash_on(d: Node3D) -> void:
	var red := Decorations.mat(Color(0.75, 0.12, 0.12))
	var strap := CSGBox3D.new()
	strap.size = Vector3(0.025, 0.012, 0.42)
	strap.position = Vector3(0.0, 0.2, -0.22)
	strap.rotation_degrees.x = 55.0
	strap.material = red
	d.add_child(strap)
	var trail := CSGBox3D.new()
	trail.size = Vector3(0.025, 0.012, 0.5)
	trail.position = Vector3(0.05, 0.01, 0.05)
	trail.rotation_degrees.y = 20.0
	trail.material = red
	d.add_child(trail)


func _on_porch() -> void:
	if step != Step.LEAVE:
		return
	step = Step.DRIVE
	objective("")
	await _drive()


# --- Step 1: the drive ---------------------------------------------------

func _drive() -> void:
	busy = true
	lock(true)
	await hud.fade(1.0, 1.5).finished
	car = CarRide.new()
	car.daytime = true
	car.position = DRIVE_AT
	add_child(car)
	var cabin := car.get_node("Cabin") as Node3D
	var car_dad := Figure.person(cabin, "Dad", Vector3(-0.38, -0.1, -0.5), 180.0, 1.8, Figure.DAD, true)
	var car_mom := Figure.person(cabin, "Mom", Vector3(0.38, -0.1, -0.5), 180.0, 1.68, Figure.MOM, true)
	Figure.person(cabin, "Jamie", Vector3(-0.38, -0.04, 0.62), 180.0, 1.62, Figure.JAMIE, true)
	add_chatter(car_dad, "Dad", ["Nobody needs the bathroom. Right? Right.", "That's a hawk. Or a big pigeon."])
	add_chatter(car_mom, "Mom", ["Look at the trees, hon. Look how red."])
	# Leo's window: nothing to see but what's outside it.
	var window := Interactable.new()
	window.name = "CarWindow"
	window.prompt = "Look out the window"
	window.memory_text = "Red trees, orange trees, yellow trees, and one tree that can't make up its mind."
	window.repeat_text = "Every yard has a leaf pile somebody's dad gave up on halfway."
	window.position = Vector3(0.73, 1.05, 0.35)
	var glass := CollisionShape3D.new()
	var pane := BoxShape3D.new()
	pane.size = Vector3(0.04, 0.4, 0.6)
	glass.shape = pane
	window.add_child(glass)
	cabin.add_child(window)
	_biscuit_in_car(cabin)
	player.sit(DRIVE_AT + LEO_SEAT, 0.0)
	dog.set_active(false)
	await wait(0.5)
	await hud.fade(0.0, 2.0).finished
	lock(false)

	await say([
		["Dad", "Everybody buckled? Biscuit, you buckled?"],
		["", "Biscuit's nose is pressed to the window. Every car that passes is the most exciting car he's ever seen."],
		["Mom", "The parade's on the radio."],
		["Jamie", "How do you watch a parade on the radio."],
		["Dad", "Imagination, Jamie. Look into your heart."],
	])
	await wait(6.0)
	await say([
		["Mom", "When we get there, Grandma's going to say you got taller. Just let her."],
		["Dad", "Okay. Over the river..."],
		["Mom", "Don't."],
		["Dad", "...and through the woods!"],
		["Jamie", "Every. Single. Year."],
	])
	await wait(5.0)
	lock(true)
	await hud.fade(1.0, 2.5).finished
	hud.show_line("", "Two hours. One rest stop. Biscuit's nose prints on every window in the van.")
	await wait(3.5)
	hud.clear_line()
	step = Step.END
	busy = false
	go_to_chapter("res://scenes/chapter_2_thanksgiving.tscn")


## Biscuit rides in the middle seat, sitting up so he can see out.
func _biscuit_in_car(cabin: Node3D) -> void:
	var rider := Dog.new()
	rider.name = "BiscuitRiding"
	var pet := Interactable.new()
	pet.name = "PetBody"
	pet.prompt = "Pet Biscuit"
	pet.memory_text = "He leans his whole weight into your hand without looking away from the window."
	pet.repeat_text = "His tail thumps the seat. Jamie says 'ow' even though it didn't hit them."
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 0.45, 0.5)
	shape.shape = box
	shape.position = Vector3(0, 0.22, 0)
	pet.add_child(shape)
	rider.add_child(pet)
	rider.parked = true
	rider.pose = Dog.Pose.SIT
	rider.position = BISCUIT_SEAT
	cabin.add_child(rider)
