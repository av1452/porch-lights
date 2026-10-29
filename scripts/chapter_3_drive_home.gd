extends Chapter
## Chapter 3 — November. The long drive home from Grandma's.
## Back seat → share Jamie's headphones → Mom and the Black Friday ads, and
## the first Christmas song on the radio → lean on the window and fall asleep
## → the dream street, where every porch light turns into Christmas lights as
## you pass → Grandma's porch → waking up as Dad carries you in → the class party.

enum Step { RIDE, OVERHEAR, SLEEP, DREAM, GRANDMA, END }

## On a booster seat, so he can see out the windshield.
const LEO_SEAT := Vector3(0.38, 0.14, 0.62)
## The dream street (scripts/street.gd) is built at the origin; the
## sidewalk in front of our side of the street, facing the far end.
const DREAM_START := Vector3(-17.8, -0.4, 16.0)
## The middle of the back seat; Biscuit's head lands in Leo's lap.
const BISCUIT_SEAT := Vector3(-0.06, 0.42, 0.66)

@onready var env: Environment = $WorldEnvironment.environment
@onready var car: CarRide = $CarRide

var mom: Interactable
var dad: Interactable
var jamie: Interactable
var grandma: Interactable
var street: Street
var _dream_bounds: StaticBody3D
var _snow: GPUParticles3D


func _ready() -> void:
	super._ready()
	var cabin := car.get_node("Cabin") as Node3D
	# Car seats sit lower than chairs, so the grown-ups sink in a little.
	dad = Figure.person(cabin, "Dad", Vector3(-0.38, -0.1, -0.5), 180.0, 1.8, Figure.DAD, true)
	mom = Figure.person(cabin, "Mom", Vector3(0.38, -0.1, -0.5), 180.0, 1.68, Figure.MOM, true)
	jamie = Figure.person(cabin, "Jamie", Vector3(-0.38, -0.04, 0.62), 180.0, 1.62, Figure.JAMIE, true)
	_earbuds(jamie)
	_biscuit(cabin)
	_snow = _make_snow(cabin)

	_thing(cabin, "Leftovers", Vector3(0.38, 0.52, 0.3), Vector3(0.28, 0.06, 0.22), Color(0.75, 0.75, 0.78),
		"Leftovers", "Grandma wrapped two slices of pie. One is for you. One is 'for your father, and don't let him eat both.'",
		"The foil is still a little warm. You can smell the cinnamon through it.")
	_thing(cabin, "Window", Vector3(0.73, 1.05, 0.35), Vector3(0.04, 0.4, 0.6), Color(0, 0, 0, 0),
		"Look out the window", "Streetlights slide over the ceiling one at a time, like the second hand on a clock.",
		"You fog the glass and draw a house. Then a porch. Then a little light by the door.")
	var hoodie := _thing(cabin, "Hoodie", Vector3(0.62, 0.78, 0.82), Vector3(0.22, 0.2, 0.2), Color(0.1, 0.1, 0.12),
		"Lean on the window", "", "")
	hoodie.enabled = false
	hoodie.used.connect(_on_sleep)
	jamie.used.connect(_on_jamie)

	add_chatter(dad, "Dad", [
		"Seatbelt on back there? Good.",
		"Two more hours, bud. Try to get some sleep.",
		"Don't tell your mom, but I already had one of those slices.",
	])
	add_chatter(mom, "Mom", [
		"Not now, hon. I'm just watching the road.",
		"Grandma sent you home with half the kitchen, huh?",
	])

	player.sit(LEO_SEAT, 0.0)
	Audio.play_sfx("blinker", null, -14.0)
	await open_chapter("November", "The Long Drive Home")
	hud.show_memory("Leftovers on your lap. The heater smells like burnt dust. Jamie has their headphones on.", 5.0)
	await wait(3.0)
	objective("Ask Jamie what they're listening to")


func _exit_tree() -> void:
	if is_instance_valid(street) and street.get_parent() == null:
		street.free()


