extends Chapter
## Chapter 1 — October 31. Halloween night.
## Sort candy → candy tax (overhear the grown-ups) → porch light off →
## show Jamie your haul → bedtime → the dream hallway → Grandma's kitchen →
## the 2 a.m. interlude (scripts/interlude_porch_light.gd) → Chapter 2.

enum Step { SORT_CANDY, CANDY_TAX, PORCH_LIGHT, SHOW_JAMIE, TALK_JAMIE, HANG_OUT, BEDTIME, DREAM }

@onready var env: Environment = $WorldEnvironment.environment
@onready var lights: Node3D = $Lights
@onready var story: Node3D = $Story
@onready var hall_end: Node3D = $House/Hallway/HallEnd
@onready var hallway: Node3D = $House/Hallway
@onready var jamie_room: Node3D = $House/JamieRoom
@onready var jamie_full: Node3D = $House/JamieRoom/JamieRoomFull
@onready var jamie_dream: Node3D = $House/JamieRoom/JamieRoomDream
@onready var dream_hall: Node3D = $DreamHall
@onready var jamie_door: Interactable = $House/JamieRoom/JamieDoor
@onready var jamie: Interactable = $House/JamieRoom/JamieRoomFull/Things/Jamie
@onready var jamie_pc: Interactable = $House/JamieRoom/JamieRoomFull/Things/JamieComputer
@onready var mom: Interactable = $Story/Mom
@onready var dad: Interactable = $Story/Dad
@onready var candy: Interactable = $Story/Candy
@onready var porch_switch: Interactable = $Story/PorchSwitch
@onready var porch_pane_on: Node3D = $Story/PorchPaneOn
@onready var overhear: Trigger = $Story/KitchenOverhear
@onready var bed: Interactable = $House/KidRoom/Things/Bed
@onready var dream_door: Interactable = $DreamHall/DreamDoor
@onready var tv_screen: TvScreen = $House/LivingRoom/Things/TV/ScreenFeed
@onready var dog: Dog = $Biscuit
@onready var street: Street = $Street
@onready var porch_bulb: CSGShape3D = $Exterior/PorchLamp
@onready var interlude: Node = $Interlude

var _knocks := 0
var _mom_i := 0
var _dad_i := 0
var _flicker_t := 0.0
var _tv_energy := 0.0
var _crickets: AudioStreamPlayer3D


func _ready() -> void:
	super._ready()
	_tv_energy = (lights.get_node("TVGlow") as OmniLight3D).light_energy
	stash(dream_hall)
	stash(jamie_dream)

	candy.used.connect(_on_candy)
	overhear.player_entered.connect(_on_overhear)
	mom.used.connect(_on_mom)
	dad.used.connect(_on_dad)
	porch_switch.used.connect(_on_porch_switch)
	jamie_door.used.connect(_on_jamie_door)
	jamie.used.connect(_on_jamie)
	jamie_pc.used.connect(_on_jamie_pc)
	bed.used.connect(_on_bed)
	dream_door.used.connect(_on_dream_door)
	dog.player = player

	Audio.make_loop("clock_tick", $House/LivingRoom/Things/Clock, -14.0)
	Audio.make_loop("room_tone", $House/Kitchen/Things/Fridge, -10.0)
	_crickets = Audio.make_loop("crickets", $Exterior/Ambience, -8.0) as AudioStreamPlayer3D
	_crickets.unit_size = 8.0
	Audio.make_loop("wind", $Exterior/Ambience, -16.0)
	Audio.play_music("ch1_living_room", 4.0)

	await open_chapter("October 31", "Halloween")
	hud.show_memory("Home from trick-or-treating. Your pillowcase is so heavy the handle's stretched out.", 5.0)
	await wait(2.5)
	objective("Sort your candy")


func _exit_tree() -> void:
	free_stashed([dream_hall, jamie_dream, jamie_full, hall_end])


