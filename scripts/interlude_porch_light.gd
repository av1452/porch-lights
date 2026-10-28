extends Node
## Interlude — 2:14 a.m., later that night. Plays inside the Chapter 1 house
## after the dream hallway, then hands off to Chapter 2.
## Wake up → Jamie's still awake → overhear Mom on the phone about Grandma →
## Biscuit wants out → porch light back on → every porch light on the street
## is on again, and they go out one by one → all but one.

enum Step { WAKE, LET_OUT, PORCH, END }

const NEXT_CHAPTER := "res://scenes/chapter_2_thanksgiving.tscn"
## Where Leo looks when the street lights start going out.
const STREET_POINT := Vector3(-2.1, 0.6, 18.0)

@onready var ch = get_parent() # chapter_1_halloween.gd
@onready var player: Player = $"../Player"
@onready var hud: GameHud = $"../HUD"
@onready var dog: Dog = $"../Biscuit"
@onready var street: Street = $"../Street"
@onready var front_door: Interactable = $"../House/LivingRoom/Things/FrontDoor"
@onready var porch_switch: Interactable = $"../Story/PorchSwitch"
@onready var pane_on: Node3D = $"../Story/PorchPaneOn"
@onready var pane_off: Node3D = $"../Story/PorchPaneOff"
@onready var porch_light: OmniLight3D = $"../Lights/PorchLight"
@onready var porch_bulb: CSGShape3D = $"../Exterior/PorchLamp"
@onready var spot_door: Marker3D = $"../DogSpots/InsideDoor"
@onready var spot_doorway: Marker3D = $"../DogSpots/Doorway"
@onready var spot_porch: Marker3D = $"../DogSpots/Porch"

var active := false
var step := Step.WAKE
var _porch_on := false
var _energy := {}
var _porch_energy := 0.0
var _standing_jamie: Node3D
var _jamie_coming := false


func _ready() -> void:
	# Remember how bright things were before the dream switched them off.
	var lights: Node3D = $"../Lights"
	for l in lights.get_children():
		if l is Light3D:
			_energy[l.name] = (l as Light3D).light_energy
	_porch_energy = porch_light.light_energy


## Called by Chapter 1 when the dream door fades out (screen is black).
func start() -> void:
	active = true
	ch.busy = true
	ch.lock(true)
	ch.objective("")
	_set_up_night()
	Audio.play_music("ch2_night", 4.0, -4.0)
	await ch.wait(1.0)
	await hud.chapter_card("2:14 a.m.", "The Porch Light")
	await hud.fade(0.0, 3.0).finished
	ch.lock(false)
	ch.busy = false
	hud.show_memory("Something woke you up. Out in the living room, Biscuit is whining.", 5.0)
	await ch.wait(3.0)
	ch.objective("Check on Biscuit")


func _set_up_night() -> void:
	# Back in the real house.
	ch.stash(ch.dream_hall)
	ch.unstash(ch.hall_end, ch.hallway)
	ch.stash(ch.jamie_dream)
	ch.unstash(ch.jamie_full, ch.jamie_room)
	ch.jamie_door.rotation.y = 0.0
	ch.jamie_door.enabled = false
	Audio.set_dreaming(false)

	var env: Environment = ch.env
	env.ambient_light_color = Color(0.3, 0.3, 0.45)
	env.ambient_light_energy = 0.22
	env.fog_light_color = Color(0.1, 0.1, 0.14)
	env.fog_density = 0.02
	player.camera.fov = player.base_fov

	# 2 a.m.: TV and lamp off, kitchen light on (Mom and Dad are up),
	# Jamie's monitor glowing, and the porch light off since Leo turned it off.
	var lights: Node3D = $"../Lights"
	for n in _energy:
		(lights.get_node(n) as Light3D).light_energy = 0.0
	for n in ["KitchenLight", "JamieMonitor", "JamieDesk", "LavaLight"]:
		if _energy.has(n):
			(lights.get_node(n) as Light3D).light_energy = _energy[n] * (0.6 if n == "KitchenLight" else 1.0)
	if _energy.has("KidLamp"):
		(lights.get_node("KidLamp") as Light3D).light_energy = _energy["KidLamp"] * 0.25
	ch.tv_screen.channel = "off"
	_set_porch_light(false)

	# Up and down the street, every porch light is on again.
	street.restore_lights()

	ch.mom.visible = true
	ch.dad.visible = true
	ch.mom.process_mode = Node.PROCESS_MODE_INHERIT
	ch.dad.process_mode = Node.PROCESS_MODE_INHERIT
	ch.mom.used.connect(_on_parents)
	ch.dad.used.connect(_on_parents)

	front_door.memory_text = ""
	front_door.repeat_text = ""
	front_door.prompt = "Front door"
	front_door.used.connect(_on_front_door)
	porch_switch.prompt = "Porch light"
	porch_switch.used.connect(_on_switch)

	dog.set_active(true)
	dog.free_roam = false
	dog.global_position = spot_door.global_position
	dog.go_to([spot_door.global_position], false, front_door.global_position)
	dog.set_pose(Dog.Pose.SIT)
	dog.set_whining(true)

	_trigger(Vector3(2.0, 1.0, -4.3), Vector3(1.1, 2.0, 0.8), _on_pass_jamie)
	_trigger(Vector3(2.55, 1.0, 0.0), Vector3(1.1, 2.0, 1.8), _on_overhear)
	_trigger(Vector3(-2.1, 1.0, 1.4), Vector3(1.6, 2.0, 1.4), _on_reach_dog)
	_trigger(Vector3(-1.55, 1.0, 4.1), Vector3(3.3, 2.0, 1.6), _on_porch)

	player.teleport(Vector3(4.6, 0.05, -7.0), 90.0)


