extends Node
## Chapter 5: Porch Lights. One year later, Halloween again. Leo puts
## Grandma's orange bulb in his own porch light and hands out full-size bars.
## A lost little ghost finds their way because of the orange light. At the
## end of the street, the old light comes on one more time.

@onready var main = get_parent() # main.gd
@onready var player: Player = $"../Player"
@onready var hud: GameHud = $"../HUD"
@onready var dog: Dog = $"../Biscuit"
@onready var street: Street = $"../Street"
@onready var door_hinge: Node3D = $"../Interactables/FrontDoorHinge"
@onready var front_door: Interactable = $"../Interactables/FrontDoorHinge/FrontDoor"
@onready var porch_switch: Interactable = $"../Interactables/PorchSwitch"
@onready var candy_bowl: Interactable = $"../Porch/CandyBowl"
@onready var steps_block: CollisionShape3D = $"../Porch/Bounds/StepsBlock"
@onready var shoes_prop: Node3D = $"../Props/Shoes"
@onready var spot_porch: Marker3D = $"../DogSpots/Porch"

const G := Street.GROUND_Y
## Where trick-or-treaters stand: the foot of our steps.
const STEPS := Vector3(-6.6, G, 0.0)
const WALK_END := Vector3(-12.4, G, 0.0)
const ORANGE := Color(1, 0.5, 0.15)
const GROUPS := [
	{ "kids": ["ghost", "witch"], "heights": [1.1, 1.2], "hello": "kids_1", "thanks": "kids_1_thanks", "from": 22.0 },
	{ "kids": ["pumpkin", "robot", "skeleton"], "heights": [1.0, 1.15, 1.3], "hello": "kids_2", "thanks": "kids_2_thanks", "from": -22.0 },
]
const CREDITS := [
	["PORCH LIGHTS", "The End"],
	["Made by", "Aidan Vazquez"],
	["Voices", "Kokoro text-to-speech"],
	["Sound and music", "BigSoundBank, Kenney, OpenGameArt (CC0)"],
	["Made with", "Godot Engine"],
	["For Grandma", "who always left the light on"],
]

var active := false
var _bulb_in := false
var _switch_on := false
var _bowl_full := false
var _door_open := false
var _visits_started := false
var _ended := false
var _bulb_spot: Interactable
var _bowl_bars: Node3D
var _crate: Node3D
var _said := {}


func _ready() -> void:
	front_door.used.connect(_on_front_door_used)
	porch_switch.used.connect(_on_switch_used)
	candy_bowl.used.connect(_on_bowl_used)


## From chapter 4, or `-- --chapter=5`.
func start(_jumped: bool) -> void:
	active = true
	main.chapter = 5
	main.call("_lock", true)
	_set_scene()
	Audio.play_sfx("title_sting", null, -6.0)
	await hud.show_title("Chapter 5 - Porch Lights", "One year later", 3.0).finished
	Audio.play_music("ch1_living_room", 4.0)
	await hud.fade(0.0, 3.0).finished
	main.call("_lock", false)
	await get_tree().create_timer(1.5).timeout
	await Audio.say("ch5_mom_intro")
	hud.set_objective("Put Grandma's bulb in the porch light.")


## Halloween night again, everything back the way it was in chapter 1.
func _set_scene() -> void:
	main.set_daylight(false)
	main.blanket.visible = false
	main.tv_screen.channel = "special"
	main.fade_crickets(-6.0, 2.0)
	main.set_porch_light(false)
	for e in street.porch_lights:
		street.relight(e, 0.0)
	street.set_level(street.far_light, 0.0, 0.0)
	shoes_prop.visible = true
	player.set_flashlight(false)
	player.teleport(Vector3(0.0, 0.05, 1.1), 0.0)
	dog.global_position = Vector3(1.6, 0.05, 1.0)
	dog.release()

	door_hinge.rotation_degrees.y = 0.0
	front_door.collision_layer = 1
	front_door.enabled = true
	steps_block.disabled = false

	# Grandma's bulb, in our porch light. The bulb material is shared with
	# the scene file, so work on a copy.
	main.porch_bulb.material = main.porch_bulb.material.duplicate()

	_reline("Interactables/Window", "ch5_window", PackedStringArray(["ch5_window_repeat"]))
	_reline("Interactables/Candy", "ch5_candy", PackedStringArray())
	_reline("Interactables/Mask", "ch5_mask", PackedStringArray())
	_reline("Interactables/SiblingDoor", "sib_first", PackedStringArray(["sib_repeat"]))
	(get_node("../Interactables/SiblingDoor") as Interactable).use_sfx = "knock"
	candy_bowl.line_id = ""
	candy_bowl.speak = false
	candy_bowl.prompt = "Fill the bowl"
	candy_bowl.times_used = 0

	_bulb_spot = Build.interactable(self, Vector3(-3.32, 1.98, -0.95), Vector3(0.4, 0.4, 0.4), "Put in Grandma's bulb")
	_bulb_spot.one_shot = true
	_bulb_spot.used.connect(_on_bulb_used)

	# Grandma's box on the porch, next to the bowl.
	_crate = Build.box(self, Vector3(0.45, 0.25, 0.3), Vector3(-3.5, 0.13, 0.25), Build.mat(Color(0.62, 0.47, 0.3)))
	var label := Label3D.new()
	label.text = "HALLOWEEN\nFULL SIZE ONLY"
	label.font_size = 28
	label.pixel_size = 0.004
	label.modulate = Color(0.1, 0.1, 0.12)
	label.outline_size = 0
	label.position = Vector3(-0.23, 0, 0)
	label.rotation_degrees.y = -90.0
	_crate.add_child(label)
	_bowl_bars = Node3D.new()
	_bowl_bars.position = candy_bowl.global_position + Vector3(0, 0.1, 0)
	add_child(_bowl_bars)


