extends Chapter
## Chapter 4 — December 18. The last week before winter break.
## Same house as Chapter 1 (the scene inherits it), decorated for December.
## Mom's been at Grandma's all week. Help Dad with dinner → Mom calls from
## Grandma's → find the one dead bulb with Jamie → fall asleep to the
## Christmas special → in the dream it snows in the living room and
## Grandma calls → wake up, and Mom's home.

enum Step { FIND_DAD, SET_TABLE, PHONE, JAMIE, BULB, COUCH, DREAM, END }

const TREE_POS := Vector3(-2.35, 0.0, -0.65)
const BULB_COLORS := [Color(1, 0.2, 0.2), Color(0.2, 1, 0.3), Color(0.3, 0.5, 1), Color(1, 0.85, 0.2), Color(1, 0.5, 0.1)]
## Which of the bulbs you can check is the dead one.
const DEAD_CHECK := 3

@onready var env: Environment = $WorldEnvironment.environment
@onready var lights: Node3D = $Lights
@onready var dad: Interactable = $Story/Dad
@onready var phone: Interactable = $House/Kitchen/Things/Phone
@onready var couch: Interactable = $House/LivingRoom/Things/Couch
@onready var tv_screen: TvScreen = $House/LivingRoom/Things/TV/ScreenFeed
@onready var dog: Dog = $Biscuit

var jamie: Interactable
var _jamie_on_couch: Interactable
var _plates: Interactable
var _bulb_mats: Array[StandardMaterial3D] = []
var _checks: Array[Interactable] = []
var _tree_glow: OmniLight3D
var _ringing := false
var _snow: GPUParticles3D
var _flicker_t := 0.0
var _tv_energy := 0.0
var _dream_hall: Node
var _jamie_dream: Node


func _ready() -> void:
	super._ready()
	_tv_energy = (lights.get_node("TVGlow") as OmniLight3D).light_energy
	dog.player = player
	_put_away_halloween()
	_set_the_scene()
	_decorate()

	dad.used.connect(_on_dad)
	phone.used.connect(_on_phone)
	couch.used.connect(_on_couch)
	jamie.used.connect(_on_jamie)

	Audio.make_loop("clock_tick", $House/LivingRoom/Things/Clock, -14.0)
	Audio.make_loop("room_tone", $House/Kitchen/Things/Fridge, -10.0)
	Audio.make_loop("wind", $Exterior/Ambience, -10.0)
	Audio.play_music("ch4_silent_night", 4.0, -6.0)

	await open_chapter("December 18", "The Last Week Before Winter Break")
	hud.show_memory("Mom's been at Grandma's since Sunday. The house sounds different without her.", 5.0)
	await wait(2.5)
	objective("Find Dad")


func _exit_tree() -> void:
	free_stashed([_dream_hall, _jamie_dream])


func _process(delta: float) -> void:
	super._process(delta)
	_flicker_t -= delta
	if _flicker_t > 0.0:
		return
	_flicker_t = randf_range(0.05, 0.22)
	var tv := lights.get_node("TVGlow") as OmniLight3D
	tv.light_energy = 0.0 if tv_screen.channel == "off" else _tv_energy * randf_range(0.7, 1.15)
	tv.light_color = tv.light_color.lerp(tv_screen.light_color(), 0.5)


# --- Setting up December ------------------------------------------------

func _hide(path: String) -> void:
	var n := get_node(path) as Node3D
	n.visible = false
	if n is CollisionObject3D:
		(n as CollisionObject3D).collision_layer = 0
	if n is Interactable:
		(n as Interactable).enabled = false


func _put_away_halloween() -> void:
	for p in ["Story/Candy", "Story/Mom", "House/LivingRoom/Things/Mask", "House/LivingRoom/Things/JackOLantern",
			"House/Kitchen/Things/CandyBowl", "House/JamieRoom/JamieRoomFull/Things/Jamie"]:
		_hide(p)
	(lights.get_node("PumpkinLight") as OmniLight3D).light_energy = 0.0
	# Chapter 1's dream pieces aren't used this chapter.
	_dream_hall = $DreamHall
	_jamie_dream = $House/JamieRoom/JamieRoomDream
	stash(_dream_hall)
	stash(_jamie_dream)