func _process(delta: float) -> void:
	super._process(delta)
	_flicker_t -= delta
	if _flicker_t > 0.0:
		return
	_flicker_t = randf_range(0.05, 0.22)
	var tv := lights.get_node("TVGlow") as OmniLight3D
	var dreaming := step == Step.DREAM
	var on := 0.0 if tv_screen.channel == "off" else 1.0
	tv.light_energy = _tv_energy * on * (0.6 if dreaming else 1.0) * randf_range(0.7, 1.15)
	tv.light_color = tv.light_color.lerp(tv_screen.light_color(), 0.5)
	var pumpkin := lights.get_node("PumpkinLight") as OmniLight3D
	pumpkin.light_energy = 0.6 * randf_range(0.6, 1.2)


# --- Step 0: sort candy -------------------------------------------------

func _on_candy(_by: Node) -> void:
	if interlude.active:
		return
	if step != Step.SORT_CANDY:
		return
	step = Step.CANDY_TAX
	await wait(4.0)
	say([["Mom (kitchen)", "Hey! Don't forget the candy tax!"]])
	objective("Pay the candy tax")
	overhear.active = true


# --- Step 1: overhear, then candy tax ----------------------------------

func _on_overhear() -> void:
	await say([
		["Mom", "...okay, but if we hide the full-size bars, they'll never know."],
		["Dad", "They'll know. They count. Leo counts everything."],
		["Mom", "Then we call it the candy tax. Rules are rules."],
		["Dad", "Hey! There's the big winner. How'd we do?"],
	])


func _on_mom(_by: Node) -> void:
	if interlude.active:
		return
	if busy:
		return
	if step == Step.CANDY_TAX:
		step = Step.PORCH_LIGHT
		await say([
			["", "You hold out the pillowcase."],
			["Mom", "Candy tax. Rules are rules."],
			["Dad", "Ooh, the peanut butter cups. Good kid."],
			["Mom", "Can you flip the porch light off for me, hon? We're done for the night."],
		])
		objective("Turn off the porch light")
		return
	var lines := {
		Step.SORT_CANDY: ["Sort your candy first. Then we'll talk taxes.", "Did you say thank you at every house?"],
		Step.PORCH_LIGHT: ["Porch light, please. By the front door."],
		Step.SHOW_JAMIE: ["Go show Jamie. Then bed.", "Brush your teeth. I mean it."],
	}
	var pool: Array = lines.get(step, ["Bed. Now. I love you.", "Did you brush your teeth?"])
	say([["Mom", pool[_mom_i % pool.size()]]])
	_mom_i += 1


func _on_dad(_by: Node) -> void:
	if interlude.active:
		return
	if busy:
		return
	var pool := [
		"Best costume on the block. I'm not biased.",
		"Did the house with the fog machine scare you? It scared me.",
		"Don't tell Mom, but I already ate two of your peanut butter cups.",
		"Next year I'm going as a ghost. Same sheet as always.",
	]
	say([["Dad", pool[_dad_i % pool.size()]]])
	_dad_i += 1


# --- Step 2: porch light ------------------------------------------------

func _on_porch_switch(_by: Node) -> void:
	if interlude.active:
		return
	if busy:
		return
	if step != Step.PORCH_LIGHT:
		hud.show_memory("The porch light stays on until the very last trick-or-treater. That's the rule.", 4.0)
		return
	step = Step.SHOW_JAMIE
	busy = true
	var porch := lights.get_node("PorchLight") as OmniLight3D
	create_tween().tween_property(porch, "light_energy", 0.0, 0.15)
	(porch_bulb.material as StandardMaterial3D).emission_energy_multiplier = 0.0
	porch_pane_on.visible = false
	street.lights_out_one_by_one()
	porch_switch.prompt = "Porch light (off)"
	hud.show_memory("Click. Up and down the street, the porch lights start going off, one by one.", 5.0)
	await wait(5.0)
	await say([["Mom (kitchen)", "Thanks, hon! Go show Jamie your haul. Then it's bedtime."]])
	busy = false
	objective("Show Jamie your haul")


# --- Steps 3-5: Jamie ---------------------------------------------------

func _on_jamie_door(_by: Node) -> void:
	if interlude.active:
		return
	if busy:
		return
	if step != Step.SHOW_JAMIE:
		var muffled := [
			"Music through the door, a lot of guitar. Jamie yells 'busy!' and turns it up.",
			"You sit against the door for a while. You can hear them laughing at something on the computer.",
		]
		hud.show_memory(muffled[_knocks % muffled.size()], 5.0)
		_knocks += 1
		return
	step = Step.TALK_JAMIE
	busy = true
	await say([
		["Jamie", "...What."],
		["", "You hold up the full-size bar."],
		["Jamie", "...Fine. Come in."],
	])
	jamie_door.enabled = false
	await swing_door(jamie_door, 95.0)
	busy = false
	objective("Talk to Jamie")