## Earbuds on a cord, down to the portable CD player in Jamie's lap.
func _earbuds(who: Node3D) -> void:
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.92, 0.92, 0.9)
	var head_y := 0.8656 * 1.62 - 0.136 * 1.62
	for side in [-1, 1]:
		var bud := CSGSphere3D.new()
		bud.radius = 0.018
		bud.position = Vector3(0.11 * side, head_y - 0.01, 0)
		bud.material = white
		who.add_child(bud)
	var cord := CSGCylinder3D.new()
	cord.radius = 0.004
	cord.height = 0.5
	cord.position = Vector3(0.06, head_y - 0.27, -0.06)
	cord.rotation_degrees.x = 12.0
	cord.material = white
	who.add_child(cord)
	# The CD player: a silver disc with a little window on top.
	var player_mat := StandardMaterial3D.new()
	player_mat.albedo_color = Color(0.7, 0.72, 0.76)
	player_mat.metallic = 0.6
	player_mat.roughness = 0.35
	var cd := CSGCylinder3D.new()
	cd.radius = 0.07
	cd.height = 0.025
	cd.position = Vector3(0.04, head_y - 0.5, -0.16)
	cd.material = player_mat
	who.add_child(cd)


## Biscuit rides home stretched across the back seat, head in Leo's lap.
func _biscuit(cabin: Node3D) -> void:
	var dog := Dog.new()
	dog.name = "Biscuit"
	var pet := Interactable.new()
	pet.name = "PetBody"
	pet.prompt = "Pet Biscuit"
	pet.memory_text = "Biscuit sighs the big sigh, the one that means he's not moving until we're home."
	pet.repeat_text = "His ear is inside out. You fix it. He doesn't open his eyes."
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 0.3, 0.6)
	shape.shape = box
	shape.position = Vector3(0, 0.15, 0)
	pet.add_child(shape)
	dog.add_child(pet)
	dog.parked = true
	dog.pose = Dog.Pose.LIE
	dog.position = BISCUIT_SEAT
	dog.rotation.y = -PI / 2.0 # head toward Leo
	cabin.add_child(dog)


## The first snow of the year, only where the headlights catch it.
func _make_snow(cabin: Node3D) -> GPUParticles3D:
	var snow := GPUParticles3D.new()
	snow.name = "Snow"
	snow.amount = 1400
	snow.lifetime = 1.1
	snow.emitting = false
	# Ahead of the car, in the beams; flakes melt away before the windshield.
	snow.position = Vector3(0, 0.9, -17.0)
	snow.visibility_aabb = AABB(Vector3(-4, -4, -8), Vector3(8, 8, 32))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(2.4, 1.6, 8.0)
	# Flakes rush toward the windshield as the car drives into them.
	pm.direction = Vector3(0, -0.15, 1)
	pm.spread = 8.0
	pm.initial_velocity_min = 14.0
	pm.initial_velocity_max = 18.0
	pm.gravity = Vector3(0, -1.5, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	snow.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.045, 0.045)
	var flake := StandardMaterial3D.new()
	# Dim on their own, bright where the headlights hit them.
	flake.albedo_color = Color(0.75, 0.75, 0.75)
	flake.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	flake.roughness = 1.0
	quad.material = flake
	snow.draw_pass_1 = quad
	cabin.add_child(snow)
	return snow


## Something in the car you can look at. A clear color means no mesh.
func _thing(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color,
		prompt_text: String, first: String, again: String) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt_text
	it.memory_text = first
	it.repeat_text = again
	it.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	it.add_child(shape)
	if color.a > 0.0:
		var mesh := CSGBox3D.new()
		mesh.size = size
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.metallic = 0.6 if node_name == "Leftovers" else 0.0
		m.roughness = 0.35 if node_name == "Leftovers" else 0.95
		mesh.material = m
		it.add_child(mesh)
	parent.add_child(it)
	return it


# --- Step 0: Jamie's headphones ----------------------------------------

