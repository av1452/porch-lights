extends HouseChapter
## Winter Break — late December. The slow days between Christmas and New
## Year's: no school, no homework, no hurry.
## Sleep in → in any order: hot chocolate and leftovers with Mom, Grandma's
## thank-you note, player two with Jamie, a snowman in the front yard with
## Biscuit bounding around it → evening: a board game, the tree lit, falling
## asleep on the couch → New Year's Eve.
## (The thank-you note and player two came from the old January 3 chapter.)

enum Step { DAY, EVENING, END }

## Front yard, just past the porch steps.
const SNOWMAN_AT := Vector3(-2.1, -0.45, 7.2)
## Where Biscuit runs laps in the snow.
const YARD_LAPS: Array[Vector3] = [Vector3(-3.6, -0.4, 6.6), Vector3(-3.2, -0.4, 8.6), Vector3(-0.8, -0.4, 8.4), Vector3(-0.6, -0.4, 6.4)]
## Things to do; the evening comes once you've done this many of them.
const ENOUGH := 3
## Your mug of cocoa on the counter, by the radio.
const COCOA_AT := Vector3(6.48, 0.99, 0.5)
## How many marshmallows "all of them" is.
const MARSHMALLOWS := 5
## The board game on the coffee table, within reach of the couch.
const BOARD_AT := Vector3(0.0, 0.41, 0.55)
const BOARD_SPACES := 16
## Your three turns: what you roll, how far the bottle cap goes, what everybody says.
const ROLLS := [
	{ "result": "A four. Clink, clink, clink, clink.", "spaces": [4], "lines": [
		["Jamie", "Dad. Leo's playing with garbage. That's a bottle cap."],
		["Dad", "That bottle cap has been in this family longer than you have. Show some respect."],
	] },
	{ "result": "Double fives! Ten spaces... right onto the one that says GO BACK 3.", "spaces": [10, -3], "lines": [
		["", "Somebody wrote 'SORRY' next to GO BACK 3 in crayon, years ago. You're pretty sure it was Jamie."],
		["Mom", "Rules are rules, kiddo. Back you go."],
	] },
	{ "result": "The die bounces off the table and under the couch. Biscuit gets there first.", "spaces": [1], "lines": [
		["Mom", "It's a one. I'm calling it a one. It's wet, I'm not checking."],
		["", "Biscuit looks very proud of himself. Jamie laughs so hard they snort, which makes everybody laugh."],
	] },
]

var mom: Interactable
var jamie: Interactable
var _note: Interactable
var _snow_pile: Interactable
var _snowman: Node3D
var _snowman_parts := 0
var _done := {}
var _outside := false
var _board: Node3D
var _cap: CSGCylinder3D
var _cap_space := 0
var _dice: Interactable
var _rolls := 0
var _cocoa: Interactable
var _marshmallows := 0