func _on_jamie(_by: Node) -> void:
	if interlude.active:
		return
	if busy:
		return
	match step:
		Step.TALK_JAMIE:
			step = Step.HANG_OUT
			await say([
				["Jamie", "Okay. That's actually a really good haul."],
				["Jamie", "Trade you two of mine for the big one."],
				["", "It's a terrible trade. You make it anyway."],
				["Jamie", "You can hang out. Just don't read over my shoulder."],
			])
			jamie_pc.enabled = true
			objective("Hang out with Jamie")
		Step.HANG_OUT, Step.BEDTIME:
			var pool := ["Shh. I'm talking to people.", "Go to bed, kid.", "If you tell Mom I'm still up, I'll tell her about the candy under your bed."]
			say([["Jamie", pool[randi() % pool.size()]]])


func _on_jamie_pc(_by: Node) -> void:
	if interlude.active:
		return
	if busy or step != Step.HANG_OUT:
		return
	step = Step.BEDTIME
	busy = true
	jamie_pc.enabled = false
	await say([
		["", "Jamie's typing to three people at once. Every time the door-creak sound plays, they type faster."],
		["", "Their away message is a song lyric you don't understand yet."],
		["Jamie", "Okay, you're reading over my shoulder."],
	])
	await wait(1.0)
	await say([
		["Mom (hallway)", "Bedtime! Both of you."],
		["Jamie", "I'm fifteen."],
		["Mom (hallway)", "Then it's fifteen-year-old bedtime."],
		["Jamie", "...Night, kid."],
	])
	busy = false
	objective("Get ready for bed")


# --- Step 6: sleep and dream --------------------------------------------

func _on_bed(_by: Node) -> void:
	if interlude.active:
		return
	if busy:
		return
	if step != Step.BEDTIME:
		hud.show_memory("Not yet. Nobody's even said bedtime.", 3.0)
		return
	step = Step.DREAM
	busy = true
	objective("")
	lock(true)
	hud.show_memory("The glow-in-the-dark stars are brighter than they've been all year.", 4.0)
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


func _enter_dream() -> void:
	unstash(dream_hall, self)
	dog.set_active(false)
	tv_screen.channel = "dream"
	Audio.set_dreaming(true)
	Audio.play_music("dream_hall", 3.0)
	stash(hall_end)
	stash(jamie_full)
	unstash(jamie_dream, jamie_room)
	jamie_door.rotation.y = deg_to_rad(95.0)
	for n in ["Lamp", "KitchenLight", "HallLight", "JamieDesk", "JamieMonitor", "LavaLight", "KidLamp", "PorchLight"]:
		(lights.get_node(n) as OmniLight3D).light_energy = 0.0
	mom.visible = false
	dad.visible = false
	mom.process_mode = Node.PROCESS_MODE_DISABLED
	dad.process_mode = Node.PROCESS_MODE_DISABLED
	env.ambient_light_color = Color(0.3, 0.25, 0.5)
	env.ambient_light_energy = 0.55
	env.background_color = Color(0.03, 0.02, 0.07)
	env.fog_light_color = Color(0.2, 0.15, 0.35)
	env.fog_density = 0.05
	player.camera.fov = 90.0
	player.teleport(Vector3(4.3, 0.05, -6.8), 90.0)


func _on_dream_door(_by: Node) -> void:
	if interlude.active:
		return
	if busy:
		return
	busy = true
	lock(true)
	await wait(2.5)
	await hud.fade(1.0, 2.5, Color(1.0, 0.94, 0.82)).finished
	await wait(0.5)
	await hud.fade(1.0, 1.0, Color.BLACK).finished
	Audio.stop_music(1.0)
	interlude.start()


## Crickets outside the front door (the interlude silences them).
func fade_crickets(to_db: float, time: float) -> void:
	create_tween().tween_property(_crickets, "volume_db", to_db, time)