func _on_jamie(_by: Node) -> void:
	if busy:
		return
	if step != Step.RIDE:
		var pool := ["Shh. This is the good part.", "You're breathing on me.", "Go to sleep, kid."]
		say([["Jamie", pool[randi() % pool.size()]]])
		return
	step = Step.OVERHEAR
	busy = true
	objective("")
	await say([
		["Jamie", "What."],
		["", "You point at the headphones."],
		["Jamie", "...Fine. One earbud. Don't breathe on me."],
	])
	# Jamie's band. Drop the real recording in as audio/music/static_parade.*;
	# until then the old night track stands in.
	var song := "static_parade" if Audio.get_stream("music", "static_parade") else "ch2_night"
	Audio.play_music(song, 2.0, -16.0)
	await say([
		["", "Static Parade. The band from the poster in Jamie's room. It sounds like a radio playing in another house."],
		["", "It's a song you don't know yet. By spring you'll know every word."],
		["Jamie", "If you tell anyone I listen to this, you're dead."],
	])
	busy = false
	await wait(4.0)
	await _worry()
	await wait(2.0)
	await _overhear()


# --- Step 0b: Mom and Dad, quietly ---------------------------------------

## Over the music in one ear, Mom and Dad talking low in the front seat.
func _worry() -> void:
	busy = true
	await say([
		["Mom (front seat)", "Did she seem tired to you?"],
		["Dad (front seat)", "A little. She was up and down all day."],
		["Mom (front seat)", "She wouldn't let me help with the pie. She always lets me help with the pie."],
		["Dad (front seat)", "Maybe we have her over to our place for Christmas this year. Save her the work."],
		["Mom (front seat)", "...Yeah. I'd like that."],
		["", "You keep looking out the window. Grown-ups talk different when they think you're not listening."],
	])
	busy = false


# --- Step 1: Black Friday ads and the first Christmas song ---------------

func _overhear() -> void:
	busy = true
	await say([
		["", "Mom clicks on the dome light. She's got the Black Friday ads from Grandma's paper and a pen."],
		["Mom", "Okay. I'm circling things. Nobody look."],
		["Dad", "Is it the robot car? It's the robot car."],
		["Mom", "I said nobody look!"],
		["", "The radio plays the first Christmas song of the year. Dad turns it up. Mom pretends to be annoyed, then sings anyway."],
		["Dad", "It's not even December!"],
		["Mom", "It's after Thanksgiving. It counts."],
		["", "Jamie takes out the earbud so you can both hear. Everybody sings the part they know."],
	])
	busy = false
	step = Step.SLEEP
	(car.get_node("Cabin/Hoodie") as Interactable).enabled = true
	objective("Lean on the window and close your eyes")


# --- Step 2: falling asleep ---------------------------------------------

func _on_sleep(_by: Node) -> void:
	if busy or step != Step.SLEEP:
		return
	step = Step.DREAM
	busy = true
	objective("")
	lock(true)
	hud.show_memory("Jamie's hoodie is bunched against the glass. It smells like their room.", 4.0)
	Audio.stop_music(6.0)
	var t := create_tween().set_parallel(true)
	t.tween_property(player.head, "rotation:z", deg_to_rad(14.0), 4.0)
	t.tween_property(player.camera, "fov", 95.0, 9.0)
	t.tween_property(env, "fog_density", 0.08, 9.0)
	await wait(3.5)
	_snow.emitting = true
	hud.show_memory("Through your eyelashes: snow. The first snow of the year, falling in the headlights.", 5.0)
	await wait(5.0)
	await hud.fade(1.0, 2.5).finished
	_enter_dream()
	await wait(1.5)
	await hud.fade(0.0, 3.0).finished
	lock(false)
	busy = false
	hud.show_memory("The car is gone. You're standing on a street you almost know. Every porch light is on, waiting.", 5.0)
	await wait(3.0)
	objective("Follow the porch lights")


