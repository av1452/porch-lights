extends HouseChapter
## Chapter 5 — December 24. Christmas Eve.
## Grandma arrives with fudge → open one present (matching reindeer pajamas,
## everybody) → the disposable-camera family picture → cookies and milk for
## Santa → carrots for the reindeer → porch light on so Santa can find the
## house → out on the porch in the snow → bed, listening for hooves → Chapter 6.

enum Step { GRANDMA, PRESENT, PICTURE, COOKIES, CARROTS, PORCH_LIGHT, OUTSIDE, PORCH, END }

const STREET_POINT := Vector3(-2.1, 0.6, 18.0)

var mom: Interactable
var jamie: Interactable
var grandma: Interactable
var _present: Interactable
var _santa_plate: Interactable
var _carrots: Interactable
var _gave_cd := false


func _ready() -> void:
	super._ready()
	Decorations.christmas_tree(self, true)
	tv_screen.channel = "winter"
	set_porch_light(false)
	dad.position = Vector3(6.0, 0.0, -0.6)
	dad.rotation.y = deg_to_rad(90.0)
	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	mom.position = Vector3(1.6, 0.0, -0.4)
	mom.rotation.y = deg_to_rad(-60.0)
	grandma = Figure.person(self, "Grandma", Vector3(0.9, 0.0, 1.0), -150.0, 1.6, Figure.GRANDMA)
	jamie = Figure.person(self, "Jamie", Vector3(0.9, 0.0, -1.3), 20.0, 1.62, Figure.JAMIE)

	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Snow on the porch rail. Every house on the street is lit up for Christmas Eve."
	window.repeat_text = "The Hendersons' giant star is blinking out of rhythm. It's beautiful anyway."
	box_thing("Fudge", Vector3(4.6, 0.8, 0.15), Vector3(0.22, 0.06, 0.22), Color(0.2, 0.35, 0.25), "Grandma's fudge tin",
		"The good tin, with the Scottish dog on the lid. You take two pieces. Grandma pretends not to see.",
		"The tin is half empty. Dad has a chocolate thumbprint on his sweater.")
	_present = box_thing("GrandmasPresent", Decorations.TREE_POS + Vector3(0.6, 0.11, 0.6), Vector3(0.32, 0.22, 0.26),
		Color(0.7, 0.12, 0.12), "Open one present")
	_present.enabled = false
	_santa_plate = box_thing("SantaCookies", Vector3(4.6, 0.8, 0.65), Vector3(0.24, 0.04, 0.24), Color(0.95, 0.95, 0.92), "Cookies for Santa")
	_santa_plate.enabled = false
	_carrots = box_thing("Carrots", Vector3(6.55, 0.96, 1.7), Vector3(0.25, 0.05, 0.12), Color(1.0, 0.5, 0.1), "Carrots for the reindeer")
	_carrots.enabled = false

	grandma.used.connect(_on_grandma)
	_present.used.connect(_on_present)
	mom.used.connect(_on_mom)
	jamie.used.connect(_on_jamie)
	_santa_plate.used.connect(_on_santa_plate)
	_carrots.used.connect(_on_carrots)
	porch_switch.used.connect(_on_switch)
	front_door.used.connect(_on_front_door)
	add_chatter(dad, "Dad", [
		"Cocoa's almost ready. Marshmallows: yes, or obviously?",
		"Your grandma's fudge is the only reason I married your mother. Don't tell her.",
		"Is that Bing Crosby? It's always Bing Crosby.",
	])
	add_trigger(Vector3(-1.55, 1.0, 4.1), Vector3(3.3, 2.0, 1.6), _on_porch)

	Audio.make_loop("wind", $Exterior/Ambience, -12.0)
	Audio.play_music("ch4_silent_night", 4.0, -8.0)
	await open_chapter("December 24", "Christmas Eve")
	hud.show_memory("Grandma's here! The whole house smells like her fudge and the cold she brought in on her coat.", 5.5)
	await wait(3.0)
	objective("Say hi to Grandma")


