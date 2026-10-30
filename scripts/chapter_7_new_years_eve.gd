extends HouseChapter
## Chapter 7 — December 31. New Year's Eve. The last chapter.
## You're allowed to stay up till midnight → in any order: the ornaments on
## the tree with Mom (a memory for each), the New Year's snacks, Jamie, the
## snowy street out the window, Grandma calling to say goodnight early →
## dinner → the countdown on TV and midnight together → the house goes quiet:
## look around one last time, the porch light still on → the final dream:
## the long hallway, snow falling indoors, Christmas lights, the warm door,
## and on the other side the porch, every light on the street glowing,
## Biscuit beside you → The End, and the pictures back from the drugstore.
## (The ornaments and the last picture on the roll came from the old January 3
## chapter; the porch light now stays on.)

enum Step { EVENING, COUNTDOWN, QUIET, DREAM, END }

const ORNAMENTS := [
	"Your kindergarten handprint ornament. Your hand was so small. Mom always hangs it in front.",
	"Jamie's macaroni star from second grade. Half the macaroni is gone. Jamie says it's 'vintage.'",
	"The glass bell from Grandma. You hold it up to the tree lights. It still rings, very quietly.",
]
## Things to do before dinner; the evening moves on once you've done this many.
const ENOUGH := 3
## The final dream: the Halloween hallway, and where Biscuit waits by its door.
const DREAM_DOG := Vector3(2.0, 0.05, -24.4)
const PORCH_SPOT := Vector3(-2.1, 0.05, 4.4)
const STREET_POINT := Vector3(-2.1, 0.6, 18.0)

var mom: Interactable
var jamie: Interactable
var _ornaments: Interactable
var _snacks: Interactable
var _ornament_i := 0
var _done := {}
var _looked := {}
var _hall_end: Node3D
var _dream_dog_greeted := false
var _radio: Radio


func _ready() -> void:
	super._ready()
	Decorations.christmas_tree(self, true)
	tv_screen.channel = "newyear"
	set_porch_light(true)
	_radio = Radio.on_kitchen_counter(self, PackedStringArray(["radio_deck_the_halls", "radio_we_wish_you", "radio_wenceslas"]), -16.0)
	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	mom.position = Vector3(-1.5, 0.0, 0.3)
	mom.rotation.y = deg_to_rad(-140.0)
	dad.position = Vector3(5.6, 0.0, 1.2)
	dad.rotation.y = deg_to_rad(120.0)
	jamie = Figure.person(self, "Jamie", Vector3(-0.5, 0.0, 2.05), 180.0, 1.62, Figure.JAMIE, true)

	_ornaments = box_thing("Ornaments", Decorations.TREE_POS + Vector3(0.35, 1.0, 0.35), Vector3(0.5, 0.8, 0.3),
		Color(0, 0, 0, 0), "Look at the ornaments")
	(_ornaments.get_child(1) as Node3D).visible = false
	_snacks = box_thing("Snacks", Vector3(-0.1, 0.45, 0.4), Vector3(0.45, 0.08, 0.3), Color(0.85, 0.6, 0.3), "New Year's snacks")
	box_thing("Racer", Vector3(0.9, 0.09, 1.0), Vector3(0.3, 0.12, 0.18), Color(0.15, 0.35, 0.8), "Mega Robo Racer",
		"New batteries. From Grandma, in the mail, with a note: 'For emergencies.'",
		"It climbs the couch one more time, for the new year.")
	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Snow on every roof. Christmas lights still up on every house, and every porch light on."
	window.repeat_text = "Somebody down the street is already setting off a firework. Too early. Everybody cheers anyway."

	_ornaments.used.connect(_on_ornaments)
	_snacks.used.connect(_on_snacks)
	mom.used.connect(_on_mom)
	jamie.used.connect(_on_jamie)
	window.used.connect(func(_by: Node) -> void: _did("window"))
	add_chatter(dad, "Dad", [
		"I'm making the little hot dogs. Nobody tell your mother how many.",
		"Every year I say I'll make it to midnight without falling asleep. This is my year.",
	])

	Audio.make_loop("wind", $Exterior/Ambience, -14.0)
	Audio.play_music("ch1_living_room", 4.0, -8.0)
	await open_chapter("December 31", "New Year's Eve")
	hud.show_memory("New Year's Eve. You're allowed to stay up till midnight. You've been planning it all week.", 5.5)
	await wait(3.0)
	objective("Stay up till midnight")
	get_tree().create_timer(40.0).timeout.connect(_grandma_calls)