func _reline(path: String, first: String, repeats: PackedStringArray) -> void:
	var it := get_node("../" + path) as Interactable
	it.line_id = first
	it.repeat_line_ids = repeats
	it.times_used = 0
	it.speak = true


# ---------------------------------------------------------------- getting ready

func _on_front_door_used(_by: Node) -> void:
	if not active or _door_open:
		return
	_door_open = true
	front_door.enabled = false
	front_door.collision_layer = 0
	Audio.play_sfx("door_open", front_door)
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) \
		.tween_property(door_hinge, "rotation_degrees:y", 100.0, 1.6)
	Audio.say("ch5_door")


func _on_bulb_used(_by: Node) -> void:
	_bulb_in = true
	var mat := main.porch_bulb.material as StandardMaterial3D
	mat.albedo_color = ORANGE
	mat.emission = ORANGE
	main.porch_light.light_color = ORANGE
	Audio.play_sfx("switch_click", main.porch_bulb, -10.0, 0.2)
	await Audio.say("ch5_bulb")
	_refresh()


func _on_switch_used(_by: Node) -> void:
	if not active:
		return
	if not _bulb_in:
		Audio.say("ch5_switch_no_bulb")
		return
	_switch_on = not _switch_on
	main.set_porch_light(_switch_on)
	if _switch_on and not _beat_said("light_on"):
		await Audio.say("ch5_light_on")
	_refresh()


func _on_bowl_used(_by: Node) -> void:
	if not active or _bowl_full:
		return
	_bowl_full = true
	candy_bowl.prompt = "Candy bowl"
	Audio.play_sfx("candy_rustle", candy_bowl, -4.0)
	for i in 8:
		Build.candy_bar(_bowl_bars, Vector3(randf_range(-0.07, 0.07), i * 0.014, randf_range(-0.07, 0.07)), randf_range(0, 180))
	await Audio.say("ch5_fill_bowl")
	_refresh()


func _beat_said(id: String) -> bool:
	var was: bool = _said.has(id)
	_said[id] = true
	return was


func _refresh() -> void:
	if _visits_started:
		return
	if not _bulb_in:
		hud.set_objective("Put Grandma's bulb in the porch light.")
	elif not _switch_on:
		hud.set_objective("Turn on the porch light.")
	elif not _bowl_full:
		hud.set_objective("Fill the candy bowl.")
	else:
		_visits_started = true
		hud.set_objective("Wait for trick-or-treaters.")
		_visits()


# ---------------------------------------------------------------- trick or treat

func _visits() -> void:
	await get_tree().create_timer(4.0).timeout
	for g in GROUPS:
		await _group_visit(g)
		await get_tree().create_timer(5.0).timeout
	await _sammy()
	await _finale()


func _kid(costume: String, height: float, at: Vector3) -> TrickOrTreater:
	var k := TrickOrTreater.new()
	k.costume = costume
	k.height = height
	add_child(k)
	k.global_position = at
	return k


func _wait_for(kids: Array[TrickOrTreater]) -> void:
	while kids.any(func(k: TrickOrTreater): return k.is_walking()):
		await get_tree().process_frame


## Waits until Leo hands out candy to whoever's at the steps.
func _give_candy(prompt: String) -> void:
	var give := Build.interactable(self, STEPS, Vector3(0.9, 1.4, 1.8), prompt, "", Vector3(0, 0.7, 0))
	give.one_shot = true
	await give.used
	give.queue_free()
	Audio.play_sfx("candy_rustle", candy_bowl, -4.0)
	for i in 2:
		if _bowl_bars.get_child_count() > 1:
			_bowl_bars.get_child(_bowl_bars.get_child_count() - 1).free()


