extends HouseChapter
## Christmas Eve — December 24.
## Afternoon, in any order: decorate sugar cookies with Mom, wrap Grandma's
## present with Dad, find the one dead bulb with Jamie so the tree lights up →
## evening: Grandma arrives with fudge → open one present (matching reindeer
## pajamas, everybody) → the disposable-camera family picture → dinner and the
## claymation special → cookies and milk for Santa → carrots for the reindeer →
## porch light on so Santa can find the house → out on the porch in the snow →
## bed, listening for hooves → the dream: the long hallway strung with
## Christmas lights, Biscuit at the glowing door → Christmas morning.
## (The cookies, the tree lights and the toy catalog came from the old
## "Home for Winter Break".)

enum Step { DAY, GRANDMA, PRESENT, PICTURE, COOKIES, CARROTS, PORCH_LIGHT, OUTSIDE, PORCH, DREAM, END }

const STREET_POINT := Vector3(-2.1, 0.6, 18.0)
## Which of the bulbs you can check is the dead one.
const DEAD_CHECK := 3
## The dream: Chapter 1's long hallway, and where Biscuit waits by its door.
const DREAM_DOG := Vector3(2.0, 0.05, -24.4)

var mom: Interactable
var jamie: Interactable
var grandma: Interactable
var _present: Interactable
var _santa_plate: Interactable
var _carrots: Interactable
var _gave_cd := false
var _sugar_cookies: Interactable
var _wrapping: Interactable
var _wrapped: Interactable
var _bulb_mats: Array[StandardMaterial3D] = []
var _checks: Array[Interactable] = []
var _tree_glow: OmniLight3D
var _day_done := {}
var _hall_end: Node3D
var _dream_dog_greeted := false
var _window: Interactable
var _fudge: Interactable
var _bulb_hunt := false
var _night_look := {}


func _ready() -> void:
	super._ready()
	# The tree's up, but one dead bulb has the whole string out.
	var tree := Decorations.christmas_tree(self, false, true)
	_bulb_mats = tree.bulbs
	_checks = tree.checks
	_tree_glow = tree.glow
	for i in _checks.size():
		_checks[i].used.connect(_on_bulb.bind(i))
	tv_screen.channel = "winter"
	set_porch_light(false)
	_afternoon()
	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	# Afternoon: Mom baking, Dad wrapping at the coffee table, Jamie at the tree.
	mom.position = Vector3(6.0, 0.0, 0.9)
	mom.rotation.y = deg_to_rad(90.0)
	dad.position = Vector3(0.9, 0.0, 1.1)
	dad.rotation.y = deg_to_rad(-120.0)
	jamie = Figure.person(self, "Jamie", Vector3(-1.5, 0.0, 0.35), -140.0, 1.62, Figure.JAMIE)
	grandma = Figure.person(self, "Grandma", Vector3(0.9, 0.0, 1.0), -150.0, 1.6, Figure.GRANDMA)
	stash(grandma)
	_sugar_cookies = box_thing("SugarCookies", Vector3(6.55, 0.95, 1.5), Vector3(0.4, 0.04, 0.3), Color(0.9, 0.75, 0.5), "Decorate cookies")
	_wrapping = box_thing("Wrapping", Vector3(-0.1, 0.45, 0.4), Vector3(0.5, 0.08, 0.35), Color(0.15, 0.45, 0.25), "Help wrap Grandma's present")
	_wrapped = box_thing("WrappedPresent", Decorations.TREE_POS + Vector3(-0.5, 0.11, 0.7), Vector3(0.3, 0.2, 0.25),
		Color(0.15, 0.45, 0.25), "Grandma's present",
		"'TO GRANDMA, FROM LEO.' The corners are rustic. Dad's word.",
		"You shake it. It doesn't rattle. Good. The tape is holding everything together.")
	_wrapped.visible = false
	_wrapped.enabled = false
	_sugar_cookies.used.connect(_on_sugar_cookies)
	_wrapping.used.connect(_on_wrapping)
	box_thing("Catalog", Vector3(0.15, 0.42, 0.45), Vector3(0.24, 0.02, 0.3), Color(0.85, 0.2, 0.2), "Toy catalog",
		"The big toy catalog. You've circled the Mega Robo Racer three times, in three different markers.",
		"Page 47 is folded down. Page 47 is everything.")
	box_thing("Advent", Vector3(6.27, 1.45, -1.55), Vector3(0.03, 0.32, 0.24), Color(0.7, 0.12, 0.15), "Advent calendar",
		"Door 24, the last one. A chocolate Santa. Jamie hasn't eaten it. A Christmas miracle.",
		"All twenty-four doors open. It looks like a little building with every light on.")

	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Kids pulling sleds up the street. The Hendersons' inflatable Santa keeps bowing. It's kind of polite."
	window.repeat_text = "It's getting dark already, and it's only four. Christmas Eve dark."
	_window = window
	_fudge = box_thing("Fudge", Vector3(4.6, 0.8, 0.15), Vector3(0.22, 0.06, 0.22), Color(0.2, 0.35, 0.25), "Grandma's fudge tin",
		"The good tin, with the Scottish dog on the lid. You take two pieces. Grandma pretends not to see.",
		"The tin is half empty. Dad has a chocolate thumbprint on his sweater.")
	stash(_fudge)
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
	dad.set_meta("mute_chatter", true) # busy wrapping until the evening
	add_trigger(Vector3(-1.55, 1.0, 4.1), Vector3(3.3, 2.0, 1.6), _on_porch)

	Audio.make_loop("wind", $Exterior/Ambience, -12.0)
	Audio.play_music("ch4_silent_night", 4.0, -8.0)
	await open_chapter("December 24", "Christmas Eve")
	hud.show_memory("Christmas Eve. The tree's up, the presents are under it, and the whole house smells like sugar cookies.", 5.5)
	await wait(3.0)
	_day_objective()


