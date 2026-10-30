extends HouseChapter
## Chapter 6 — December 25. Christmas morning.
## 5:52 a.m., Jamie's in your doorway → he came! → the stocking, one thing at
## a time → the Mega Robo Racer (batteries not included; Grandma brought
## batteries) → flipping Dad's snowman pancakes → snowball ambush on the porch,
## and you throw one back → afternoon nap in a room full of everybody → Winter Break.

enum Step { WAKE, STOCKING, PRESENT, DAD, FLIP, OUTSIDE, PORCH, THROW, END }

const STREET_POINT := Vector3(-2.1, 0.6, 18.0)
## What's in the stocking, top to toe: [prop, what you think when it comes out].
const STOCKING := [
	["candy", "Candy first. A candy cane, chocolate coins, and the gum that comes rolled up like a tape measure."],
	["yoyo", "A yo-yo. Glow-in-the-dark. You try it once and it just hangs there. You'll practice."],
	["cards", "A pack of trading cards. You open it right there on the floor. No shiny ones. Still good."],
	["toothbrush", "A toothbrush. That was Mom. Santa doesn't do toothbrushes. Everybody knows that."],
	["orange", "And in the toe, like every single year: an orange."],
]
## Where the stocking things land, on the floor under the stocking.
const STOCKING_PILE := Vector3(0.45, 0.0, -1.85)
## Dad's frying pan, on the front burner.
const PAN_AT := Vector3(6.57, 0.975, -0.4)
## Out in the front yard, where Jamie ambushes you from.
const JAMIE_YARD := Vector3(-0.8, -0.43, 6.7)
## What the pancakes become, flip by flip: [size, what happens].
const FLIPS := [
	[0.07, "Up... and down. Mostly in the pan. That's the bottom of the snowman."],
	[0.055, "Too hard. It lands half on the burner. Dad scoops it back like nothing happened."],
	[0.04, "The little one, for the head. You flip it perfect. Dad actually applauds."],
]

var mom: Interactable
var jamie: Interactable
var grandma: Interactable
var _stocking: Interactable
var _present: Interactable
var _daylight := {}
var _pulled := 0
var _pan: Interactable
var _flips := 0
var _pancakes: Array[CSGCylinder3D] = []


func _ready() -> void:
	super._ready()
	Decorations.christmas_tree(self, true)
	_morning()
	_before_dawn()
	tv_screen.channel = "christmas"
	set_porch_light(true)
	Radio.on_kitchen_counter(self, PackedStringArray(["radio_deck_the_halls", "radio_we_wish_you", "radio_wenceslas"]), -14.0)
	# At the stove, to the side of the pan so you can reach it too.
	dad.position = Vector3(6.05, 0.0, -1.05)
	dad.rotation.y = deg_to_rad(60.0)
	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	mom.position = Vector3(1.6, 0.0, -0.4)
	mom.rotation.y = deg_to_rad(-60.0)
	grandma = Figure.person(self, "Grandma", Vector3(0.5, 0.0, 2.05), 180.0, 1.6, Figure.GRANDMA, true)
	# Inside your room by the door, facing the bed, but beside the way out.
	jamie = Figure.person(self, "Jamie", Vector3(3.3, 0.0, -5.3), -37.0, 1.62, Figure.JAMIE)

	_stocking = box_thing("Stocking", Vector3(0.7, 1.1, -2.46), Vector3(0.2, 0.36, 0.06), Color(0.75, 0.1, 0.12), "Stocking")
	_stocking.enabled = false
	dress(_stocking, Props.stocking())
	_present = box_thing("RoboRacer", Decorations.TREE_POS + Vector3(0.65, 0.09, 0.45), Vector3(0.4, 0.18, 0.24),
		Color(0.15, 0.35, 0.8), "Open presents")
	_present.enabled = false
	dress(_present, Props.racer_box(Vector3(0.4, 0.18, 0.24)), -20.0)
	dress(box_thing("SantaPlate", Vector3(-0.3, 0.42, 0.45), Vector3(0.24, 0.02, 0.24), Color(0.95, 0.95, 0.92), "Santa's plate",
		"Crumbs. An empty glass. A note in very fancy handwriting: 'Thanks, Leo! Biscuit has been good. Mostly. —S.'",
		"The fancy handwriting looks a little like Dad's. Santa probably just has nice handwriting."), Props.santa_plate(true))
	_pan = box_thing("Pan", PAN_AT, Vector3(0.3, 0.05, 0.26), Color(0.15, 0.15, 0.17), "Flip the pancake")
	dress(_pan, Props.frying_pan())
	_pan.enabled = false
	_pan.used.connect(_on_pan)
	# Snow piled on the porch rail overnight.
	var rail_snow := Props.snow_pile(Vector3(1.5, 0.05, 0.08))
	rail_snow.position = Vector3(-0.65, 0.88, 4.95)
	add_child(rail_snow)
	Look.upgrade(rail_snow)
	Props.tie_bandana(dog)
	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Snow on everything. Kids already out in brand-new snow boots."
	window.repeat_text = "Somebody's dad is trying out a new sled on the tiniest hill in the world."
	house_text({
		"Clock": ["5:56. Mom said not before six. It's basically six.",
			"Okay, NOW it's six. It's officially morning. You checked."],
		"Fridge": ["Orange juice, eggnog, and the ham from last night. Dad's pancake batter is already in a bowl."],
		"CalendarI": ["DECEMBER 25. The box with three stars. It's finally the day with three stars."],
		"Coats": ["New mittens in your coat pocket. They weren't there last night. Santa's thorough."],
		"KidWindow": ["Fresh snow, and nobody's walked in it yet. The whole street is waiting for somebody to go first."],
	})

	grandma.used.connect(_on_grandma)
	mom.used.connect(_on_mom)
	jamie.used.connect(_on_jamie)
	_stocking.used.connect(_on_stocking)
	_present.used.connect(_on_present)
	dad.used.connect(_on_dad)
	front_door.used.connect(_on_front_door)
	add_trigger(Vector3(2.0, 1.0, -2.2), Vector3(1.2, 2.0, 0.8), _on_see_tree)
	add_trigger(Vector3(-1.55, 1.0, 4.1), Vector3(3.3, 2.0, 1.6), _on_porch)

	player.teleport(Vector3(4.6, 0.05, -7.0), 90.0)
	await open_chapter("December 25", "Christmas Morning")
	hud.show_memory("5:52 a.m. Still dark out. Jamie's standing in your doorway in reindeer pajamas.", 5.0)
	await say([["Jamie", "Hey. Kid. Wake up. ...It's time."]])
	objective("Go see if he came")