func _ready() -> void:
	super._ready()
	Decorations.christmas_tree(self, true)
	tv_screen.channel = "winter"
	set_porch_light(true)
	_snow_day()
	Radio.on_kitchen_counter(self, PackedStringArray(["radio_deck_the_halls", "radio_we_wish_you", "radio_wenceslas"]), -16.0)
	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	mom.position = Vector3(6.0, 0.0, 0.9)
	mom.rotation.y = deg_to_rad(90.0)
	# Dad's out front, shoveling the walk he already shoveled this morning.
	dad.position = Vector3(-0.4, -0.45, 8.0)
	dad.rotation.y = deg_to_rad(160.0)
	jamie = Figure.person(self, "Jamie", Vector3(-0.5, 0.0, 2.05), 180.0, 1.62, Figure.JAMIE, true)

	_note = box_thing("ThankYouNote", Vector3(4.6, 0.77, 0.4), Vector3(0.2, 0.01, 0.15), Color(0.95, 0.93, 0.85), "Write to Grandma")
	dress(_note, Props.letter_and_crayons(), 90.0)
	var racer := box_thing("Racer", Vector3(0.9, 0.09, 1.0), Vector3(0.3, 0.12, 0.18), Color(0.15, 0.35, 0.8), "Mega Robo Racer",
		"It's climbed the couch, Grandma's footstool, and Biscuit. Biscuit has filed a complaint.",
		"The batteries are already running low. Grandma said they would. She sent more.")
	dress(racer, Props.robo_racer(), 30.0)
	var leftovers := box_thing("Leftovers", Vector3(6.55, 0.95, 1.5), Vector3(0.3, 0.06, 0.24), Color(0.85, 0.65, 0.55), "Leftovers",
		"A Christmas ham sandwich at eleven in the morning. This is what winter break is for.",
		"The last piece of Grandma's fudge has a note on it: DAD'S. You leave it. Mostly.")
	dress(leftovers, Props.leftovers(), 90.0)
	_snow_pile = box_thing("SnowPile", Vector3(-2.1, 0.0, 5.0), Vector3(1.0, 0.3, 0.5), Color(0.92, 0.94, 0.98), "Build a snowman")
	dress(_snow_pile, Props.snow_pile(Vector3(1.0, 0.3, 0.5)))
	Props.tie_bandana(dog)
	_snow_pile.enabled = false
	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Snow on everything. Kids pulling sleds toward the big hill behind the school."
	window.repeat_text = "Somebody's Christmas lights are still on in the daytime. They look tired. Good tired."
	house_text({
		"Clock": ["10:40 in the morning, still in pajamas. Winter break time doesn't count.",
			"Whatever time it is, it's not a school time. That's all that matters."],
		"Fridge": ["Leftovers in foil, leftovers in tupperware, and leftovers of the leftovers.",
			"Somebody's put a sticky note on the last slice of pie: JAMIE'S. Somebody else crossed it out."],
		"CalendarI": ["DECEMBER. Mom's crossing off the days. Only three left in the whole year."],
		"Coats": ["Your coat's on the hook, and your mittens are drying on the heater. They smell like wet dog. So does the dog."],
		"KidWindow": ["Kids pulling sleds toward the big hill. Somebody's lost one mitten on the sidewalk."],
		"Backpack": ["Somewhere in there is a worksheet you're supposed to do over break. That's a future-you problem."],
	})

	_note.used.connect(_on_note)
	mom.used.connect(_on_mom)
	jamie.used.connect(_on_jamie)
	front_door.used.connect(_on_front_door)
	_snow_pile.used.connect(_on_snow)
	add_chatter(dad, "Dad", [
		"I shoveled this already. Then it snowed. Then I shoveled it. Now look.",
		"Snowball? Go ahead. I'm not even looking. ...I was looking.",
	])
	add_trigger(Vector3(-1.55, 1.0, 4.1), Vector3(3.3, 2.0, 1.6), _on_porch)

	Audio.make_loop("wind", $Exterior/Ambience, -16.0)
	Audio.play_music("ch1_living_room", 4.0, -10.0)
	player.teleport(Vector3(4.6, 0.05, -7.0), 90.0)
	await open_chapter("December 28", "Winter Break")
	hud.show_memory("10:40 a.m. Nobody woke you up. Nobody's going to. There's no school for a whole other week.", 5.5)
	await wait(3.0)
	_objective()


## Bright snow-light morning. Every window full of white.
func _snow_day() -> void:
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = Color(0.4, 0.55, 0.78)
	sky.sky_horizon_color = Color(0.85, 0.88, 0.92)
	sky.ground_horizon_color = Color(0.8, 0.82, 0.86)
	sky.ground_bottom_color = Color(0.6, 0.62, 0.66)
	env.ambient_light_color = Color(0.86, 0.88, 0.95)
	env.ambient_light_energy = 0.7
	env.fog_light_color = Color(0.8, 0.82, 0.88)
	env.fog_density = 0.006
	var sun := lights.get_node("Moon") as DirectionalLight3D
	sun.light_color = Color(1, 0.96, 0.88)
	sun.light_energy = 1.1
	for e in street.porch_lights + [street.far_light]:
		street.kill_light(e, 0.01)
	var snow_ground := CSGBox3D.new()
	snow_ground.size = Vector3(60, 0.02, 30)
	snow_ground.position = Vector3(-2.0, -0.43, 17.6)
	snow_ground.material = Decorations.mat(Color(0.9, 0.92, 0.97))
	add_child(snow_ground)
	set_window_daylight(true)


func _objective() -> void:
	if step == Step.DAY:
		objective("Enjoy winter break")


func _did(id: String) -> void:
	if _done.has(id):
		return
	_done[id] = true
	if _done.size() >= ENOUGH and step == Step.DAY:
		step = Step.EVENING
		await wait(3.0)
		await _evening()


# --- The kitchen: hot chocolate, the thank-you note ----------------------