# --- Step 0-1: Grandma, and one present ---------------------------------

func _on_grandma(_by: Node) -> void:
	if busy:
		return
	if step == Step.GRANDMA:
		step = Step.PRESENT
		await say([
			["Grandma", "There's my favorite! Don't tell your cousins."],
			["", "She squeezes you so hard your glasses would fall off, if you had glasses."],
			["Grandma", "One present tonight. That's the rule. Go find the one with my handwriting on it."],
		])
		_present.enabled = true
		objective("Open one present on Christmas Eve")
		return
	match step:
		Step.CARROTS:
			say([["Grandma", "Carrots go on the porch, honey. Reindeer don't come inside. Too many antlers."]])
		Step.PORCH_LIGHT:
			say([["Grandma", "Porch light, sweetheart. That's how he finds the house. Every year."]])
		_:
			var pool := ["You got so tall! Stop that.", "Did you leave room for my fudge? Good answer."]
			say([["Grandma", pool[randi() % pool.size()]]])


func _on_present(_by: Node) -> void:
	if busy or step != Step.PRESENT:
		return
	step = Step.PICTURE
	busy = true
	Decorations.hide(_present)
	Audio.play_sfx("candy_rustle", _present, -2.0)
	await say([
		["", "The tag's in Grandma's loopy handwriting: 'For Leo. Open Christmas Eve.'"],
		["", "Pajamas. Matching ones, with little reindeer on them. Everybody got the same pair. Even Dad."],
		["", "Biscuit gets a reindeer bandana. He looks extremely dignified about it."],
		["Jamie", "I'm not wearing these."],
		["Jamie", "...Okay. I'm wearing these. For the picture. Only for the picture."],
		["Mom", "Picture time! Everybody squish in by the tree."],
	])
	busy = false
	objective("Line up for the family picture")


# --- Step 2: the family picture -----------------------------------------

func _on_mom(_by: Node) -> void:
	if busy:
		return
	if step != Step.PICTURE:
		var pool := ["Merry Christmas Eve, sweetie.", "Did you leave Santa a note? You have to leave a note."]
		say([["Mom", pool[randi() % pool.size()]]])
		return
	step = Step.COOKIES
	busy = true
	await say([
		["Mom", "Okay! Grandma in the middle. Jamie, smile with teeth. Biscuit, look at me. Biscuit!"],
	])
	await camera_flash("Christmas Eve, matching pajamas", "'03 12 24")
	await say([
		["", "Click. Wind, wind, wind. Click. The disposable camera has three pictures left. They're all going to be of the tree."],
		["Mom", "We won't see these until the drugstore develops them. That's half the fun."],
		["Grandma", "Now. Santa's cookies won't put themselves out."],
	])
	_santa_plate.enabled = true
	busy = false
	objective("Leave cookies and milk for Santa")


## The disposable camera: a white flash and a click.
func camera_flash(caption: String, stamp: String) -> void:
	await Game.take_photo(caption, stamp)
	Audio.play_sfx("switch_click", null, 2.0)
	await hud.fade(0.85, 0.05, Color.WHITE).finished
	await hud.fade(0.0, 0.6, Color.WHITE).finished


func _on_jamie(_by: Node) -> void:
	if busy:
		return
	if not _gave_cd:
		_gave_cd = true
		await say([
			["Jamie", "Hey. Here. Merry Christmas Eve, or whatever."],
			["", "It's the CD. The song from the car. Jamie burned you a copy and wrote LEO MIX on it in silver marker."],
			["Jamie", "Don't scratch it. And don't tell anyone I gave you something early."],
		])
		return
	var pool := ["These pajamas are itchy. They're also the best pajamas I've ever had.", "Go to bed early and it's Christmas faster. That's science."]
	say([["Jamie", pool[randi() % pool.size()]]])


# --- Step 3-4: Santa's cookies and the reindeer's carrots ---------------