## Bright snow light through the windows; the street's porch lights are off
## because it's morning. Except ours: nobody's turned it off yet.
func _morning() -> void:
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = Color(0.35, 0.5, 0.75)
	sky.sky_horizon_color = Color(0.8, 0.83, 0.88)
	sky.ground_horizon_color = Color(0.7, 0.72, 0.76)
	sky.ground_bottom_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_color = Color(0.85, 0.85, 0.95)
	env.ambient_light_energy = 0.7
	env.fog_light_color = Color(0.75, 0.78, 0.85)
	env.fog_density = 0.006
	var sun := lights.get_node("Moon") as DirectionalLight3D
	sun.light_color = Color(1, 0.95, 0.85)
	sun.light_energy = 1.2
	for e in street.porch_lights + [street.far_light]:
		street.kill_light(e, 0.01)
	var snow_ground := CSGBox3D.new()
	snow_ground.size = Vector3(60, 0.02, 30)
	snow_ground.position = Vector3(-2.0, -0.43, 17.6)
	snow_ground.material = Decorations.mat(Color(0.9, 0.92, 0.97))
	add_child(snow_ground)


## 5:52 a.m. is still dark: start from deep blue, with the tree lights doing
## most of the work. The morning above is where the sunrise ends up.
func _before_dawn() -> void:
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	var sun := lights.get_node("Moon") as DirectionalLight3D
	_daylight = {
		"sky_top": sky.sky_top_color, "sky_horizon": sky.sky_horizon_color,
		"ground_horizon": sky.ground_horizon_color, "ground_bottom": sky.ground_bottom_color,
		"fog_color": env.fog_light_color, "ambient_color": env.ambient_light_color,
		"ambient": env.ambient_light_energy, "sun": sun.light_energy, "sun_color": sun.light_color,
		"lamps": {},
	}
	sky.sky_top_color = Color(0.03, 0.04, 0.12)
	sky.sky_horizon_color = Color(0.12, 0.12, 0.25)
	sky.ground_horizon_color = Color(0.1, 0.1, 0.18)
	sky.ground_bottom_color = Color(0.05, 0.05, 0.1)
	env.fog_light_color = Color(0.1, 0.1, 0.2)
	env.ambient_light_energy = 0.08
	env.ambient_light_color = Color(0.4, 0.45, 0.75)
	sun.light_energy = 0.15
	sun.light_color = Color(0.55, 0.65, 1.0)
	# Nobody's turned the lamps on yet; the tree and the TV are the light.
	for l in lights.get_children():
		if l is OmniLight3D and not l.name in ["TVGlow", "PorchLight"]:
			_daylight.lamps[l] = (l as OmniLight3D).light_energy
			(l as OmniLight3D).light_energy *= 0.3