func _group_visit(g: Dictionary) -> void:
	var kids: Array[TrickOrTreater] = []
	var n: int = g.kids.size()
	for i in n:
		var off := (i - (n - 1) / 2.0) * 0.55
		var k := _kid(g.kids[i], g.heights[i], Vector3(-12.9, G, g.from + i * 0.9 * signf(g.from)))
		k.walk([WALK_END + Vector3(0, 0, off * 0.4), STEPS + Vector3(-absf(off) * 0.3, 0, off)], 1.3 + randf() * 0.25)
		kids.append(k)
	await _wait_for(kids)
	for k in kids:
		k.face(player.global_position)
	await Audio.say(g.hello)
	hud.set_objective("Give them candy.")
	await _give_candy("Give candy")
	hud.set_objective("")
	await Audio.say(g.thanks)
	for i in n:
		var k := kids[i]
		k.walk([WALK_END + Vector3(0, 0, (i - 1) * 0.3), Vector3(-12.9, G, -g.from)], 1.5)
		k.arrived.connect(k.queue_free)
	hud.set_objective("Wait for trick-or-treaters.")


## The last one: a little ghost, alone, from the end of the street.
func _sammy() -> void:
	var sammy := _kid("ghost", 0.85, Vector3(-12.9, G, -22.0))
	sammy.walk([WALK_END + Vector3(0, 0, -0.3), STEPS], 1.0)
	await sammy.arrived
	sammy.face(player.global_position)
	await get_tree().create_timer(1.0).timeout
	await Audio.say("sammy_1")
	hud.set_objective("Give the little ghost some candy.")
	await _give_candy("Give candy")
	hud.set_objective("")
	await Audio.say("ch5_sammy_candy")
	dog.go_to([spot_porch.global_position], false, STEPS)
	dog.arrived.connect(func(): dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)
	await get_tree().create_timer(5.0).timeout

	var brother := _kid("", 1.45, Vector3(-12.9, G, 24.0))
	brother.walk([WALK_END + Vector3(0, 0, 0.5), STEPS + Vector3(0, 0, 0.6)], 3.2)
	var flashlight := SpotLight3D.new()
	flashlight.light_energy = 2.0
	flashlight.spot_range = 10.0
	flashlight.spot_angle = 20.0
	flashlight.position = Vector3(0.2, 0.9, -0.2)
	flashlight.rotation_degrees.x = -15.0
	brother.add_child(flashlight)
	await brother.arrived
	brother.face(sammy.global_position)
	sammy.face(brother.global_position)
	await Audio.say("brother_1")
	brother.walk([WALK_END + Vector3(0, 0, 0.4), Vector3(-12.9, G, 34.0)], 1.2)
	sammy.walk([WALK_END + Vector3(0, 0, 0.9), Vector3(-12.6, G, 34.0)], 1.2)
	brother.arrived.connect(brother.queue_free)
	sammy.arrived.connect(sammy.queue_free)
	await get_tree().create_timer(4.0).timeout


# ---------------------------------------------------------------- the end

func _finale() -> void:
	main.call("_lock", true)
	if player.global_position.x > -3.2:
		# Leo wandered inside; bring him back out to the porch for the ending.
		await hud.fade(1.0, 0.8).finished
		player.teleport(Vector3(-4.9, 0.05, 0.6), 90.0)
		await hud.fade(0.0, 0.8).finished
	await player.tween_look_at(Vector3(-18.0, 0.6, 0.0), 2.0).finished
	Audio.stop_music(6.0)
	# Everybody else goes to bed, one porch at a time. Ours stays on.
	var lights := street.porch_lights
	for i in lights.size():
		var at: Vector3 = (lights[i].light as Node3D).global_position
		player.tween_look_at(at, 1.4)
		await get_tree().create_timer(1.0).timeout
		street.kill_light(lights[i], 1.2)
		if i == 2:
			Audio.say("ch5_lights_out")
		await get_tree().create_timer(0.8).timeout
	await get_tree().create_timer(1.0).timeout
	await Audio.say("mom_ch5_late")
	await get_tree().create_timer(1.5).timeout

	# At the very end of the street, one more time.
	var far: Vector3 = (street.far_light.light as Node3D).global_position
	player.tween_fov(30.0, 4.0)
	await player.tween_look_at(far, 3.0).finished
	await get_tree().create_timer(1.5).timeout
	street.set_level(street.far_light, 1.0, 2.5)
	Audio.play_music("ending", 4.0)
	await get_tree().create_timer(4.0).timeout
	await Audio.say("ch5_far_light")
	dog.call("_on_petted", null)
	await get_tree().create_timer(2.0).timeout
	street.set_level(street.far_light, 0.0, 4.0)
	await get_tree().create_timer(3.0).timeout
	player.tween_fov(player.base_fov, 2.0)
	await hud.fade(1.0, 4.0).finished
	await get_tree().create_timer(1.0).timeout
	for c in CREDITS:
		await hud.show_title(c[0], c[1], 2.5).finished
	hud.show_memory("Press E to play again.", 600.0)
	_ended = true


func _unhandled_input(event: InputEvent) -> void:
	if _ended and event.is_action_pressed("interact"):
		Audio.stop_music(0.5)
		Audio.stop_voice()
		get_tree().reload_current_scene()
