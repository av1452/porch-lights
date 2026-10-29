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

var mom: Interactable
var jamie: Interactable
var _note: Interactable
var _snow_pile: Interactable
var _snowman: Node3D
var _snowman_parts := 0
var _done := {}
var _outside := false


func _ready() -> void:
	super._ready()
	Decorations.christmas_tree(self, true)
	tv_screen.channel = "winter"
	set_porch_light(true)
	_snow_day()
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
	box_thing("Racer", Vector3(0.9, 0.09, 1.0), Vector3(0.3, 0.12, 0.18), Color(0.15, 0.35, 0.8), "Mega Robo Racer",
		"It's climbed the couch, Grandma's footstool, and Biscuit. Biscuit has filed a complaint.",
		"The batteries are already running low. Grandma said they would. She sent more.")
	box_thing("Leftovers", Vector3(6.55, 0.95, 1.5), Vector3(0.3, 0.06, 0.24), Color(0.85, 0.65, 0.55), "Leftovers",
		"A Christmas ham sandwich at eleven in the morning. This is what winter break is for.",
		"The last piece of Grandma's fudge has a note on it: DAD'S. You leave it. Mostly.")
	_snow_pile = box_thing("SnowPile", Vector3(-2.1, 0.0, 5.0), Vector3(1.0, 0.3, 0.5), Color(0.92, 0.94, 0.98), "Build a snowman")
	_snow_pile.enabled = false
	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Snow on everything. Kids pulling sleds toward the big hill behind the school."
	window.repeat_text = "Somebody's Christmas lights are still on in the daytime. They look tired. Good tired."

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
	await say([
		["Mom", "Hot chocolate? Marshmallows: some, or all of them?"],
		["", "All of them. The marshmallows melt into a white foam on top. You burn your tongue anyway. Every time."],
		["Mom", "While you're here. Grandma's thank-you note. Kitchen table. Best handwriting."],
	])
	_did("cocoa")


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
	dog.set_active(true)
	dog.global_position = Vector3(0.5, 0.05, 1.4)
	dog.go_to([Vector3(0.5, 0.05, 1.4)], false)
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.LIE), CONNECT_ONE_SHOT)
	mom.position = Vector3(-0.6, 0.0, 0.0)
	mom.rotation.y = deg_to_rad(180.0)
	dad.position = Vector3(0.5, 0.0, -0.3)
	dad.rotation.y = deg_to_rad(-150.0)
	player.sit(Vector3(0.45, 0.05, 1.95), 180.0)
	await wait(0.5)
	await hud.fade(0.0, 2.0).finished
	await say([
		["", "Night comes early. Dad gets out the board game with the missing pieces; the bottle cap is still the little dog."],
		["Dad", "Okay. Nobody's allowed to be mad at anybody. That's the rule."],
		["", "Somebody's mad at somebody within ten minutes. Mom wins. Mom always wins."],
		["Jamie", "This game is rigged. I'm going to bed. ...One more round."],
		["", "The tree's the only light by the end. You fall asleep on the couch with Biscuit on your feet, and nobody makes you move."],
	])
	await wait(1.5)
	await hud.fade(1.0, 3.0).finished
	step = Step.END
	await wait(1.0)
	go_to_chapter("res://scenes/chapter_7_new_years_eve.tscn")