## While the presents get opened, the sun comes up over the snow.
func _sunrise(time := 25.0) -> void:
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	var sun := lights.get_node("Moon") as DirectionalLight3D
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	t.tween_property(sky, "sky_top_color", _daylight.sky_top, time)
	t.tween_property(sky, "sky_horizon_color", _daylight.sky_horizon, time)
	t.tween_property(env, "ambient_light_energy", _daylight.ambient, time)
	t.tween_property(sun, "light_energy", _daylight.sun, time)
	t.tween_property(sun, "light_color", _daylight.sun_color, time)
	t.tween_property(sky, "ground_horizon_color", _daylight.ground_horizon, time)
	t.tween_property(sky, "ground_bottom_color", _daylight.ground_bottom, time)
	t.tween_property(env, "fog_light_color", _daylight.fog_color, time)
	t.tween_property(env, "ambient_light_color", _daylight.ambient_color, time)
	for l in _daylight.lamps:
		t.tween_property(l, "light_energy", _daylight.lamps[l], time)
	# The painted-glass windows in the other rooms catch up when it's full day.
	get_tree().create_timer(time).timeout.connect(set_window_daylight.bind(true))


# --- Step 0: he came ----------------------------------------------------

func _on_see_tree() -> void:
	if step != Step.WAKE:
		return
	step = Step.STOCKING
	busy = true
	jamie.position = Vector3(1.4, 0.0, -1.6)
	jamie.rotation.y = deg_to_rad(-120.0)
	await say([
		["", "He came. The cookies are gone. There's a bite out of the note. The stockings are full."],
		["Jamie", "HE CAME. Mom! Dad! He came!"],
		["Dad", "Coffee first. That's the law."],
		["Mom", "Oh, let them go. It's Christmas."],
	])
	_stocking.enabled = true
	busy = false
	objective("Open your stocking")


# --- Step 1-2: stocking and presents ------------------------------------

## One thing out of the stocking per use, onto the floor, top to toe.
func _on_stocking(_by: Node) -> void:
	if busy or step != Step.STOCKING:
		return
	busy = true
	var item: Array = STOCKING[_pulled]
	var prop := Props.stocking_item(item[0])
	prop.position = STOCKING_PILE + Vector3(_pulled * 0.12, 0, (_pulled % 2) * 0.08)
	prop.rotation_degrees.y = randf_range(-30, 30)
	prop.scale = Vector3.ONE * 0.2
	add_child(prop)
	Look.upgrade(prop)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(prop, "scale", Vector3.ONE, 0.35)
	Audio.play_sfx("candy_rustle", _stocking, -6.0, 0.1)
	_pulled += 1
	if _pulled < STOCKING.size():
		hud.show_memory(item[1], 4.0)
		await wait(0.6)
		busy = false
		return
	step = Step.PRESENT
	_stocking.enabled = false
	dress(_stocking, Props.stocking(false))
	await say([
		["", item[1]],
		["Jamie", "Every year, the orange. Who started the orange?"],
		["Grandma", "I did. Every year. You're welcome."],
	])
	_present.enabled = true
	busy = false
	objective("Open presents")


func _on_present(_by: Node) -> void:
	if busy or step != Step.PRESENT:
		return
	step = Step.DAD
	busy = true
	_sunrise()
	Audio.play_sfx("candy_rustle", _present, -2.0)
	await say([
		["", "The Mega Robo Racer. The one you circled in the catalog. Three times. In three markers."],
		["", "On the side of the box, in tiny letters: BATTERIES NOT INCLUDED."],
		["Grandma", "I brought batteries. I always bring batteries."],
		["", "She pulls a whole pack of double-As out of her purse like a magician."],
		["Jamie", "Okay. That's actually legendary."],
		["Mom", "Hold it up! Hold it up for the picture!"],
	])
	await _flash("The Mega Robo Racer!")
	dress(_present, Props.robo_racer(), -20.0)
	_present.prompt = "Mega Robo Racer"
	_present.memory_text = "It climbs the couch. It climbs Biscuit. Biscuit does not want it to climb Biscuit."
	_present.repeat_text = "Vrrrrrr. Best present in the history of presents."
	_present.enabled = true
	busy = false
	objective("Show Dad the Robo Racer")