func _enter_dream() -> void:
	stash(car)
	Audio.set_dreaming(true)
	Audio.play_music("dream_hall", 3.0)
	env.ambient_light_color = Color(0.3, 0.25, 0.5)
	env.ambient_light_energy = 0.4
	env.fog_light_color = Color(0.2, 0.15, 0.35)
	env.fog_density = 0.03
	street = Street.new()
	street.name = "DreamStreet"
	add_child(street)
	Look.upgrade(street)
	_build_dream_bounds()
	player.head.rotation.z = 0.0
	player.camera.fov = 85.0
	player.stand(DREAM_START, 0.0)
	_add_grandma()


func _build_dream_bounds() -> void:
	_dream_bounds = StaticBody3D.new()
	add_child(_dream_bounds)
	# [center, size]: sidewalk edges, the far end, and the walk up to her porch.
	for b in [
		[Vector3(-12.0, 0.5, -20.0), Vector3(0.2, 3.0, 100.0)],
		[Vector3(-24.4, 0.5, -15.0), Vector3(0.2, 3.0, 90.0)],
		[Vector3(-18.0, 0.5, 30.0), Vector3(13.0, 3.0, 0.2)],
		[Vector3(-19.0, 0.5, -70.0), Vector3(15.0, 3.0, 0.2)],
		[Vector3(-26.3, 0.5, -65.0), Vector3(0.2, 3.0, 10.0)],
		[Vector3(-25.3, 0.5, -60.0), Vector3(2.0, 3.0, 0.2)],
	]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = b[1]
		shape.shape = box
		shape.position = b[0]
		_dream_bounds.add_child(shape)


func _add_grandma() -> void:
	var at: Vector3 = (street.far_light.light as Node3D).global_position
	grandma = Figure.person(self, "Grandma", Vector3(at.x + 0.8, Street.GROUND_Y, at.z), 90.0, 1.6, Figure.GRANDMA, false)
	grandma.used.connect(_on_grandma)


func _process(delta: float) -> void:
	super._process(delta)
	# The street is only built once the fade into the dream is done.
	if (step != Step.DREAM and step != Step.GRANDMA) or street == null:
		return
	# Every porch light you pass turns into Christmas lights.
	for e in street.porch_lights:
		if e.z > player.global_position.z + 3.0 and not e.get("christmas", false):
			e["christmas"] = true
			street.set_light_color(e, Decorations.BULB_COLORS[street.porch_lights.find(e) % 3])
			Audio.play_sfx("dog_tags", (e.light as Node3D).global_position, -6.0, 0.2)
	if step == Step.DREAM and player.global_position.z < -52.0:
		step = Step.GRANDMA
		objective("Go up to Grandma's porch")


# --- Step 3: Grandma ----------------------------------------------------

func _on_grandma(_by: Node) -> void:
	if busy or step != Step.GRANDMA:
		return
	step = Step.END
	busy = true
	objective("")
	lock(true)
	await player.tween_look_at(grandma.global_position + Vector3(0, 1.3, 0), 1.0).finished
	await say([
		["Grandma", "There you are. I left the light on for you."],
		["", "Her porch smells like her kitchen. Cinnamon, and the oven, and the hand lotion by the sink."],
		["Grandma", "Look at that. The whole street's ready for Christmas."],
		["Grandma", "Remember what you promised me? Not too fast. Christmas comes when it comes."],
		["", "You nod. She fixes your collar like it's the most important job in the world."],
		["Grandma", "Go on, now. Your dad's carrying you in."],
	])
	await wait(1.0)
	await hud.fade(1.0, 2.5, Color(1.0, 0.94, 0.82)).finished
	await wait(0.5)
	await hud.fade(1.0, 1.0, Color.BLACK).finished
	Audio.stop_music(2.0)
	Audio.set_dreaming(false)
	Audio.play_sfx("car_door", null, -6.0)
	await wait(1.5)
	await say([
		["Dad", "Gotcha. Up we go, bud."],
		["Mom", "Is he out?"],
		["Dad", "Out cold. Grab the pie."],
		["Jamie", "...Night, kid."],
		["", "You're not asleep. Not all the way. You just don't want to open your eyes yet."],
	])
	await wait(1.5)
	Audio.stop_music(2.0)
	await wait(1.0)
	go_to_chapter("res://scenes/school_class_party.tscn")
