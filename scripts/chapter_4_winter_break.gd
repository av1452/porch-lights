extends HouseChapter
## Chapter 4 — December 19. The last day of school before winter break.
## Same house as Chapter 1 (the scene inherits it), decorated for December.
## Home from the class party → decorate sugar cookies with Mom → help Jamie
## find the one dead bulb so the tree lights up → Grandma calls: she's coming
## for Christmas Eve → the claymation special on the couch → dream: snow in
## the living room → wake up to real snow → Chapter 5.

enum Step { FIND_MOM, COOKIES, JAMIE, BULB, PHONE, COUCH, DREAM, END }

## Which of the bulbs you can check is the dead one.
const DEAD_CHECK := 3

var mom: Interactable
var jamie: Interactable
var _jamie_on_couch: Interactable
var _cookies: Interactable
var _bulb_mats: Array[StandardMaterial3D] = []
var _checks: Array[Interactable] = []
var _tree_glow: OmniLight3D
var _ringing := false
var _snow: GPUParticles3D


func _ready() -> void:
	super._ready()
	_set_the_scene()
	var tree := Decorations.christmas_tree(self, false, true)
	_bulb_mats = tree.bulbs
	_checks = tree.checks
	_tree_glow = tree.glow
	for i in _checks.size():
		_checks[i].used.connect(_on_bulb.bind(i))

	mom.used.connect(_on_mom)
	phone.used.connect(_on_phone)
	couch.used.connect(_on_couch)
	jamie.used.connect(_on_jamie)
	add_chatter(dad, "Dad", [
		"Who put these lights away like this? ...Oh. It was me. Last January.",
		"The inflatable Santa won't stay up. He keeps bowing. It's kind of polite.",
		"Two weeks of no school, huh? Your mom and I are thrilled. Thrilled.",
	])

	Audio.make_loop("wind", $Exterior/Ambience, -12.0)
	Audio.play_music("ch4_silent_night", 4.0, -8.0)
	await open_chapter("December 19", "The Last Day Before Winter Break")
	hud.show_memory("Last day of school before winter break. Two whole weeks. Your backpack is full of paper snowflakes.", 5.5)
	await wait(3.0)
	objective("Tell Mom about the class party")


func _set_the_scene() -> void:
	tv_screen.channel = "winter"
	# Mom's baking, Dad's fighting the outside lights by the front door.
	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	mom.position = Vector3(6.0, 0.0, 0.9)
	mom.rotation.y = deg_to_rad(90.0)
	dad.position = Vector3(-1.4, 0.0, 1.9)
	dad.rotation.y = deg_to_rad(-120.0)
	jamie = Figure.person(self, "Jamie", Vector3(-1.5, 0.0, 0.35), -140.0, 1.62, Figure.JAMIE)

	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Gray sky. The kind that looks like snow. You stare at it until it has to."
	window.repeat_text = "The Hendersons put up their light-up reindeer. One of its legs is out. It's still great."
	box_thing("Backpack", Vector3(-2.6, 0.15, 1.45), Vector3(0.3, 0.3, 0.18), Color(0.2, 0.35, 0.7), "Backpack",
		"Paper snowflakes, a paper-chain garland, a clothespin reindeer, and a candy cane from Mrs. Patterson.",
		"The class gift exchange got you a Slinky. It's already tangled. Worth it.")
	box_thing("Catalog", Vector3(0.15, 0.42, 0.45), Vector3(0.24, 0.02, 0.3), Color(0.85, 0.2, 0.2), "Toy catalog",
		"The big toy catalog. You've circled the Mega Robo Racer three times, in three different markers.",
		"Page 47 is folded down. Page 47 is everything.")
	box_thing("Advent", Vector3(6.27, 1.45, -1.55), Vector3(0.03, 0.32, 0.24), Color(0.7, 0.12, 0.15), "Advent calendar",
		"Door 19. The chocolate's shaped like a bell. Jamie already ate theirs. And tomorrow's.",
		"You check door 20. Just to see. It's empty. Jamie.")
	_cookies = box_thing("Cookies", Vector3(6.55, 0.95, 1.5), Vector3(0.4, 0.04, 0.3), Color(0.9, 0.75, 0.5), "Decorate cookies")
	_cookies.enabled = false
	_cookies.used.connect(_on_cookies)