func _on_mom(_by: Node) -> void:
	if busy:
		return
	if _done.has("cocoa"):
		var pool := ["Leftover pie for lunch? It's break. Rules are suspended.", "Wear your boots if you go out. Your boots, not Jamie's."]
		say([["Mom", pool[randi() % pool.size()]]])
		return
	if _cocoa:
		say([["Mom", "Go on. Marshmallows don't count on break."]])
		return
	await say([["Mom", "Hot chocolate? Marshmallows: some, or all of them?"]])
	# A mug for you, and the whole bag next to it.
	_cocoa = box_thing("Cocoa", COCOA_AT, Vector3(0.14, 0.1, 0.24), Color.WHITE, "Add a marshmallow")
	var setup := Props.mug(Color(0.2, 0.45, 0.8))
	var bag := Props.box(setup, Vector3(0.08, 0.12, 0.04), Vector3(0, 0.06, -0.11), Color(0.96, 0.96, 0.96), Vector3(0, 0, -8))
	Props.box(bag, Vector3(0.06, 0.04, 0.002), Vector3(0, 0.0, 0.021), Color(0.3, 0.55, 0.9))
	dress(_cocoa, setup)
	_cocoa.used.connect(_on_cocoa)
	objective("Make hot chocolate")


## One marshmallow per use, until it's all of them; then you drink it.
func _on_cocoa(_by: Node) -> void:
	if busy or _done.has("cocoa"):
		return
	if _marshmallows < MARSHMALLOWS:
		var m := Props.cyl(self, 0.012, 0.018, COCOA_AT + Vector3(0, 0.25, 0), Props.WHITE)
		m.rotation_degrees.z = randf_range(0, 90)
		var spot := COCOA_AT + Vector3(randf_range(-0.015, 0.015), 0.04 + _marshmallows * 0.004, randf_range(-0.015, 0.015))
		create_tween().tween_property(m, "position", spot, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_marshmallows += 1
		var thoughts := ["One.", "Two. Mom raises an eyebrow.", "Three. Four. You've stopped counting.",
			"Mom says 'some.' You hear 'more.'", "The bag is empty. You meant 'all of them.' You said 'all of them.'"]
		hud.show_memory(thoughts[_marshmallows - 1], 3.0)
		if _marshmallows == MARSHMALLOWS:
			_cocoa.prompt = "Drink your hot chocolate"
		return
	busy = true
	_cocoa.enabled = false
	await say([
		["", "The marshmallows melt into a white foam on top. You burn your tongue anyway. Every time."],
		["Mom", "While you're here. Grandma's thank-you note. Kitchen table. Best handwriting."],
	])
	busy = false
	_did("cocoa")
	_objective()


func _on_note(_by: Node) -> void:
	if busy or _done.has("note"):
		return
	_note.enabled = false
	await say([
		["", "'Dear Grandma, thank you for the pajamas and the batteries. The robot car can climb the couch.'"],
		["", "'Love, Leo. P.S. Biscuit says thank you for the bandana. P.P.S. Your fudge is the best fudge.'"],
		["", "You draw the porch light at the bottom, with the light coming out of it in yellow marker."],
	])
	_did("note")


# --- The couch: player two ------------------------------------------------

func _on_jamie(_by: Node) -> void:
	if busy:
		return
	if _done.has("game"):
		say([["Jamie", "Hold on, I'm about to beat this level. Okay I'm not. Hold on."]])
		return
	busy = true
	player.sit(Vector3(0.45, 0.05, 1.95), 0.0)
	lock(true)
	await say([
		["Jamie", "Okay. Christmas promise. You can be player two."],
		["", "You're always player two. You don't care. You lose four times and win once, and it's the best win of your whole life."],
		["Jamie", "...Rematch. Best of seven. No, nine."],
	])
	player.stand(Vector3(0.45, 0.05, 1.3), 0.0)
	lock(false)
	busy = false
	_did("game")


# --- Outside: the snowman, and Biscuit in the snow -----------------------

func _on_front_door(_by: Node) -> void:
	if busy or not front_door.enabled:
		return
	open_front_door()


func _on_porch() -> void:
	if _outside:
		return
	_outside = true
	_snow_pile.enabled = true
	hud.show_memory("Cold so bright it squeaks. Biscuit is out the door before you, straight into a snowbank.", 4.5)
	_biscuit_laps()


## Biscuit runs laps around the front yard, the way dogs do in new snow.
func _biscuit_laps() -> void:
	dog.free_roam = false
	dog.global_position = YARD_LAPS[0]
	while is_inside_tree() and step == Step.DAY:
		var lap: Array[Vector3] = YARD_LAPS.duplicate()
		if randf() < 0.5:
			lap.reverse()
		dog.go_to(lap, true)
		await dog.arrived
		if randf() < 0.35:
			dog.bark(1)
		dog.set_pose(Dog.Pose.STAND)
		await wait(randf_range(0.5, 1.5))


func _on_snow(_by: Node) -> void:
	if busy or _snowman_parts >= 3:
		return
	if _snowman == null:
		_snowman = Node3D.new()
		_snowman.position = SNOWMAN_AT
		add_child(_snowman)
	var white := Decorations.mat(Color(0.95, 0.96, 1.0))
	var sizes := [0.45, 0.32, 0.22]
	var heights := [0.4, 1.0, 1.45]
	var ball := CSGSphere3D.new()
	ball.radius = sizes[_snowman_parts]
	ball.position.y = heights[_snowman_parts]
	ball.material = white
	_snowman.add_child(ball)
	_snowman_parts += 1
	Audio.play_sfx("candy_rustle", _snow_pile, -14.0, 0.2)
	match _snowman_parts:
		1:
			hud.show_memory("You roll the bottom. It gets too big to push. That means it's the right size.", 4.0)
		2:
			hud.show_memory("The middle. Dad lifts it on top for you, and pretends it's heavier than it is. It is heavy.", 4.0)
		3:
			_finish_snowman()


func _finish_snowman() -> void:
	busy = true
	var nose := CSGCylinder3D.new()
	nose.cone = true
	nose.radius = 0.035
	nose.height = 0.18
	nose.rotation_degrees.x = -90.0
	nose.position = Vector3(0, 1.45, -0.26)
	nose.material = Decorations.mat(Color(1.0, 0.5, 0.1))
	_snowman.add_child(nose)
	var scarf := CSGTorus3D.new()
	scarf.inner_radius = 0.18
	scarf.outer_radius = 0.26
	scarf.position.y = 1.24
	scarf.material = Decorations.mat(Color(0.7, 0.1, 0.12))
	_snowman.add_child(scarf)
	for side in [-1, 1]:
		var eye := CSGSphere3D.new()
		eye.radius = 0.025
		eye.position = Vector3(side * 0.07, 1.52, -0.2)
		eye.material = Decorations.mat(Color(0.05, 0.05, 0.05))
		_snowman.add_child(eye)
	_snow_pile.enabled = false
	await say([
		["", "A head, a carrot from the fridge, two buttons from Mom's sewing tin, and Dad's scarf."],
		["Dad", "That's my good scarf. ...You know what, he looks better in it."],
		["", "Biscuit sniffs the snowman, very seriously, then lies down in the snow next to it like they're friends now."],
	])
	busy = false
	_did("snowman")


# --- Evening -------------------------------------------------------------

## The tree lit, a board game on the coffee table, everybody home.
func _evening() -> void:
	busy = true
	objective("")
	lock(true)
	await hud.fade(1.0, 2.5).finished
	set_window_daylight(false)
	env.ambient_light_energy = 0.35
	(lights.get_node("Moon") as DirectionalLight3D).light_energy = 0.2
	street.restore_lights()
	_set_up_board()
	house_text({
		"Clock": ["8:30 at night. Nobody's said the word 'bedtime' once. You're not going to be the one who brings it up."],
	})
	dog.set_active(true)
	dog.global_position = Vector3(-0.3, 0.05, 1.35)
	dog.go_to([Vector3(-0.3, 0.05, 1.35)], false)
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.LIE), CONNECT_ONE_SHOT)
	# Everybody around the coffee table.
	mom.position = Vector3(-0.85, 0.0, 0.55)
	mom.rotation.y = deg_to_rad(90.0)
	dad.position = Vector3(0.9, 0.0, 0.35)
	dad.rotation.y = deg_to_rad(-90.0)
	dad.set_meta("mute_chatter", true)
	player.sit(Vector3(0.45, 0.05, 1.95), 0.0) # facing the coffee table
	await wait(0.5)
	await hud.fade(0.0, 2.0).finished
	await say([
		["", "Night comes early. Dad gets out the board game with the missing pieces. The box is held together with packing tape."],
		["Dad", "Okay. Nobody's allowed to be mad at anybody. That's the rule."],
		["", "Your piece is a bottle cap. The real one, the little dog, went missing before you were born."],
	])
	lock(false)
	busy = false
	objective("Your turn: roll the dice")