# --- Afternoon: cookies, wrapping, the tree lights ------------------------

## Late, snowy December afternoon light. Remembers the night look for later.
func _afternoon() -> void:
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	var sun := lights.get_node("Moon") as DirectionalLight3D
	_night_look = {
		"sky_top": sky.sky_top_color, "sky_horizon": sky.sky_horizon_color,
		"ground_horizon": sky.ground_horizon_color, "ground_bottom": sky.ground_bottom_color,
		"ambient": env.ambient_light_color, "ambient_energy": env.ambient_light_energy,
		"fog_color": env.fog_light_color, "fog": env.fog_density,
		"sun_color": sun.light_color, "sun_energy": sun.light_energy,
	}
	sky.sky_top_color = Color(0.5, 0.58, 0.72)
	sky.sky_horizon_color = Color(0.9, 0.78, 0.65)
	sky.ground_horizon_color = Color(0.75, 0.75, 0.8)
	sky.ground_bottom_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_color = Color(0.9, 0.86, 0.85)
	env.ambient_light_energy = 0.6
	env.fog_light_color = Color(0.8, 0.78, 0.8)
	env.fog_density = 0.008
	sun.light_color = Color(1, 0.85, 0.65)
	sun.light_energy = 0.8
	for e in street.porch_lights + [street.far_light]:
		street.kill_light(e, 0.01)
	set_window_daylight(true)


## Back to Christmas Eve night: the original sky, lights and windows.
func _nightfall() -> void:
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	var sun := lights.get_node("Moon") as DirectionalLight3D
	sky.sky_top_color = _night_look.sky_top
	sky.sky_horizon_color = _night_look.sky_horizon
	sky.ground_horizon_color = _night_look.ground_horizon
	sky.ground_bottom_color = _night_look.ground_bottom
	env.ambient_light_color = _night_look.ambient
	env.ambient_light_energy = _night_look.ambient_energy
	env.fog_light_color = _night_look.fog_color
	env.fog_density = _night_look.fog
	sun.light_color = _night_look.sun_color
	sun.light_energy = _night_look.sun_energy
	street.restore_lights()
	set_window_daylight(false)


func _day_objective() -> void:
	objective("Help get ready for tonight (%d of 3)" % _day_done.size())


func _day_task_done(id: String) -> void:
	_day_done[id] = true
	if _day_done.size() < 3:
		_day_objective()
		return
	objective("")
	await wait(2.0)
	await _evening()