func _trigger(pos: Vector3, size: Vector3, callback: Callable) -> void:
	var t := Trigger.new()
	t.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	t.add_child(shape)
	add_child(t)
	t.player_entered.connect(callback)


func _set_porch_light(on: bool) -> void:
	_porch_on = on
	porch_light.light_energy = _porch_energy if on else 0.0
	pane_on.visible = on and front_door.enabled
	(porch_bulb.material as StandardMaterial3D).emission_energy_multiplier = 4.0 if on else 0.0


# --- Jamie --------------------------------------------------------------

func _on_pass_jamie() -> void:
	if step != Step.WAKE:
		return
	ch.busy = true
	await ch.swing_door(ch.jamie_door, 95.0)
	await ch.say([
		["Jamie", "...Hey. Why are you up?"],
		["", "You point down the hall. Biscuit whines again, louder."],
		["Jamie", "He's been doing that for like an hour. I thought it was the dryer."],
		["Jamie", "Fine. I'm coming. If something eats you, Mom's gonna blame me."],
	])
	ch.busy = false
	_jamie_coming = true
	# Jamie gets up from the computer.
	ch.jamie.visible = false
	ch.jamie.collision_layer = 0
	_standing_jamie = _make_standing_jamie()
	_place_jamie(Vector3(-0.6, 0.0, 1.6), front_door.global_position)


## Jamie's model is built sitting at the desk; make a standing copy.
func _make_standing_jamie() -> Node3D:
	var j: StaticBody3D = ch.jamie.duplicate(Node.DUPLICATE_GROUPS)
	j.visible = true
	j.collision_layer = 0
	var mat: Material = (j.get_node("Thighs") as CSGBox3D).material
	for part in ["Thighs", "Shins"]:
		j.get_node(part).free()
	for c in j.get_children():
		if c is Node3D:
			(c as Node3D).position.y += 0.36
	var legs := CSGBox3D.new()
	legs.size = Vector3(0.3, 0.86, 0.17)
	legs.position.y = 0.43
	legs.material = mat
	j.add_child(legs)
	add_child(j)
	return j


func _place_jamie(pos: Vector3, facing: Vector3) -> void:
	_standing_jamie.global_position = pos
	var to := facing - pos
	_standing_jamie.rotation.y = atan2(to.x, to.z)


# --- Mom and Dad in the kitchen -----------------------------------------

func _on_overhear() -> void:
	if step == Step.END:
		return
	ch.say([
		["Mom (kitchen)", "That was her again. Two in the morning, and she's wide awake."],
		["Dad (kitchen)", "Is she okay?"],
		["Mom (kitchen)", "She says the house is too quiet. She asked if I remembered to turn her porch light on."],
		["Mom (kitchen)", "Like I still live there. Like I'm twelve."],
		["Dad (kitchen)", "I'll call her in the morning. Come back to bed."],
		["Mom (kitchen)", "In a minute."],
	])


func _on_parents(_by: Node) -> void:
	if active and not ch.busy:
		hud.show_memory("You stay in the doorway. They haven't seen you, and you don't want them to.", 4.0)


# --- Biscuit and the front door -----------------------------------------

func _on_reach_dog() -> void:
	if step != Step.WAKE:
		return
	step = Step.LET_OUT
	hud.show_memory("Biscuit's nose is pressed to the crack under the door. His tail isn't wagging.", 5.0)
	ch.objective("Let Biscuit out")