## The board: a ring of colored spaces, three real pieces and one bottle cap,
## and a pair of dice close enough to reach from the couch.
func _set_up_board() -> void:
	for p in ["House/LivingRoom/Furniture/Remote", "House/LivingRoom/Furniture/TVGuide"]:
		hide_node(p)
	_board = Node3D.new()
	_board.position = BOARD_AT
	add_child(_board)
	var base := CSGBox3D.new()
	base.size = Vector3(0.44, 0.012, 0.44)
	base.material = Decorations.mat(Color(0.93, 0.89, 0.78))
	_board.add_child(base)
	var colors := [Color(0.8, 0.2, 0.2), Color(0.95, 0.75, 0.2), Color(0.25, 0.6, 0.3), Color(0.25, 0.4, 0.8)]
	for i in BOARD_SPACES:
		var tile := CSGBox3D.new()
		tile.size = Vector3(0.045, 0.004, 0.045)
		tile.position = _space(i) + Vector3(0, 0.007, 0)
		tile.material = Decorations.mat(colors[(i / 4) % colors.size()])
		_board.add_child(tile)
	# Mom's, Dad's and Jamie's pieces, already a few spaces ahead of you.
	for pawn: Array in [[5, Color(0.6, 0.55, 0.75)], [3, Color(0.6, 0.2, 0.15)], [4, Color(0.1, 0.1, 0.12)]]:
		var piece := CSGCylinder3D.new()
		piece.radius = 0.012
		piece.height = 0.04
		piece.position = _space(pawn[0]) + Vector3(randf_range(-0.01, 0.01), 0.026, randf_range(-0.01, 0.01))
		piece.material = Decorations.mat(pawn[1])
		_board.add_child(piece)
	_cap = CSGCylinder3D.new()
	_cap.radius = 0.016
	_cap.height = 0.008
	_cap.sides = 12
	_cap.position = _space(0) + Vector3(0, 0.012, 0)
	_cap.material = Decorations.mat(Color(0.75, 0.75, 0.78))
	_board.add_child(_cap)
	_dice = box_thing("Dice", BOARD_AT + Vector3(0.25, 0.015, 0.2), Vector3(0.08, 0.03, 0.05), Color(0.97, 0.97, 0.95), "Roll the dice")
	dress(_dice, Props.dice())
	_dice.used.connect(_on_dice)