func _on_santa_plate(_by: Node) -> void:
	if busy or step != Step.COOKIES:
		return
	step = Step.CARROTS
	busy = true
	_santa_plate.position = Vector3(-0.3, 0.42, 0.45)
	_santa_plate.enabled = false
	await say([
		["", "Three sugar cookies, a glass of milk, and a note in your best handwriting."],
		["", "'Dear Santa, the robot car please. P.S. Biscuit has been good. Mostly.'"],
	])
	_carrots.enabled = true
	busy = false
	objective("Get carrots for the reindeer")


func _on_carrots(_by: Node) -> void:
	if busy or step != Step.CARROTS:
		return
	step = Step.PORCH_LIGHT
	Decorations.hide(_carrots)
	await say([["Grandma", "Good. Now the most important part. Porch light on, so Santa can find the house."]])
	objective("Turn on the porch light for Santa")


# --- Step 5-6: the porch light, and outside -----------------------------

func _on_switch(_by: Node) -> void:
	if busy:
		return
	if step != Step.PORCH_LIGHT:
		hud.show_memory("Not yet. Grandma says there's an order to these things.", 3.0)
		return
	step = Step.OUTSIDE
	set_porch_light(true)
	await say([["", "Click. Grandma winks at you. That's how Santa finds the house. Every year, since Mom was little."]])
	objective("Put the carrots out on the porch")


func _on_front_door(_by: Node) -> void:
	if busy:
		return
	if step != Step.OUTSIDE:
		hud.show_memory("Cold leaks in around the edges. You can almost hear the snow.", 3.5)
		return
	step = Step.PORCH
	open_front_door()
	var snow_ground := CSGBox3D.new()
	snow_ground.size = Vector3(30, 0.02, 12)
	snow_ground.position = Vector3(-2.0, -0.43, 8.6)
	snow_ground.material = Decorations.mat(Color(0.85, 0.88, 0.95))
	add_child(snow_ground)
	add_child(Decorations.snow(Vector3(-2.1, 3.6, 8.0), Vector3(9.0, 0.05, 6.0), 900))
	# Christmas Eve: every house on the street is lit up in colors.
	for i in street.porch_lights.size():
		street.set_light_color(street.porch_lights[i], Decorations.BULB_COLORS[i % Decorations.BULB_COLORS.size()])
	hud.show_memory("Cold air, and snow coming down slow, like it's got all night.", 4.0)


func _on_porch() -> void:
	if step != Step.PORCH:
		return
	step = Step.END
	busy = true
	objective("")
	await wait(1.0)
	lock(true)
	Audio.stop_music(4.0)
	await player.tween_look_at(STREET_POINT, 2.0).finished
	await say([
		["", "You put the carrots on the porch rail, in a neat little row. Three carrots. Nine reindeer. They'll share."],
		["", "Every house on the street is lit up. Inflatable Santas, light-up reindeer, the Hendersons' blinking star."],
	])
	await wait(1.0)
	Audio.play_sfx("dog_tags", STREET_POINT + Vector3(0, 8, 0), 6.0)
	await wait(1.5)
	await say([["", "Was that sleigh bells? ...Or Biscuit's collar. It was definitely sleigh bells."]])
	jamie.position = Vector3(-2.1, 0.0, 2.35)
	jamie.rotation.y = 0.0
	await player.tween_look_at(Vector3(-2.1, 1.3, 2.35), 1.5).finished
	await say([
		["Jamie", "Bed, kid. He doesn't come if you're awake. Those are the rules."],
		["Jamie", "...Merry Christmas Eve. For real."],
	])
	await hud.fade(1.0, 2.5).finished
	Audio.play_music("ch4_silent_night", 3.0, -10.0)
	await say([
		["", "You lie in bed in your reindeer pajamas, listening for hooves on the roof."],
		["", "You hear somebody eat a cookie in the living room. You decide it was Santa."],
		["Grandma", "Goodnight, honey. See you bright and early."],
	])
	await wait(2.0)
	Audio.stop_music(3.0)
	await wait(1.0)
	go_to_chapter("res://scenes/chapter_6_christmas_morning.tscn")