func _did(id: String) -> void:
	if _done.has(id) or step != Step.EVENING:
		return
	_done[id] = true
	if _done.size() >= ENOUGH:
		step = Step.COUNTDOWN
		await wait(2.5)
		await _countdown()


# --- The evening: ornaments, snacks, Jamie, Grandma ----------------------

func _on_ornaments(_by: Node) -> void:
	if busy or step != Step.EVENING or _ornament_i >= ORNAMENTS.size():
		return
	hud.show_memory(ORNAMENTS[_ornament_i], 4.5)
	_ornament_i += 1
	if _ornament_i == ORNAMENTS.size():
		_ornaments.enabled = false
		await wait(4.5)
		await say([["Mom", "Every year I think, this is the year we take it down on New Year's. Every year it's the third."]])
		_did("ornaments")


func _on_snacks(_by: Node) -> void:
	if busy or _done.has("snacks"):
		return
	await say([
		["", "Party mix, the little hot dogs, and sparkling cider in the fancy glasses. You get a fancy glass too."],
		["", "Biscuit sits next to the coffee table and looks at the little hot dogs like he's never been fed in his life."],
	])
	_did("snacks")


func _on_mom(_by: Node) -> void:
	if busy:
		return
	var pool := ["Wrap up the year, hon. What was the best part? ...All of it? Good answer.",
		"If you fall asleep before midnight, I'm not waking you up. That's the deal."]
	say([["Mom", pool[randi() % pool.size()]]])


func _on_jamie(_by: Node) -> void:
	if busy:
		return
	if _done.has("jamie"):
		say([["Jamie", "Resolution: beat that level. And be nicer to you. Mostly the level."]])
		return
	await say([
		["Jamie", "I'm making a mix CD for next year. First song's Static Parade. Obviously."],
		["Jamie", "...Track two's the one from the car. You can have a copy. Don't make it weird."],
	])
	_did("jamie")


## Grandma never makes it to midnight. She calls to say goodnight early.
func _grandma_calls() -> void:
	if step != Step.EVENING or not is_inside_tree():
		return
	while busy:
		await wait(1.0)
	Audio.play_sfx("phone_ring", phone, -2.0)
	await wait(1.5)
	await say([
		["Grandma (phone)", "Happy New Year, honey. I'm going to bed. I never make it to midnight. Don't tell anyone."],
		["Grandma (phone)", "You stay up for me, okay? And leave that porch light on. It's good luck for the new year."],
	])
	_did("grandma")


# --- Midnight -------------------------------------------------------------

func _countdown() -> void:
	busy = true
	objective("")
	lock(true)
	await hud.fade(1.0, 2.0).finished
	hud.show_line("", "Dinner. Then everybody on the couch, under the one big blanket, waiting.")
	await wait(3.5)
	hud.clear_line()
	mom.position = Vector3(-0.2, 0.0, 2.05)
	mom.rotation.y = deg_to_rad(180.0)
	dad.position = Vector3(1.1, 0.0, 2.05)
	dad.rotation.y = deg_to_rad(180.0)
	player.sit(Vector3(0.45, 0.05, 1.95), 0.0)
	dog.set_active(true)
	dog.global_position = Vector3(0.6, 0.05, 1.3)
	dog.go_to([Vector3(0.6, 0.05, 1.3)], false, Vector3(0.6, 0.0, 3.0))
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.LIE), CONNECT_ONE_SHOT)
	await hud.fade(0.0, 1.5).finished
	await player.tween_look_at(tv_screen.get_parent().global_position + Vector3(0, 0.2, 0), 1.0).finished
	await say([
		["Dad", "Here it comes. Here it comes!"],
		["Jamie", "Dad is awake. Everybody, Dad is awake. Historic."],
	])
	_radio.turn_off()
	Audio.stop_music(1.0)
	tv_screen.start_countdown()
	for n in range(10, 0, -1):
		hud.show_line("", str(n) + "...")
		await wait(1.0)
	hud.show_line("", "HAPPY NEW YEAR!")
	Audio.play_sfx("title_sting", null, -4.0)
	# The TV crowd starts singing.
	Audio.play_music("radio_auld_lang_syne", 2.0, -8.0)
	await wait(1.5)
	await say([
		["", "Everybody yells it at once. Dad kisses Mom. Mom kisses Jamie, who lets her. Biscuit barks at all of it."],
		["Jamie", "Happy New Year, kid."],
		["Dad", "Hold on! One picture left on the roll. Everybody on the couch. Biscuit too!"],
	])
	await Game.take_photo("Midnight, the last picture on the roll", "'04 01 01")
	Audio.play_sfx("switch_click", null, 2.0)
	await hud.fade(0.85, 0.05, Color.WHITE).finished
	await hud.fade(0.0, 0.6, Color.WHITE).finished
	await say([
		["Mom", "Okay. Bed, everybody. Leo, you can stay up a few more minutes. You earned it."],
		["Mom", "Leave the porch light on tonight. We'll turn it off one of these days. Until next Halloween."],
	])
	await hud.fade(1.0, 1.5).finished
	_quiet_house()