## Where space `i` is, going around the edge of the board.
func _space(i: int) -> Vector3:
	var side := (i / 4) % 4
	var along := -0.15 + (i % 4) * 0.1
	match side:
		0: return Vector3(along, 0, 0.18)
		1: return Vector3(0.18, 0, -along)
		2: return Vector3(-along, 0, -0.18)
		_: return Vector3(-0.18, 0, along)


func _on_dice(_by: Node) -> void:
	if busy or _rolls >= ROLLS.size():
		return
	busy = true
	var roll: Dictionary = ROLLS[_rolls]
	_rolls += 1
	objective("")
	# The dice tumble, then the bottle cap goes clink, clink, clink.
	Audio.play_sfx("candy_rustle", _dice, -8.0, 0.3)
	var t := create_tween()
	t.tween_property(_dice, "rotation:y", _dice.rotation.y + TAU * 1.5, 0.5)
	await t.finished
	hud.show_memory(roll.result, 3.0)
	for move: int in roll.spaces:
		await _move_cap(move)
		await wait(0.4)
	await say(roll.lines)
	busy = false
	if _rolls < ROLLS.size():
		objective("Your turn again: roll the dice")
	else:
		await _good_night()


## Hops the bottle cap one space at a time (backward if `spaces` is negative).
func _move_cap(spaces: int) -> void:
	for i in absi(spaces):
		_cap_space = posmod(_cap_space + signi(spaces), BOARD_SPACES)
		var to := _space(_cap_space) + Vector3(0, 0.012, 0)
		var hop := create_tween()
		hop.tween_property(_cap, "position", (_cap.position + to) / 2.0 + Vector3(0, 0.03, 0), 0.12)
		hop.tween_property(_cap, "position", to, 0.12)
		await hop.finished
		Audio.play_sfx("switch_click", _cap, -18.0, 0.2)


## Mom wins, Jamie demands a rematch, and you fall asleep on the couch.
func _good_night() -> void:
	busy = true
	lock(true)
	_dice.enabled = false
	await say([
		["", "Somebody's mad at somebody within ten minutes. Mom wins. Mom always wins."],
		["Jamie", "This game is rigged. I'm going to bed. ...One more round."],
		["", "The tree's the only light by the end. You fall asleep on the couch with Biscuit on your feet, and nobody makes you move."],
	])
	await wait(1.5)
	await hud.fade(1.0, 3.0).finished
	step = Step.END
	await wait(1.0)
	go_to_chapter("res://scenes/chapter_7_new_years_eve.tscn")