func _flash(caption: String, stamp := "'03 12 25") -> void:
	await Game.take_photo(caption, stamp)
	Audio.play_sfx("switch_click", null, 2.0)
	await hud.fade(0.85, 0.05, Color.WHITE).finished
	await hud.fade(0.0, 0.6, Color.WHITE).finished


# --- Step 3: Dad and the snow blobs -------------------------------------

func _on_dad(_by: Node) -> void:
	if busy:
		return
	if step == Step.FLIP:
		say([["Dad", "Wrist, not arm. It's all in the wrist. That's what my dad told me, and look how I turned out."]])
		return
	if step != Step.DAD:
		say([["Dad", "Pancakes in a minute, bud. Snowman pancakes. It's a whole thing."]])
		return
	step = Step.FLIP
	busy = true
	await say([
		["Dad", "Merry Christmas, bud! Snowman pancakes. You're on flipping. I'm on supervising."],
	])
	_pan_pancake()
	_pan.enabled = true
	busy = false
	objective("Flip the snowman pancakes (0 of 3)")


## A fresh pancake in the pan, the size of the next part of the snowman.
func _pan_pancake() -> void:
	var p := Props.pancake(_pan, Vector3(0, 0.0, 0), FLIPS[_flips][0], 0.1)
	p.position.y = 0.012
	_pancakes.append(p)


