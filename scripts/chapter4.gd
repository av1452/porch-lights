extends Node
## Chapter 4: Grandma's House. A week later, on a gray November afternoon,
## the family packs up her real house. Leo finds what she kept, and on her
## porch Mom gives him her orange porch-light bulb. It's still warm.

@onready var main = get_parent() # main.gd
@onready var player: Player = $"../Player"
@onready var hud: GameHud = $"../HUD"
@onready var dog: Dog = $"../Biscuit"
@onready var street: Street = $"../Street"
@onready var chapter5: Node = $"../Chapter5"

## Far enough from the neighborhood that neither can see the other.
const ORIGIN := Vector3(200, 0, 0)
## Memories to find before Mom calls Leo out to the porch.
const MEMORIES_BEFORE_PORCH := 3

var active := false
var house: GrandmaHouse
var _found := {}
var _kitchen_done := false
var _called := false
var _on_porch_done := false
var _bulb_taken := false
var _ambience: Array[Node] = []


func _ready() -> void:
	set_process(false)


## From chapter 3's morning, or `-- --chapter=4`.
func start(_jumped: bool) -> void:
	active = true
	main.chapter = 4
	main.call("_lock", true)

	house = GrandmaHouse.new()
	house.position = ORIGIN
	add_child(house)
	for id in house.memories:
		(house.memories[id] as Interactable).used.connect(_on_memory.bind(id))
	house.porch_lamp.used.connect(_on_lamp_used)

	# A gray November afternoon.
	main.set_daylight(true, Vector3(0.6, -0.5, -0.6))
	main.moon.light_energy = 0.8
	var sky := main.env.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = Color(0.45, 0.5, 0.58)
	sky.sky_horizon_color = Color(0.7, 0.7, 0.7)
	main.env.fog_density = 0.008
	main.set_porch_light(false)
	main.tv_screen.channel = "off"
	main.fade_crickets(-60.0, 0.1)
	street.kill_all()
	street.set_level(street.far_light, 0.0, 0.0)

	_ambience.append(Audio.make_loop("clock_tick", house, -18.0))
	(_ambience[0] as Node3D).position = Vector3(GrandmaHouse.W - 0.2, 1.9, 1.0)
	_ambience.append(Audio.make_loop("wind", house, -16.0))
	(_ambience[1] as Node3D).position = Vector3(-4, 1.5, 2.4)
	_ambience.append(Audio.make_loop("room_tone", house, -18.0))
	(_ambience[2] as Node3D).position = Vector3(6.4, 1.0, -4.4)

	player.set_flashlight(false)
	player.teleport(ORIGIN + Vector3(-1.4, 0.05, 2.4), -90.0)
	dog.set_whining(false)
	dog.global_position = ORIGIN + Vector3(-1.0, 0.05, 3.3)
	dog.release()

	Audio.play_sfx("title_sting", null, -6.0)
	await hud.show_title("Chapter 4", "Grandma's House", 2.5).finished
	await hud.fade(0.0, 3.0).finished
	main.call("_lock", false)
	set_process(true)
	await get_tree().create_timer(1.0).timeout
	await Audio.say("ch4_mom_intro")
	hud.set_objective("Look around Grandma's house.")


func _process(_delta: float) -> void:
	var p := player.global_position - ORIGIN
	if not _kitchen_done and p.z < -0.4 and p.x > 0.2:
		_kitchen_done = true
		Audio.say("ch4_kitchen")
	if _called and not _on_porch_done and p.x < -0.4:
		_on_porch_done = true
		_porch_talk()


func _on_memory(_by: Node, id: String) -> void:
	if _found.has(id):
		return
	_found[id] = true
	if _found.size() == MEMORIES_BEFORE_PORCH and not _called:
		# Let Leo's thought (and Dad's reply) finish before Mom calls.
		await get_tree().create_timer(9.0 if id == "pantry" else 6.0).timeout
		_called = true
		await Audio.say("ch4_mom_porch")
		hud.set_objective("Go out to the front porch.")


func _porch_talk() -> void:
	main.call("_lock", true)
	hud.set_objective("")
	await player.tween_look_at(house.bulb.global_position, 1.5).finished
	await Audio.say("ch4_mom_bulb")
	main.call("_lock", false)
	house.porch_lamp.enabled = true
	hud.set_objective("Take Grandma's bulb.")


func _on_lamp_used(_by: Node) -> void:
	if _bulb_taken:
		return
	_bulb_taken = true
	house.porch_lamp.enabled = false
	hud.set_objective("")
	main.call("_lock", true)
	Audio.play_sfx("switch_click", house.bulb, -10.0, 0.2)
	# Unscrew it: a few slow turns, then it's in Leo's hand.
	var t := create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(house.bulb, "rotation_degrees:y", 540.0, 1.6)
	t.tween_property(house.bulb, "position:y", house.bulb.position.y - 0.08, 0.3)
	await t.finished
	house.bulb.visible = false
	await Audio.say("ch4_bulb")
	await get_tree().create_timer(0.6).timeout

	# Home before dark.
	await player.tween_look_at(ORIGIN + Vector3(-6.2, 1.0, 2.4), 2.0).finished
	dog.bark(2)
	Audio.play_music("ending", 3.0)
	await get_tree().create_timer(2.0).timeout
	await hud.fade(1.0, 3.0).finished
	await get_tree().create_timer(1.0).timeout
	await Audio.say("ch4_bye")
	await get_tree().create_timer(1.5).timeout
	Audio.stop_music(3.0)
	_finish()


func _finish() -> void:
	active = false
	set_process(false)
	for a in _ambience:
		if a:
			a.queue_free()
	house.queue_free()
	chapter5.call("start", false)