func _on_sugar_cookies(_by: Node) -> void:
	if busy or step != Step.DAY:
		return
	busy = true
	_sugar_cookies.enabled = false
	await say([
		["", "Sugar cookies, still warm. You do a reindeer, a snowman, and one that's just all sprinkles."],
		["Mom", "That one's my favorite. Don't tell the reindeer."],
		["", "You eat one broken star. Quality control."],
		["Mom", "Save the three best ones. Those are for Santa."],
	])
	busy = false
	_day_task_done("cookies")


func _on_wrapping(_by: Node) -> void:
	if busy or step != Step.DAY:
		return
	busy = true
	_wrapping.enabled = false
	await say([
		["Dad", "Grandma's present. You're on tape. I'm on corners. Corners are an art."],
		["", "Too much tape. Way too much tape. The paper tears, so you tape the tear. Biscuit lies down on the leftover paper and won't move."],
		["Dad", "Look at that. Rustic. She's going to love it."],
		["", "You write the tag yourself: TO GRANDMA, FROM LEO. It goes under the tree with the others."],
	])
	Decorations.hide(_wrapping)
	_wrapped.visible = true
	_wrapped.enabled = true
	busy = false
	_day_task_done("wrapping")


# --- Evening -------------------------------------------------------------

## The afternoon goes dark. Grandma arrives; everyone takes their places.
func _evening() -> void:
	busy = true
	lock(true)
	await hud.fade(1.0, 2.0).finished
	hud.show_line("", "It gets dark at five. At six, Grandma's car pulls in, honking twice like always.")
	await wait(3.5)
	hud.clear_line()
	_nightfall()
	unstash(grandma, self)
	unstash(_fudge, self)
	dad.position = Vector3(6.0, 0.0, -0.6)
	dad.rotation.y = deg_to_rad(90.0)
	dad.remove_meta("mute_chatter")
	mom.position = Vector3(1.6, 0.0, -0.4)
	mom.rotation.y = deg_to_rad(-60.0)
	jamie.position = Vector3(0.9, 0.0, -1.3)
	jamie.rotation.y = deg_to_rad(20.0)
	_window.memory_text = "Snow on the porch rail. Every house on the street is lit up for Christmas Eve."
	_window.repeat_text = "The Hendersons' giant star is blinking out of rhythm. It's beautiful anyway."
	player.teleport(Vector3(-0.6, 0.05, 1.6), 30.0)
	step = Step.GRANDMA
	await wait(0.5)
	await hud.fade(0.0, 2.0).finished
	lock(false)
	busy = false
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
	])
	# Christmas Eve dinner, then everybody on the couch.
	lock(true)
	await hud.fade(1.0, 1.5).finished
	hud.show_line("", "Christmas Eve dinner. Ham, Grandma's rolls, and the green Jell-O nobody eats but everybody wants on the table.")
	await wait(4.0)
	hud.show_line("", "Then the claymation special, all of you on the couch. Jamie says it's for babies and doesn't look away once. Grandma's asleep by the misfit toys.")
	await wait(4.5)
	hud.clear_line()
	await hud.fade(0.0, 1.5).finished
	lock(false)
	await say([
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
	if step == Step.DAY and not _day_done.has("tree"):
		if _bulb_hunt:
			say([["Jamie", "Check them one at a time. That's the only way. That's the law of Christmas lights."]])
			return
		_bulb_hunt = true
		await say([
			["Jamie", "Okay. Dad quit. It's up to us."],
			["Dad", "I did not quit! I'm wrapping. It's a strategic break."],
			["Jamie", "One bulb's dead, so the whole string's dead. It's the stupidest thing ever invented. Help me find it."],
		])
		for c in _checks:
			c.enabled = true
		return
	if step == Step.DAY:
		say([["Jamie", "Best tree we've ever had. Don't tell Dad I said that."]])
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


func _on_bulb(_by: Node, index: int) -> void:
	if busy or step != Step.DAY or not _bulb_hunt:
		return
	if index != DEAD_CHECK:
		var pool := ["Not this one.", "This one's fine. Jamie sighs, very dramatically.", "Nope. You twist it back in."]
		hud.show_memory(pool[index % pool.size()], 2.5)
		_checks[index].enabled = false
		return
	busy = true
	for c in _checks:
		c.enabled = false
	hud.show_memory("This one's loose and dark. You twist in a new one from the box.", 3.0)
	await wait(1.5)
	Audio.play_sfx("switch_click", _tree_glow, -4.0)
	Decorations.light_tree({ "bulbs": _bulb_mats, "glow": _tree_glow }, true)
	await say([
		["Jamie", "...YES. See? Just the one."],
		["", "The whole tree lights up at once. Red, green, blue, gold. Dad cheers from the couch like it's a touchdown."],
		["Dad", "THAT'S what I'm talking about!"],
	])
	busy = false
	_day_task_done("tree")


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
	await _enter_dream()


# --- Step 7: the dream ---------------------------------------------------

## The hallway from Halloween, longer than it should be, strung with Christmas
## lights all the way down. Biscuit waits at the warm door at the end.
func _enter_dream() -> void:
	step = Step.DREAM
	unstash(_dream_hall, self)
	_hall_end = $House/Hallway/HallEnd
	stash(_hall_end)
	string_dream_lights(_dream_hall)
	var door := _dream_hall.get_node("DreamDoor") as Interactable
	door.prompt = "Open the door"
	door.used.connect(_on_dream_door)
	tv_screen.channel = "dream"
	Audio.set_dreaming(true)
	Audio.play_music("dream_hall", 3.0)
	for n in ["Lamp", "KitchenLight", "HallLight", "PorchLight"]:
		var l := lights.get_node_or_null(n) as OmniLight3D
		if l:
			l.light_energy = 0.0
	for n in [mom, dad, jamie, grandma]:
		(n as Node3D).visible = false
		(n as Interactable).collision_layer = 0
	env.ambient_light_color = Color(0.3, 0.25, 0.5)
	env.ambient_light_energy = 0.5
	env.background_color = Color(0.03, 0.02, 0.07)
	env.fog_light_color = Color(0.2, 0.15, 0.35)
	env.fog_density = 0.04
	# Biscuit, still in his reindeer bandana.
	dog.set_active(true)
	dog.global_position = DREAM_DOG
	dog.go_to([DREAM_DOG], false, DREAM_DOG + Vector3(0, 0, 4.0))
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)
	_bandana(dog)
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
	hud.show_memory("The hallway is longer than it should be again. Somebody strung Christmas lights all the way down it.", 5.0)


## A little red triangle of a bandana on Biscuit's collar.
func _bandana(d: Dog) -> void:
	var cloth := CSGPolygon3D.new()
	cloth.polygon = PackedVector2Array([Vector2(-0.09, 0), Vector2(0.09, 0), Vector2(0, -0.12)])
	cloth.depth = 0.01
	cloth.position = Vector3(0, 0.38, -0.33)
	cloth.material = Decorations.mat(Color(0.75, 0.1, 0.12))
	d.add_child(cloth)


func _process(delta: float) -> void:
	super._process(delta)
	if step == Step.DREAM and not _dream_dog_greeted \
			and player.global_position.distance_to(dog.global_position) < 6.0:
		_dream_dog_greeted = true
		dog.greet()
		hud.show_memory("Biscuit, in his reindeer bandana, tail going like he's been waiting up for Santa too.", 5.0)


func _on_dream_door(_by: Node) -> void:
	if busy or step != Step.DREAM:
		return
	step = Step.END
	busy = true
	lock(true)
	await say([["", "Light comes around the edges of the door, red and green and gold. On the other side, it's already morning."]])
	await hud.fade(1.0, 2.5, Color(1.0, 0.94, 0.82)).finished
	await hud.fade(1.0, 1.0, Color.BLACK).finished
	Audio.stop_music(2.0)
	Audio.set_dreaming(false)
	await wait(1.0)
	go_to_chapter("res://scenes/chapter_6_christmas_morning.tscn")


func _exit_tree() -> void:
	super._exit_tree()
	free_stashed([grandma, _fudge, _hall_end])