func _set_the_scene() -> void:
	($House/Kitchen/Furniture/CalendarMonth as Label3D).text = "DECEMBER"
	tv_screen.channel = "winter"
	dad.position = Vector3(6.0, 0.0, -0.6)
	dad.rotation.y = deg_to_rad(90.0)
	phone.memory_text = ""
	phone.repeat_text = ""
	phone.prompt = "Phone"
	couch.memory_text = ""
	couch.repeat_text = ""
	couch.prompt = "Sit down"
	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "Snow on the porch rail. Every house on the street has Christmas lights up except the Kowalskis'."
	window.repeat_text = "You write your name in the fog on the glass. Then, next to it, Grandma's."
	jamie = Figure.person(self, "Jamie", Vector3(-1.5, 0.0, 0.35), -140.0, 1.62, Figure.JAMIE)
	_plates = _box_thing("Plates", Vector3(6.55, 0.96, 1.7), Vector3(0.25, 0.07, 0.25), Color(0.95, 0.95, 0.92), "Grab the plates")
	_plates.enabled = false
	_plates.used.connect(_on_plates)


func _box_thing(node_name: String, pos: Vector3, size: Vector3, color: Color, prompt_text: String) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt_text
	it.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	it.add_child(shape)
	var mesh := CSGBox3D.new()
	mesh.size = size
	mesh.material = _mat(color)
	it.add_child(mesh)
	add_child(it)
	return it