# --- Step 0-1: Mom and the cookies -------------------------------------

func _on_mom(_by: Node) -> void:
	if busy:
		return
	if step == Step.FIND_MOM:
		step = Step.COOKIES
		await say([
			["Mom", "There's my winter-break kid! Two whole weeks. How was the party?"],
			["", "You tell her about the gift exchange, the cupcakes with the sprinkles, and the holiday concert where you sang the loudest."],
			["Mom", "Okay, wash your hands. You're on sprinkles duty."],
		])
		_cookies.enabled = true
		objective("Decorate the sugar cookies")
		return
	var pool := ["Frosting's in the fridge if we run out. We won't run out.", "Did you remember to bring home your snowflakes? I want them on the fridge."]
	say([["Mom", pool[randi() % pool.size()]]])


func _on_cookies(_by: Node) -> void:
	if busy or step != Step.COOKIES:
		return
	step = Step.JAMIE
	busy = true
	_cookies.enabled = false
	await say([
		["", "Sugar cookies, still warm. You do a reindeer, a snowman, and one that's just all sprinkles."],
		["Mom", "That one's my favorite. Don't tell the reindeer."],
		["", "You eat one broken star. Quality control."],
		["Mom", "Go see if Jamie needs help with the tree lights. Your dad gave up."],
		["Dad", "I did not give up! I'm taking a strategic break."],
	])
	busy = false
	objective("Help Jamie with the tree lights")


# --- Step 2-3: the dead bulb --------------------------------------------

func _on_jamie(_by: Node) -> void:
	if busy:
		return
	match step:
		Step.JAMIE:
			step = Step.BULB
			await say([
				["Jamie", "Okay. Dad quit. It's up to us."],
				["Jamie", "One bulb's dead, so the whole string's dead. It's the stupidest thing ever invented. Help me find it."],
			])
			for c in _checks:
				c.enabled = true
			objective("Find the dead bulb")
		Step.BULB:
			say([["Jamie", "Check them one at a time. That's the only way. That's the law of Christmas lights."]])
		Step.COUCH:
			say([["Jamie", "Couch. The claymation one's on. The good one."]])
		Step.FIND_MOM, Step.COOKIES:
			say([["Jamie", "Bring me a cookie and I'll let you help with the lights."]])
		_:
			say([["Jamie", "Best tree we've ever had. Don't tell Dad I said that."]])


func _on_bulb(_by: Node, index: int) -> void:
	if busy or step != Step.BULB:
		return
	if index != DEAD_CHECK:
		var pool := ["Not this one.", "This one's fine. Jamie sighs, very dramatically.", "Nope. You twist it back in."]
		hud.show_memory(pool[index % pool.size()], 2.5)
		_checks[index].enabled = false
		return
	step = Step.PHONE
	busy = true
	for c in _checks:
		c.enabled = false
	hud.show_memory("This one's loose and dark. You twist in a new one from the box.", 3.0)
	await wait(1.5)
	Audio.play_sfx("switch_click", _tree_glow, -4.0)
	Decorations.light_tree({ "bulbs": _bulb_mats, "glow": _tree_glow }, true)
	await say([
		["Jamie", "...YES. See? Just the one."],
		["", "The whole tree lights up at once. Red, green, blue, gold. Dad cheers from the door like it's a touchdown."],
		["Dad", "THAT'S what I'm talking about!"],
	])
	busy = false
	_ringing = true
	_ring()
	objective("Answer the phone")


func _ring() -> void:
	while _ringing:
		Audio.play_sfx("phone_ring", phone, 2.0)
		await wait(3.5)


# --- Step 4: Grandma calls ----------------------------------------------