# --- The quiet house ---------------------------------------------------------

## Everybody's gone to bed. Look around one more time.
func _quiet_house() -> void:
	step = Step.QUIET
	for n in [mom, dad, jamie]:
		(n as Node3D).visible = false
		(n as Interactable).collision_layer = 0
	tv_screen.channel = "off"
	for n in ["Lamp", "KitchenLight", "HallLight"]:
		var l := lights.get_node_or_null(n) as OmniLight3D
		if l:
			l.light_energy *= 0.25
	Audio.stop_music(2.0)
	player.stand(Vector3(0.45, 0.05, 1.3), 0.0)
	var tree := box_thing("TreeLights", Decorations.TREE_POS + Vector3(0, 1.0, 0), Vector3(0.9, 1.8, 0.9), Color(0, 0, 0, 0), "The tree",
		"The tree's the only light in the room. Red, green, blue, gold, on the ceiling and on the walls.")
	(tree.get_child(1) as Node3D).visible = false
	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "The porch light's still on. Up and down the street, everybody's is."
	window.repeat_text = ""
	tree.used.connect(func(_by: Node) -> void: _look_around("tree"))
	window.used.connect(func(_by: Node) -> void: _look_around("window"))
	var pet := dog.get_node_or_null("PetBody") as Interactable
	if pet:
		pet.used.connect(func(_by: Node) -> void: _look_around("biscuit"))
	await wait(0.5)
	await hud.fade(0.0, 2.0).finished
	lock(false)
	busy = false
	hud.show_memory("Everybody's asleep. The house ticks and hums, the way it does at night. You're the last one up. For once.", 5.5)
	objective("Look around before bed")


func _look_around(id: String) -> void:
	if step != Step.QUIET:
		return
	_looked[id] = true
	if _looked.size() >= 2:
		step = Step.DREAM
		objective("")
		busy = true
		await wait(4.0)
		lock(true)
		await say([["", "You lie down on the couch, just for a minute. Biscuit climbs up, which isn't allowed. Nobody's awake to say so."]])
		var t := create_tween().set_parallel(true)
		t.tween_property(player.camera, "fov", 100.0, 5.0)
		t.tween_property(env, "fog_density", 0.1, 5.0)
		await wait(3.0)
		await hud.fade(1.0, 2.5).finished
		await _final_dream()


# --- The final dream ------------------------------------------------------