func _mat(c: Color, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


## The tree: three green cones, a star, presents, and a string of bulbs
## that won't light until you find the dead one.
func _decorate() -> void:
	var tree := Node3D.new()
	tree.name = "ChristmasTree"
	tree.position = TREE_POS
	add_child(tree)
	var trunk := CSGCylinder3D.new()
	trunk.radius = 0.06
	trunk.height = 0.3
	trunk.position.y = 0.15
	trunk.material = _mat(Color(0.3, 0.18, 0.1))
	tree.add_child(trunk)
	var green := _mat(Color(0.1, 0.3, 0.15))
	for i in 3:
		var cone := CSGCylinder3D.new()
		cone.cone = true
		cone.radius = 0.55 - i * 0.14
		cone.height = 0.7 - i * 0.1
		cone.position.y = 0.55 + i * 0.42
		cone.sides = 10
		cone.material = green
		tree.add_child(cone)
	var star := CSGBox3D.new()
	star.size = Vector3(0.12, 0.12, 0.03)
	star.rotation_degrees.z = 45
	star.position.y = 1.72
	star.material = _mat(Color(1, 0.85, 0.3), 3.0)
	tree.add_child(star)
	for i in 4:
		var gift := CSGBox3D.new()
		gift.size = Vector3(0.22, 0.16 + 0.05 * (i % 2), 0.2)
		gift.position = Vector3(0.35 * cos(i * 1.6), gift.size.y / 2.0, 0.35 * sin(i * 1.6) + 0.1)
		gift.rotation_degrees.y = i * 25.0
		gift.material = _mat(BULB_COLORS[i].darkened(0.3))
		tree.add_child(gift)

	# bulbs spiral down the tree
	var n := 18
	for i in n:
		var t := float(i) / n
		var y := 1.55 - t * 1.25
		var r := 0.12 + t * 0.42
		var a := t * TAU * 3.0
		var pos := Vector3(cos(a) * r, y, sin(a) * r)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = BULB_COLORS[i % BULB_COLORS.size()].darkened(0.6)
		mat.emission = BULB_COLORS[i % BULB_COLORS.size()]
		mat.emission_energy_multiplier = 0.0
		mat.emission_enabled = true
		_bulb_mats.append(mat)
		var bulb := CSGSphere3D.new()
		bulb.radius = 0.035
		bulb.radial_segments = 6
		bulb.rings = 4
		bulb.position = pos
		bulb.material = mat
		tree.add_child(bulb)
		# Every third bulb, on the side facing the room, is one you can check.
		if i % 3 == 1 and _checks.size() < 5:
			var check := Interactable.new()
			check.name = "Bulb%d" % _checks.size()
			check.prompt = "Check bulb"
			check.enabled = false
			check.position = pos
			var shape := CollisionShape3D.new()
			var s := SphereShape3D.new()
			s.radius = 0.09
			shape.shape = s
			check.add_child(shape)
			tree.add_child(check)
			check.used.connect(_on_bulb.bind(_checks.size()))
			_checks.append(check)
	_tree_glow = OmniLight3D.new()
	_tree_glow.light_color = Color(1, 0.75, 0.55)
	_tree_glow.light_energy = 0.0
	_tree_glow.omni_range = 4.0
	_tree_glow.position = Vector3(0.4, 1.0, 0.3)
	tree.add_child(_tree_glow)


# --- Step 0-1: Dad and dinner -------------------------------------------

func _on_dad(_by: Node) -> void:
	if busy:
		return
	match step:
		Step.FIND_DAD:
			step = Step.SET_TABLE
			await say([
				["Dad", "Hey, bud. Your mom's staying at Grandma's a couple more days."],
				["Dad", "So tonight, you get my famous dinner. It's pizza. The famous part is I'm making it."],
				["Dad", "Can you set the table? Plates are on the counter."],
			])
			_plates.enabled = true
			objective("Set the table")
		Step.SET_TABLE:
			say([["Dad", "Plates are on the counter, by the sink."]])
		_:
			var pool := ["It's not burnt. It's well done.", "Your mom does this every night? Huh."]
			say([["Dad", pool[randi() % pool.size()]]])


func _on_plates(_by: Node) -> void:
	if busy or step != Step.SET_TABLE:
		return
	step = Step.PHONE
	busy = true
	_plates.visible = false
	_plates.collision_layer = 0
	for i in 3:
		var plate := CSGCylinder3D.new()
		plate.radius = 0.12
		plate.height = 0.015
		plate.sides = 12
		plate.position = Vector3(4.6 + [-0.35, 0.35, 0.0][i], 0.775, 0.4 + [0.0, 0.0, 0.3][i])
		plate.material = _mat(Color(0.95, 0.95, 0.92))
		add_child(plate)
	hud.show_memory("Three plates. You almost get out four, then put one back.", 4.5)
	await wait(2.5)
	await say([
		["Dad", "...It's a little crispy. We'll call it well done."],
		["Jamie", "Is something burning?"],
		["Dad", "No!"],
	])
	busy = false
	_ringing = true
	_ring()
	objective("Answer the phone")


func _ring() -> void:
	while _ringing:
		Audio.play_sfx("phone_ring", phone, 2.0)
		await wait(3.5)


# --- Step 2: Mom calls from Grandma's -----------------------------------

func _on_phone(_by: Node) -> void:
	if busy:
		return
	if step == Step.DREAM:
		_dream_call()
		return
	if step != Step.PHONE:
		hud.show_memory("The cord's stretched out from somebody pacing while they talked.", 4.0)
		return
	step = Step.JAMIE
	busy = true
	_ringing = false
	objective("")
	Audio.play_sfx("phone_hangup", phone, -6.0)
	await say([
		["Mom (phone)", "Hi, sweetie. It's me."],
		["", "Her voice sounds smaller on the phone. Far away, and very tired."],
		["Mom (phone)", "Grandma says hi. She wants to know if you're being good for your dad."],
		["Mom (phone)", "She's sleeping a lot. That's okay. That's what the doctor wants."],
		["Mom (phone)", "I'll be home Friday. Can you put your dad on?"],
		["", "Dad takes the phone into the garage. He shuts the door, which he never does."],
	])
	_hide("Story/Dad")
	busy = false
	objective("Find Jamie")


# --- Step 3-4: the dead bulb --------------------------------------------

func _on_jamie(_by: Node) -> void:
	if busy:
		return
	match step:
		Step.JAMIE:
			step = Step.BULB
			await say([
				["Jamie", "Hey. Come here. Help me find the dead one."],
				["Jamie", "If one bulb's out, the whole string won't light. It's the stupidest thing ever invented."],
			])
			for c in _checks:
				c.enabled = true
			objective("Find the dead bulb")
		Step.BULB:
			say([["Jamie", "Just check them one at a time. That's the only way."]])
		Step.COUCH:
			say([["Jamie", "Couch. Special's starting."]])
		Step.FIND_DAD, Step.SET_TABLE, Step.PHONE:
			say([["Jamie", "Go help Dad. I'm busy with these stupid lights."]])


func _on_bulb(_by: Node, index: int) -> void:
	if busy or step != Step.BULB:
		return
	if index != DEAD_CHECK:
		var pool := ["Not this one.", "This one's fine. Jamie sighs.", "Nope. You twist it back in."]
		hud.show_memory(pool[index % pool.size()], 2.5)
		_checks[index].enabled = false
		return
	step = Step.COUCH
	busy = true
	for c in _checks:
		c.enabled = false
	hud.show_memory("This one's loose and dark. You twist in a new one from the box.", 3.0)
	await wait(1.5)
	Audio.play_sfx("switch_click", _tree_glow, -4.0)
	for m in _bulb_mats:
		m.emission_energy_multiplier = 2.5
	create_tween().tween_property(_tree_glow, "light_energy", 1.4, 0.4)
	await say([
		["Jamie", "...Nice. See? Just the one."],
		["Jamie", "Mom's gonna be okay, you know. And Grandma."],
		["Jamie", "Probably."],
		["", "Jamie doesn't say probably very often."],
		["Jamie", "Special's on. Couch. Now."],
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
	# Jamie sits down too.
	jamie.visible = false
	jamie.collision_layer = 0
	_jamie_on_couch = Figure.person(self, "Jamie", Vector3(-0.5, 0.0, 2.05), 180.0, 1.62, Figure.JAMIE, true)
	player.sit(Vector3(0.45, 0.05, 1.95), 0.0)
	lock(true)
	await say([
		["", "A cartoon snowman looks for his lost hat. Jamie pretends not to be watching."],
		["", "The tree lights blink in the dark window. Somebody's car door. Not Mom's."],
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
	hud.show_memory("It's snowing. In the living room. It doesn't seem strange at all.", 5.0)
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
	env.ambient_light_color = Color(0.3, 0.3, 0.55)
	env.ambient_light_energy = 0.45
	env.fog_light_color = Color(0.2, 0.2, 0.35)
	env.fog_density = 0.04
	player.camera.fov = 85.0
	player.stand(Vector3(0.45, 0.05, 1.3), 0.0)
	Audio.set_dreaming(true)
	Audio.play_music("dream_hall", 3.0)
	_snow = _make_snow()
	add_child(_snow)


func _make_snow() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 500
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.position = Vector3(1.5, 2.55, 0.0)
	p.visibility_aabb = AABB(Vector3(-6, -3, -4), Vector3(12, 4, 8))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(4.5, 0.05, 2.5)
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0.05, -0.12, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.3
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.025)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = m
	p.draw_pass_1 = quad
	return p


func _dream_call() -> void:
	step = Step.END
	busy = true
	_ringing = false
	objective("")
	lock(true)
	Audio.play_sfx("phone_hangup", phone, -6.0)
	await say([
		["Grandma (phone)", "Is it snowing there too?"],
		["", "It's snowing in the kitchen now. You say yes."],
		["Grandma (phone)", "Good. I always loved the first snow. Your mom used to eat it right off the porch rail."],
		["Grandma (phone)", "Will you do something for me? Leave your porch light on Christmas Eve. So I can find you."],
		["", "You promise. You're getting good at promises."],
	])
	await wait(1.0)
	await hud.fade(1.0, 2.5, Color(1.0, 0.97, 0.94)).finished
	await wait(0.5)
	await hud.fade(1.0, 1.0, Color.BLACK).finished
	Audio.stop_music(2.0)
	Audio.set_dreaming(false)
	await wait(1.5)
	await say([
		["Mom", "Hey. Hey, sleepyhead. I'm home."],
		["", "She smells like Grandma's house. Like cinnamon, and the cold."],
		["Mom", "Grandma sent something for you. You can open it Christmas Eve."],
	])
	await wait(1.5)
	Audio.play_music("ch4_silent_night", 3.0, -6.0)
	await hud.chapter_card("To be continued", "Next: December 24, Christmas Eve", 4.0)