func _on_phone(_by: Node) -> void:
	if busy:
		return
	if step == Step.DREAM:
		_dream_call()
		return
	if step != Step.PHONE:
		hud.show_memory("The cord's stretched out from Jamie pacing around the kitchen on it.", 4.0)
		return
	step = Step.COUCH
	busy = true
	_ringing = false
	objective("")
	Audio.play_sfx("phone_hangup", phone, -6.0)
	await say([
		["Grandma (phone)", "Hi, honey! It's Grandma. Is it snowing there yet?"],
		["", "You tell her not yet, and about the cookies, and the tree, and the concert."],
		["Grandma (phone)", "Well, guess what. I'm coming for Christmas Eve. And I'm bringing fudge. The good fudge."],
		["Grandma (phone)", "And you know the rule. On Christmas Eve, you leave your porch light on so Santa can find the house."],
		["Grandma (phone)", "Put your mother on, sweetheart. I love you."],
	])
	busy = false
	objective("Watch the Christmas special with Jamie")


# --- Step 5: the couch, and the dream -----------------------------------

func _on_couch(_by: Node) -> void:
	if busy or step != Step.COUCH:
		return
	step = Step.DREAM
	busy = true
	objective("")
	jamie.visible = false
	jamie.collision_layer = 0
	_jamie_on_couch = Figure.person(self, "Jamie", Vector3(-0.5, 0.0, 2.05), 180.0, 1.62, Figure.JAMIE, true)
	player.sit(Vector3(0.45, 0.05, 1.95), 0.0)
	lock(true)
	await say([
		["", "The claymation special. The island of misfit toys. Jamie says it's for babies and doesn't look away once."],
		["", "Mom brings two cookies and two glasses of milk. Biscuit gets the broken ones."],
	])
	var t := create_tween().set_parallel(true)
	t.tween_property(player.camera, "fov", 100.0, 5.0)
	t.tween_property(env, "fog_density", 0.12, 5.0)
	Audio.stop_music(5.0)
	await wait(3.0)
	await hud.fade(1.0, 2.5).finished
	_enter_dream()
	await wait(1.5)
	await hud.fade(0.0, 3.0).finished
	lock(false)
	busy = false
	hud.show_memory("It's snowing. In the living room. It doesn't seem strange at all. It seems perfect.", 5.0)
	await wait(3.0)
	_ringing = true
	_ring()
	objective("Answer the phone")


func _enter_dream() -> void:
	if _jamie_on_couch:
		_jamie_on_couch.visible = false
		_jamie_on_couch.collision_layer = 0
	dog.set_active(false)
	tv_screen.channel = "off"
	for l in lights.get_children():
		if l is OmniLight3D:
			(l as OmniLight3D).light_energy = 0.0
	_tree_glow.light_energy = 1.8
	env.ambient_light_color = Color(0.35, 0.35, 0.6)
	env.ambient_light_energy = 0.5
	env.fog_light_color = Color(0.25, 0.25, 0.4)
	env.fog_density = 0.04
	player.camera.fov = 85.0
	player.stand(Vector3(0.45, 0.05, 1.3), 0.0)
	Audio.set_dreaming(true)
	Audio.play_music("dream_hall", 3.0)
	_snow = Decorations.snow(Vector3(1.5, 2.55, 0.0), Vector3(4.5, 0.05, 2.5))
	add_child(_snow)


func _dream_call() -> void:
	step = Step.END
	busy = true
	_ringing = false
	objective("")
	lock(true)
	Audio.play_sfx("phone_hangup", phone, -6.0)
	await say([
		["Grandma (phone)", "Is it snowing there too?"],
		["", "It's snowing in the kitchen now, soft as flour. You say yes."],
		["Grandma (phone)", "First snow's the best snow. Your mom used to eat it right off the porch rail."],
		["Grandma (phone)", "Don't forget. Porch light on, Christmas Eve. So Santa can find you."],
		["", "You promise. You're good at promises."],
	])
	await wait(1.0)
	await hud.fade(1.0, 2.5, Color(1.0, 0.97, 0.94)).finished
	await wait(0.5)
	await hud.fade(1.0, 1.0, Color.BLACK).finished
	Audio.stop_music(2.0)
	Audio.set_dreaming(false)
	await wait(1.5)
	await say([
		["Mom", "Hey. Hey, sleepyhead. Look outside."],
		["", "It snowed. Real snow. The whole street is white, and it's still coming down."],
		["Jamie", "Snow day energy. Even though there's no school. Doesn't matter. It counts."],
		["Mom", "Five more days till Christmas Eve."],
	])
	await wait(1.5)
	go_to_chapter("res://scenes/chapter_5_christmas_eve.tscn")