func _on_pan(_by: Node) -> void:
	if busy or step != Step.FLIP:
		return
	busy = true
	var p: CSGCylinder3D = _pancakes.back()
	# Up, over, and (mostly) back down.
	Audio.play_sfx("candy_rustle", _pan, -12.0, 0.4)
	var t := create_tween()
	t.tween_property(p, "position:y", 0.3, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(p, "rotation:x", PI, 0.5)
	t.tween_property(p, "position", Vector3(0.06 if _flips == 1 else 0.0, 0.012, 0.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	(p.material as StandardMaterial3D).albedo_color = Color(0.82, 0.6, 0.32)
	hud.show_memory(FLIPS[_flips][1], 4.0)
	_flips += 1
	if _flips == 2:
		await say([["Dad", "Five-second rule. Christmas rules. Nobody saw that."]])
	if _flips < FLIPS.size():
		await wait(1.0)
		_pan_pancake()
		busy = false
		objective("Flip the snowman pancakes (%d of 3)" % _flips)
		return
	_pan.enabled = false
	objective("")
	await wait(1.0)
	_serve_pancakes()
	await say([
		["Dad", "Look at that. A snowman. ...A snow blob. Three snow blobs."],
		["", "They taste perfect. You eat all three snow blobs, and the Robo Racer climbs the syrup bottle."],
		["Dad", "Hey, the porch light's still on from last night. Want me to turn it off?"],
		["", "You shake your head. Santa might still be in the neighborhood. You never know."],
		["Dad", "Good thinking. Leave it on. Now go get your boots, Jamie's already outside."],
	])
	step = Step.OUTSIDE
	jamie.position = JAMIE_YARD
	jamie.rotation.y = deg_to_rad(180.0)
	busy = false
	objective("Go out in the snow")


## The three pancakes, stacked into a (lumpy) snowman on a plate at the table.
func _serve_pancakes() -> void:
	var plate := Node3D.new()
	plate.position = Vector3(4.6, 0.755, 0.15)
	add_child(plate)
	Props.cyl(plate, 0.13, 0.012, Vector3(0, 0.006, 0), Props.WHITE)
	for i in _pancakes.size():
		var p := _pancakes[i]
		p.get_parent().remove_child(p)
		plate.add_child(p)
		p.rotation = Vector3.ZERO
		p.position = Vector3(0, 0.018 + i * 0.002, -0.07 + i * 0.075 - (0.01 if i == 2 else 0.0))
	# Chocolate chip eyes and a syrup puddle.
	for side in [-1, 1]:
		Props.ball(plate, 0.006, Vector3(side * 0.012, 0.03, 0.08), Color(0.2, 0.1, 0.05))
	Props.cyl(plate, 0.05, 0.003, Vector3(0.05, 0.014, -0.03), Color(0.55, 0.3, 0.08))
	Look.upgrade(plate)


func _on_grandma(_by: Node) -> void:
	if busy:
		return
	var pool := ["Merry Christmas, honey. Did he bring the robot car? I knew it.",
		"Go play. I'll be right here with my coffee and the fudge. Supervising.",
		"Best Christmas morning. You say that every year, and every year it's true."]
	say([["Grandma", pool[randi() % pool.size()]]])


func _on_mom(_by: Node) -> void:
	if busy:
		return
	var pool := ["Merry Christmas, sweetie. Look at that tree.", "One more picture! Okay, two more pictures."]
	say([["Mom", pool[randi() % pool.size()]]])


func _on_jamie(_by: Node) -> void:
	if busy:
		return
	if step == Step.THROW:
		_on_throw()
		return
	var pool := ["I got the game! The new one! Player two is yours later.", "Did you see what Biscuit got? A squeaky hamburger. He's never been happier."]
	say([["Jamie", pool[randi() % pool.size()]]])


# --- Step 4: snow -------------------------------------------------------

func _on_front_door(_by: Node) -> void:
	if busy or step != Step.OUTSIDE:
		return
	step = Step.PORCH
	open_front_door()


func _on_porch() -> void:
	if step != Step.PORCH:
		return
	step = Step.THROW
	busy = true
	objective("")
	await wait(1.0)
	lock(true)
	await player.tween_look_at(STREET_POINT, 2.0).finished
	await say([["", "The street's white and bright and loud. Kids in new boots. Somebody's dad on a new sled, losing."]])
	await player.tween_look_at(JAMIE_YARD + Vector3(0, 1.3, 0), 1.0).finished
	await say([["Jamie", "Hey, kid."]])
	# Splat.
	Audio.play_sfx("candy_rustle", player, -2.0, 0.3)
	await hud.fade(0.7, 0.05, Color(0.95, 0.97, 1.0)).finished
	await hud.fade(0.0, 0.8, Color(0.95, 0.97, 1.0)).finished
	await say([
		["", "A snowball hits you right in the new coat. Jamie is already laughing."],
		["Jamie", "Merry Christmas! That was your present from me. Also the CD. But mostly the snowball."],
		["", "You scoop a handful of snow off the porch rail and pack it tight. Revenge."],
	])
	# Jamie's out in the yard: let Leo reach that far, just for this.
	player.ray.target_position = Vector3(0, 0, -10.0)
	jamie.prompt = "Throw the snowball"
	lock(false)
	busy = false
	objective("Throw one back at Jamie")


## The snowball arcs from Leo's hand to Jamie's hood, and bursts.
func _throw_snowball() -> void:
	var ball := Props.snowball()
	add_child(ball)
	var from: Vector3 = player.camera.global_position + player.camera.global_transform.basis * Vector3(0.15, -0.15, -0.3)
	var to: Vector3 = jamie.global_position + Vector3(0, 1.45, 0)
	ball.global_position = from
	var t := create_tween()
	t.tween_method(func(a: float) -> void:
		ball.global_position = from.lerp(to, a) + Vector3(0, sin(a * PI) * 0.6, 0), 0.0, 1.0, 0.6)
	await t.finished
	ball.queue_free()
	Audio.play_sfx("candy_rustle", jamie, 0.0, 0.3)
	for i in 8:
		var bit := Props.ball(self, 0.015, to, Props.SNOW)
		var dir := Vector3(randf_range(-1, 1), randf_range(0.2, 1), randf_range(-1, 1)).normalized() * 0.35
		var b := create_tween()
		b.tween_property(bit, "global_position", to + dir, 0.4).set_ease(Tween.EASE_OUT)
		b.tween_callback(bit.queue_free)


func _on_throw() -> void:
	step = Step.END
	busy = true
	objective("")
	lock(true)
	player.ray.target_position = Vector3(0, 0, -1.6)
	jamie.prompt = "Talk to Jamie"
	await _throw_snowball()
	await say([
		["Jamie", "HEY! Right in the hood! That's going down my back!"],
		["", "Biscuit tries to eat every snowball. Grandma cheers for everyone from the doorway, in her robe."],
		["Grandma", "Picture! Everybody stay right there!"],
	])
	await _flash("Snowball ambush")
	await wait(1.0)
	await hud.fade(1.0, 3.0).finished
	await say([["", "That afternoon you fall asleep on the couch in your reindeer pajamas, a Christmas movie on, Robo Racer on your chest, everybody you love in one room."]])
	await wait(2.0)
	go_to_chapter("res://scenes/winter_break_days.tscn")