## Everything at once: the long hallway, snow falling indoors, the Christmas
## lights, Biscuit at the warm door.
func _final_dream() -> void:
	unstash(_dream_hall, self)
	_hall_end = $House/Hallway/HallEnd
	stash(_hall_end)
	string_dream_lights(_dream_hall)
	_dream_hall.add_child(Decorations.snow(Vector3(2.0, 2.2, -17.0), Vector3(0.5, 0.2, 8.5), 400))
	var door := _dream_hall.get_node("DreamDoor") as Interactable
	door.prompt = "Open the door"
	door.used.connect(_on_dream_door)
	Audio.set_dreaming(true)
	Audio.play_music("snow_dream", 3.0)
	env.ambient_light_color = Color(0.3, 0.25, 0.5)
	env.ambient_light_energy = 0.5
	env.background_color = Color(0.03, 0.02, 0.07)
	env.fog_light_color = Color(0.2, 0.15, 0.35)
	env.fog_density = 0.04
	dog.global_position = DREAM_DOG
	dog.go_to([DREAM_DOG], false, DREAM_DOG + Vector3(0, 0, 4.0))
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.78, 0.55)
	glow.light_energy = 0.7
	glow.omni_range = 2.2
	glow.position = DREAM_DOG + Vector3(0, 0.7, 1.2)
	_dream_hall.add_child(glow)
	player.camera.fov = 90.0
	player.stand(Vector3(4.3, 0.05, -6.8), 90.0)
	await wait(1.0)
	await hud.fade(0.0, 3.0).finished
	lock(false)
	busy = false
	hud.show_memory("The hallway again. Longer than it should be. Snowing inside, Christmas lights all the way down, and the warm door at the end.", 6.0)


func _process(delta: float) -> void:
	super._process(delta)
	if step == Step.DREAM and not busy and not _dream_dog_greeted \
			and player.global_position.distance_to(dog.global_position) < 6.0:
		_dream_dog_greeted = true
		dog.greet()
		hud.show_memory("Biscuit's waiting, like he always is. Like he knew you'd come this way.", 5.0)


func _on_dream_door(_by: Node) -> void:
	if busy or step != Step.DREAM:
		return
	step = Step.END
	busy = true
	lock(true)
	await hud.fade(1.0, 2.5, Color(1.0, 0.94, 0.82)).finished
	_the_porch()
	await wait(1.0)
	await hud.fade(0.0, 3.0, Color(1.0, 0.94, 0.82)).finished
	await _ending()


## On the other side of the door: the porch, the snow, every light on the street.
func _the_porch() -> void:
	stash(_dream_hall)
	unstash(_hall_end, $House/Hallway)
	Audio.set_dreaming(false)
	env.fog_density = 0.01
	env.ambient_light_color = Color(0.35, 0.32, 0.45)
	env.ambient_light_energy = 0.4
	open_front_door()
	street.restore_lights()
	set_porch_light(true)
	add_child(Decorations.snow(Vector3(-2.1, 3.6, 9.0), Vector3(9.0, 0.05, 6.0), 900))
	var snow_ground := CSGBox3D.new()
	snow_ground.size = Vector3(30, 0.02, 14)
	snow_ground.position = Vector3(-2.0, -0.43, 10.0)
	snow_ground.material = Decorations.mat(Color(0.85, 0.88, 0.95))
	add_child(snow_ground)
	dog.global_position = PORCH_SPOT + Vector3(0.6, 0, 0.2)
	dog.go_to([PORCH_SPOT + Vector3(0.6, 0, 0.2)], false, STREET_POINT)
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)
	player.camera.fov = player.base_fov
	player.stand(PORCH_SPOT, 180.0)
	player.tween_look_at(STREET_POINT, 0.1)


func _ending() -> void:
	Audio.play_music("ending", 4.0, -6.0)
	await wait(2.0)
	await say([
		["", "Every porch light on the street is on. Snow coming down slow, like it's got all night. Biscuit leans on your leg."],
		["", "Candy taxes, and the kids' table, and the first Christmas song on the radio."],
		["", "Cupcakes with the crunchy sprinkles. A mood ring that says happy. Snow on the bike rack."],
		["", "Untangling lights. Snow blobs. Reindeer pajamas. Batteries from Grandma."],
		["", "Years from now, you'll forget what most of the presents were."],
		["", "You'll never forget the porch lights."],
	])
	await wait(2.0)
	await hud.fade(1.0, 3.0).finished
	await hud.chapter_card("Porch Lights", "The End", 5.0)
	hud.show_memory("For everyone who ever left a light on.", 6.0)
	await wait(7.0)
	Game.game_finished()
	_show_album()


## The pictures came back from the drugstore. Then back to the title screen.
func _show_album() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	layer.add_child(UI.centered(UI.album(Game.to_menu, "Your pictures are back from the drugstore")))


func _exit_tree() -> void:
	super._exit_tree()
	free_stashed([_hall_end])