func _on_switch(_by: Node) -> void:
	if not active or step == Step.END:
		return
	_set_porch_light(not _porch_on)
	if _porch_on and porch_switch.times_used == 1:
		hud.show_memory("Click. You turned it off yourself, a few hours ago. It feels like a lot longer.", 4.5)


func _on_front_door(_by: Node) -> void:
	if not active or step == Step.PORCH or step == Step.END:
		return
	if not _porch_on:
		hud.show_memory("It's pitch black out there. You turned the porch light off yourself.", 4.5)
		ch.objective("Turn the porch light back on")
		return
	step = Step.PORCH
	front_door.enabled = false
	front_door.collision_layer = 0
	pane_on.visible = false
	pane_off.visible = false
	Audio.play_sfx("door_open", front_door)
	ch.fade_crickets(0.0, 1.5)
	# The door's origin is its middle; swing it around the hinge on its left.
	var hinge: Vector3 = front_door.position + Vector3(-0.5, 0, 0)
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).tween_method(func(a: float) -> void:
		front_door.rotation.y = a
		front_door.position = hinge + Vector3(cos(a), 0, -sin(a)) * 0.5, 0.0, deg_to_rad(95.0), 1.6)
	hud.show_memory("Cold air. Every porch light on the street is on. All of them. At two in the morning.", 5.0)
	ch.objective("Follow Biscuit")
	dog.set_whining(false)
	await ch.wait(0.8)
	dog.go_to([spot_doorway.global_position, spot_porch.global_position], true, STREET_POINT)
	dog.arrived.connect(func() -> void: dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)
	if _jamie_coming:
		ch.say([["Jamie", "Go on. I'm right behind you."]])


# --- The porch ----------------------------------------------------------

func _on_porch() -> void:
	if step != Step.PORCH:
		return
	step = Step.END
	await ch.wait(1.5)
	ch.busy = true
	ch.lock(true)
	ch.objective("")
	if _jamie_coming:
		_place_jamie(Vector3(-2.1, 0.0, 2.75), STREET_POINT)
	await player.tween_look_at(STREET_POINT, 2.0).finished
	ch.fade_crickets(-60.0, 4.0)
	Audio.stop_music(5.0)
	await ch.wait(2.5)
	await ch.say([["", "It's so quiet. Even the crickets stopped."]])
	if _jamie_coming:
		await ch.say([["Jamie", "...Why is everybody's porch light on?"]])

	var lights := street.porch_lights
	for i in lights.size():
		var e: Dictionary = lights[i]
		var at: Vector3 = (e.light as Node3D).global_position
		player.tween_look_at(at, 0.9)
		await ch.wait(0.7)
		street.kill_light(e)
		Audio.play_sfx("light_out", at, 8.0)
		if i == 2:
			hud.show_line("", "One by one, down the street, they go out. Nobody's flipping them. Nobody's there.")
		if i == 6:
			hud.clear_line()
			dog.set_pose(Dog.Pose.STAND)
			dog.growl()
		await ch.wait(0.9 if i < 3 else 0.6)

	var far: Vector3 = (street.far_light.light as Node3D).global_position
	player.tween_fov(30.0, 4.0)
	await player.tween_look_at(far, 3.0).finished
	await ch.wait(1.0)
	await ch.say([["", "Except one. Way at the end of the street. The same orange as Grandma's porch light."]])
	if _jamie_coming:
		await ch.say([["Jamie", "...Whose house is that?"]])
	await ch.wait(1.0)
	player.tween_fov(player.base_fov, 1.0)

	# Our own light gives out.
	Audio.play_sfx("bulb_flicker", porch_light, 2.0)
	for i in 7:
		_set_porch_light(i % 2 == 1)
		await ch.wait(randf_range(0.05, 0.2))
	_set_porch_light(false)
	await ch.wait(0.6)
	await dog.bark(2)
	await ch.wait(1.5)

	await hud.fade(1.0, 2.0).finished
	await ch.wait(1.0)
	var lines := [["Dad", "Hey. Hey. What are you doing out here?"]]
	if _jamie_coming:
		lines += [
			["Jamie", "Biscuit had to go out."],
			["Dad", "At two in the morning. Inside. Both of you. Biscuit, you too."],
		]
	else:
		lines += [["Dad", "It's two in the morning. Inside, bud. Biscuit, you too."]]
	lines += [
		["", "Behind him, Mom is standing in the hallway with the phone still in her hand."],
		["Mom", "...Was her light on?"],
		["Dad", "Bed. Everybody."],
	]
	await ch.say(lines)
	await ch.wait(2.0)
	Audio.stop_music(1.0)
	Audio.stop_voice()
	ch.go_to_chapter(NEXT_CHAPTER)
