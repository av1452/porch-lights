extends Node
## Chapter 3: The Last Light. Later that night Leo can't sleep. He takes his
## shoes and Dad's flashlight and follows Biscuit down the dark street to the
## one porch light still on. It's Grandma's. Then the lights come back on, all
## the way home, and it's morning.

@onready var main = get_parent() # main.gd
@onready var player: Player = $"../Player"
@onready var hud: GameHud = $"../HUD"
@onready var dog: Dog = $"../Biscuit"
@onready var street: Street = $"../Street"
@onready var moon: DirectionalLight3D = $"../Lights/Moon"
@onready var hall_light: OmniLight3D = $"../Lights/HallLight"
@onready var door_hinge: Node3D = $"../Interactables/FrontDoorHinge"
@onready var front_door: Interactable = $"../Interactables/FrontDoorHinge/FrontDoor"
@onready var porch_switch: Interactable = $"../Interactables/PorchSwitch"
@onready var window: Interactable = $"../Interactables/Window"
@onready var steps_block: CollisionShape3D = $"../Porch/Bounds/StepsBlock"
@onready var shoes_prop: Node3D = $"../Props/Shoes"
@onready var spot_door: Marker3D = $"../DogSpots/InsideDoor"
@onready var spot_doorway: Marker3D = $"../DogSpots/Doorway"
@onready var spot_porch: Marker3D = $"../DogSpots/Porch"

const G := Street.GROUND_Y
const HOME := Vector3(-12.0, 1.0, 0.0)
## Biscuit's walk to Grandma's: down the front walk, south along our
## sidewalk, across the road, up to her porch.
const ROUTE: Array[Vector3] = [
	Vector3(-6.7, G, 0.0), Vector3(-12.4, G, 0.0), Vector3(-12.6, G, -12.0),
	Vector3(-12.6, G, -24.0), Vector3(-12.6, G, -36.0), Vector3(-12.8, G, -46.0),
	Vector3(-18.0, G, -51.0), Vector3(-23.6, G, -56.0), Vector3(-25.2, G, -61.5),
]
## Biscuit waits at these route indexes until Leo catches up.
const CROSSWALK := 5

var active := false
var _has_shoes := false
var _has_light := false
var _door_open := false
var _outside := false
var _route_i := -1
var _dog_waiting := false
var _beats := {}
var _base_fog := 0.0
var _gma_door_hinge: Node3D
var _gma_door: Interactable
var _gma_glow: MeshInstance3D
var _gma_light: OmniLight3D
var _gma_bowl: Interactable
var _gma_crickets: AudioStreamPlayer3D
var _bounds: StaticBody3D
var _candy_bars: Node3D
var _knocked := false
var _bars_taken := false
var _ended := false


func _ready() -> void:
	front_door.used.connect(_on_front_door_used)
	porch_switch.used.connect(_on_switch_used)
	window.used.connect(_on_window_used)
	set_process(false)


## Called by chapter2.gd once Dad brings Leo back in, or by main.gd with
## `jumped` when starting here (`-- --chapter=3`).
func start(jumped: bool) -> void:
	active = true
	main.chapter = 3
	main.call("_lock", true)
	main.tv_screen.channel = "static"
	_set_scene()
	Audio.play_sfx("title_sting", null, -6.0)
	await hud.show_title("Chapter 3", "The Last Light", 2.5).finished
	Audio.play_music("ch2_night", 4.0, -6.0)
	await hud.fade(0.0, 3.0).finished
	main.call("_lock", false)
	await get_tree().create_timer(1.5).timeout
	await Audio.say("ch3_intro")
	hud.set_objective("Look out the window.")


## Later the same night: everything off, Leo back on the couch.
func _set_scene() -> void:
	main.blanket.visible = true
	main.set_porch_light(false)
	main.lamp.light_energy = 0.0
	hall_light.light_energy = 0.15
	street.kill_all()
	_base_fog = main.env.fog_density
	player.teleport(Vector3(0.0, 0.05, 1.1), 0.0)

	# Dad shut the door behind them.
	door_hinge.rotation_degrees.y = 0.0
	front_door.collision_layer = 1
	front_door.enabled = true
	front_door.prompt = "Open door"

	# Biscuit waits by the door.
	dog.set_whining(false)
	dog.global_position = spot_door.global_position
	dog.go_to([spot_door.global_position], false, door_hinge.global_position + Vector3(0, 0, 0.45))
	dog.arrived.connect(func(): dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)

	# Same rooms, new thoughts.
	_reline("Interactables/Window", "ch3_window", PackedStringArray(["ch3_window_repeat"]))
	_reline("Interactables/Candy", "ch3_candy", PackedStringArray())
	_reline("Interactables/SiblingDoor", "ch3_sibling", PackedStringArray())
	(get_node("../Interactables/SiblingDoor") as Interactable).use_sfx = ""

	_make_pickup("Put on shoes", shoes_prop.global_position + Vector3(0, 0.06, 0), Vector3(0.4, 0.25, 0.3), _on_shoes)
	var torch := _make_pickup("Take flashlight", Vector3(-1.6, 0.64, 2.0), Vector3(0.35, 0.2, 0.3), _on_flashlight)
	_flashlight_model(torch)

	_build_bounds()
	_build_grandma_porch()


func _reline(path: String, first: String, repeats: PackedStringArray) -> void:
	var it := get_node("../" + path) as Interactable
	it.line_id = first
	it.repeat_line_ids = repeats
	it.times_used = 0
	it.speak = true


func _make_pickup(prompt: String, pos: Vector3, size: Vector3, callback: Callable) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt
	it.speak = false
	it.one_shot = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	it.add_child(shape)
	add_child(it)
	it.global_position = pos
	it.used.connect(func(_by): callback.call(it))
	return it


func _flashlight_model(parent: Node3D) -> void:
	var body := CSGCylinder3D.new()
	body.radius = 0.025
	body.height = 0.2
	body.rotation_degrees = Vector3(0, 30, 90)
	body.position.y = -0.015
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.15, 0.15, 0.17)
	m.metallic = 0.6
	m.roughness = 0.4
	body.material = m
	parent.add_child(body)
	var lens := CSGCylinder3D.new()
	lens.radius = 0.035
	lens.height = 0.04
	lens.position.y = 0.11
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.8, 0.8, 0.7)
	lens.material = lm
	body.add_child(lens)


# ---------------------------------------------------------------- inside

func _on_window_used(_by: Node) -> void:
	if not active or _beats.has("window"):
		return
	_beats["window"] = true
	await Audio.line_finished
	await get_tree().create_timer(0.6).timeout
	Audio.play_sfx("dog_tags", dog, -2.0)
	dog.set_whining(true)
	await Audio.say("ch3_dog_tags")
	dog.set_whining(false)
	_update_objective()


func _on_shoes(it: Interactable) -> void:
	_has_shoes = true
	shoes_prop.visible = false
	_put_away(it)
	Audio.play_sfx("candy_rustle", null, -14.0, 0.1)
	Audio.say("ch3_shoes")
	_update_objective()


func _on_flashlight(it: Interactable) -> void:
	_has_light = true
	_put_away(it)
	player.give_flashlight()
	player.set_flashlight(true)
	await Audio.say("ch3_flashlight")
	hud.show_memory("F: flashlight on/off", 4.0)
	_update_objective()


func _put_away(it: Interactable) -> void:
	it.visible = false
	it.collision_layer = 0


func _update_objective() -> void:
	if _door_open:
		return
	if _has_shoes and _has_light:
		hud.set_objective("Go outside.")
	elif _beats.has("window"):
		hud.set_objective("Get your shoes and Dad's flashlight.")


func _on_switch_used(_by: Node) -> void:
	if active:
		Audio.say("ch3_switch_dead")


func _on_front_door_used(_by: Node) -> void:
	if not active or _door_open:
		return
	if not (_has_shoes and _has_light):
		Audio.say("ch3_door_not_ready")
		_beats["window"] = true
		_update_objective()
		return
	_door_open = true
	front_door.enabled = false
	front_door.collision_layer = 0
	Audio.play_sfx("door_open", front_door, -6.0)
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) \
		.tween_property(door_hinge, "rotation_degrees:y", 100.0, 2.4)
	steps_block.disabled = true
	Audio.say("ch3_door_open")
	hud.set_objective("Follow Biscuit.")
	set_process(true)
	await get_tree().create_timer(0.8).timeout
	dog.go_to([spot_doorway.global_position, spot_porch.global_position], false, HOME)
	dog.arrived.connect(func(): _dog_waiting = true, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- the street

func _process(_delta: float) -> void:
	var p := player.global_position
	var dist_to_dog := Vector2(p.x - dog.global_position.x, p.z - dog.global_position.z).length()

	# Biscuit leads: he goes on to the next spot once Leo is close behind.
	if _dog_waiting and _route_i < ROUTE.size() - 1 and dist_to_dog < 3.5:
		if _route_i == CROSSWALK - 1 and not _beats.has("cross"):
			_beats["cross"] = true
			Audio.say("ch3_cross")
		_route_i += 1
		_dog_waiting = false
		dog.go_to([ROUTE[_route_i]], false, ROUTE[mini(_route_i + 1, ROUTE.size() - 1)])
		dog.arrived.connect(_on_dog_arrived, CONNECT_ONE_SHOT)

	if p.x < -6.2 and not _outside:
		_outside = true
		Audio.say("ch3_off_porch")
		hud.set_objective("Follow Biscuit to the last light.")
		main.fade_crickets(-30.0, 6.0)
		Audio.stop_music(6.0)
	if not _outside:
		return

	# The fog comes in off the street, then lifts again near Grandma's.
	var t := clampf((-p.z - 6.0) / 30.0, 0.0, 1.0) * (1.0 - clampf((-p.z - 48.0) / 12.0, 0.0, 1.0))
	main.env.fog_density = lerpf(_base_fog, _base_fog + 0.035, t)

	if p.z < -10.0:
		_beat("sidewalk", "ch3_sidewalk")
	if p.z < -30.0 and not _beats.has("look_back"):
		var facing := -player.camera.global_transform.basis.z
		if facing.z > 0.7:
			_beat("look_back", "ch3_look_back")
	if p.z < -52.0 and not _beats.has("crickets"):
		_beat("crickets", "ch3_crickets")
		create_tween().tween_property(_gma_crickets, "volume_db", -4.0, 4.0)
		Audio.play_music("ch1_living_room", 6.0, -4.0)
	if p.z < -58.0:
		if _beat("grandmas", "ch3_grandmas"):
			hud.set_objective("Knock on the door.")


func _beat(id: String, line: String) -> bool:
	if _beats.has(id):
		return false
	_beats[id] = true
	Audio.say(line)
	return true


func _on_dog_arrived() -> void:
	_dog_waiting = true
	if _route_i == CROSSWALK:
		dog.set_pose(Dog.Pose.SIT)
	if _route_i == ROUTE.size() - 1:
		dog.set_pose(Dog.Pose.SIT)


## Keeps Leo on the street: front yards on our side, the sidewalk across,
## and the street ends a little past Grandma's.
func _build_bounds() -> void:
	_bounds = StaticBody3D.new()
	add_child(_bounds)
	_wall(Vector3(-26.95, 1.0, -30.0), Vector3(0.4, 4.0, 84.0))   # across the street
	_wall(Vector3(-6.6, 1.0, -36.0), Vector3(0.4, 4.0, 71.0))     # our side, south of the walk
	_wall(Vector3(-6.6, 1.0, 6.5), Vector3(0.4, 4.0, 12.0))       # our side, north of the walk
	_wall(Vector3(-16.8, 1.0, 12.0), Vector3(20.8, 4.0, 0.4))     # up the street
	_wall(Vector3(-16.8, 1.0, -71.0), Vector3(20.8, 4.0, 0.4))    # down the street
	# Our porch steps become a ramp so Leo can walk down them.
	var ramp := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.95, 0.1, 1.2)
	ramp.shape = box
	ramp.position = Vector3(-6.0, -0.28, 0.0)
	ramp.rotation_degrees.z = 29.0
	_bounds.add_child(ramp)


func _wall(pos: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	_bounds.add_child(shape)


# ---------------------------------------------------------------- Grandma's

func _mat(c: Color, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


func _csg(size: Vector3, pos: Vector3, mat: Material, parent: Node, rot := Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation_degrees = rot
	b.material = mat
	parent.add_child(b)
	return b


## Her porch sits on the far house (street.far_light_pos, facing the street).
func _build_grandma_porch() -> void:
	var front_x := street.far_light_pos.x
	var z := street.far_light_pos.z
	var root := Node3D.new()
	root.position = Vector3(front_x, G, z)
	add_child(root)

	var boards := _mat(Color(0.32, 0.24, 0.17))
	var white := _mat(Color(0.85, 0.82, 0.75))
	_csg(Vector3(1.9, 0.08, 5.0), Vector3(0.95, 0.04, 0.0), boards, root)
	_csg(Vector3(0.6, 0.05, 0.9), Vector3(0.4, 0.09, 0.0), _mat(Color(0.35, 0.18, 0.1)), root) # mat
	for pz in [-2.4, 2.4]:
		_csg(Vector3(0.1, 2.3, 0.1), Vector3(1.85, 1.15, pz), white, root)
	_csg(Vector3(2.0, 0.1, 5.1), Vector3(0.95, 2.35, 0.0), _mat(Color(0.15, 0.13, 0.12)), root, Vector3(0, 0, -8))

	# The rocking chair.
	var chair := _make_static(root, Vector3(0.7, 0.0, -1.6), Vector3(0.55, 1.0, 0.55), "Look at rocking chair", "ch3_chair")
	var wood := _mat(Color(0.4, 0.26, 0.15))
	_csg(Vector3(0.5, 0.06, 0.5), Vector3(0, 0.45, 0), wood, chair)
	_csg(Vector3(0.06, 0.6, 0.5), Vector3(-0.22, 0.78, 0), wood, chair, Vector3(0, 0, 10))
	for sz in [-0.22, 0.22]:
		_csg(Vector3(0.7, 0.05, 0.04), Vector3(0, 0.08, sz), wood, chair)
		_csg(Vector3(0.04, 0.4, 0.04), Vector3(0.2, 0.26, sz), wood, chair)
		_csg(Vector3(0.04, 0.4, 0.04), Vector3(-0.2, 0.26, sz), wood, chair)
	var blanket := _csg(Vector3(0.45, 0.04, 0.46), Vector3(0.02, 0.5, 0), _mat(Color(0.55, 0.16, 0.12)), chair)
	blanket.rotation_degrees.z = -6.0

	# Table with the candy bowl. Full-size bars, orange wrappers.
	_gma_bowl = _make_static(root, Vector3(0.6, 0.0, 1.5), Vector3(0.5, 0.75, 0.5), "Look in the bowl", "ch3_bowl")
	_gma_bowl.used.connect(_on_bowl_used)
	_csg(Vector3(0.45, 0.5, 0.45), Vector3(0, 0.25, 0), white, _gma_bowl)
	var bowl := CSGCylinder3D.new()
	bowl.radius = 0.18
	bowl.height = 0.12
	bowl.position.y = 0.56
	bowl.material = _mat(Color(0.2, 0.3, 0.55))
	_gma_bowl.add_child(bowl)
	_candy_bars = Node3D.new()
	_candy_bars.position.y = 0.63
	_gma_bowl.add_child(_candy_bars)
	for i in 5:
		var bar := _csg(Vector3(0.18, 0.025, 0.06), Vector3(randf_range(-0.06, 0.06), i * 0.012, randf_range(-0.08, 0.08)),
			_mat(Color(0.95, 0.45, 0.08)), _candy_bars, Vector3(0, randf_range(0, 180), 0))
		bar.name = "Bar%d" % i

	# Her door. Inside is nothing but warm light.
	_gma_glow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.86, 1.96)
	_gma_glow.mesh = quad
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.6, 1.2, 0.75)
	glow.disable_fog = true
	_gma_glow.material_override = glow
	_gma_glow.position = Vector3(0.07, 0.99, 0.0)
	_gma_glow.rotation_degrees.y = 90.0
	_gma_glow.visible = false
	root.add_child(_gma_glow)

	_gma_light = OmniLight3D.new()
	_gma_light.light_color = Color(1, 0.75, 0.45)
	_gma_light.light_energy = 0.0
	_gma_light.omni_range = 7.0
	_gma_light.light_volumetric_fog_energy = 3.0
	_gma_light.position = Vector3(0.6, 1.2, 0.0)
	root.add_child(_gma_light)

	_gma_door_hinge = Node3D.new()
	_gma_door_hinge.position = Vector3(0.1, 0.0, -0.45)
	root.add_child(_gma_door_hinge)
	_gma_door = Interactable.new()
	_gma_door.prompt = "Knock"
	_gma_door.speak = false
	_gma_door.position = Vector3(0, 1.0, 0.45)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.08, 2.0, 0.9)
	shape.shape = box
	_gma_door.add_child(shape)
	_gma_door_hinge.add_child(_gma_door)
	_csg(Vector3(0.06, 2.0, 0.9), Vector3.ZERO, _mat(Color(0.2, 0.32, 0.25)), _gma_door)
	_csg(Vector3(0.02, 0.9, 0.6), Vector3(0.03, 0.3, 0), _mat(Color(0.95, 0.7, 0.4), 1.5), _gma_door) # lit window
	var knob := CSGSphere3D.new()
	knob.radius = 0.035
	knob.position = Vector3(0.06, -0.05, 0.36)
	knob.material = _mat(Color(0.8, 0.65, 0.3))
	_gma_door.add_child(knob)
	_gma_door.used.connect(_on_gma_door_used)

	_gma_crickets = Audio.make_loop("crickets", root, -60.0) as AudioStreamPlayer3D
	if _gma_crickets:
		_gma_crickets.unit_size = 8.0


func _make_static(parent: Node3D, pos: Vector3, size: Vector3, prompt: String, line: String) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt
	it.line_id = line
	it.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	it.add_child(shape)
	parent.add_child(it)
	return it


func _on_gma_door_used(_by: Node) -> void:
	if _knocked:
		return
	_knocked = true
	_gma_door.enabled = false
	hud.set_objective("")
	main.call("_lock", true)
	Audio.play_sfx("knock", _gma_door, 0.0)
	await get_tree().create_timer(1.2).timeout
	await Audio.say("ch3_knock")
	await get_tree().create_timer(2.0).timeout

	# The door opens on its own, onto light.
	Audio.play_sfx("door_open", _gma_door, -4.0)
	_gma_glow.visible = true
	_gma_door.collision_layer = 0
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	t.tween_property(_gma_door_hinge, "rotation_degrees:y", 105.0, 3.0)
	t.tween_property(_gma_light, "light_energy", 2.5, 3.0)
	dog.set_pose(Dog.Pose.STAND)
	dog.call("_on_petted", null) # tail going, tags jingling
	player.set_flashlight(false)
	player.tween_look_at(_gma_light.global_position, 2.5)
	await t.finished
	await get_tree().create_timer(1.0).timeout

	await Audio.say("gma_1")
	main.call("_lock", false)
	hud.set_objective("Take a candy bar.")
	_gma_bowl.line_id = ""
	_gma_bowl.prompt = "Take candy bars"
	_gma_bowl.times_used = 0


func _on_bowl_used(_by: Node) -> void:
	if not _knocked or _bars_taken:
		return
	_bars_taken = true
	_gma_bowl.enabled = false
	hud.set_objective("")
	Audio.play_sfx("candy_rustle", _gma_bowl, -4.0)
	for i in 2:
		_candy_bars.get_child(_candy_bars.get_child_count() - 1 - i).visible = false
	main.call("_lock", true)
	await get_tree().create_timer(0.8).timeout
	await Audio.say("ch3_take_bars")
	await get_tree().create_timer(1.0).timeout

	# She closes the door. Her light goes out, softly; no flicker this time.
	Audio.play_sfx("door_close", _gma_door, -8.0)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	t.tween_property(_gma_door_hinge, "rotation_degrees:y", 0.0, 2.5)
	t.tween_property(_gma_light, "light_energy", 0.0, 2.5)
	await t.finished
	_gma_glow.visible = false
	await get_tree().create_timer(1.0).timeout
	await Audio.say("ch3_goodnight")
	await get_tree().create_timer(0.5).timeout
	street.set_level(street.far_light, 0.0, 4.0)
	create_tween().tween_property(_gma_crickets, "volume_db", -60.0, 6.0)
	await get_tree().create_timer(4.0).timeout
	player.set_flashlight(true)
	await _lights_come_home()


## Every porch light comes back on, from here back toward home, and ours last.
func _lights_come_home() -> void:
	player.tween_fov(55.0, 3.0)
	await player.tween_look_at(HOME, 3.0).finished
	Audio.play_music("ending", 4.0)
	var lights := street.porch_lights.duplicate()
	lights.reverse()
	for i in lights.size():
		street.relight(lights[i], 0.8)
		if i == 1:
			Audio.say("ch3_lights_on")
		await get_tree().create_timer(0.7).timeout
	await get_tree().create_timer(0.6).timeout
	main.set_porch_light(true)
	await get_tree().create_timer(1.5).timeout
	await Audio.say("dad_call")
	await get_tree().create_timer(1.0).timeout
	player.tween_fov(player.base_fov, 2.0)
	await hud.fade(1.0, 3.0, Color(1.0, 0.94, 0.82)).finished
	await get_tree().create_timer(1.5).timeout
	_morning()


# ---------------------------------------------------------------- morning

func _morning() -> void:
	set_process(false)
	_bounds.queue_free()
	player.set_flashlight(false)
	main.set_porch_light(false)
	street.kill_all()
	street.set_level(street.far_light, 0.0, 0.0)
	main.tv_screen.channel = "off"
	main.fade_crickets(-60.0, 0.1)
	var env: Environment = main.env
	env.fog_density = _base_fog * 0.4
	env.ambient_light_color = Color(0.9, 0.85, 0.75)
	env.ambient_light_energy = 0.9
	var sky := env.sky.sky_material as ProceduralSkyMaterial
	if sky:
		sky.sky_top_color = Color(0.35, 0.5, 0.75)
		sky.sky_horizon_color = Color(0.85, 0.78, 0.65)
	moon.light_color = Color(1, 0.88, 0.7)
	moon.light_energy = 1.4
	# Low sun through the front window.
	moon.global_transform = Transform3D.IDENTITY.looking_at(Vector3(1.0, -0.35, 0.35), Vector3.UP)
	main.lamp.light_energy = 0.0
	hall_light.light_energy = 0.35

	# Two full-size bars on the coffee table.
	for i in 2:
		_csg(Vector3(0.18, 0.025, 0.06), Vector3(0.1 - i * 0.05, 0.415 + i * 0.026, 0.45 + i * 0.04),
			_mat(Color(0.95, 0.45, 0.08)), self, Vector3(0, 20 - i * 35, 0))
	main.blanket.visible = true
	shoes_prop.visible = false
	dog.go_to([Vector3(2.05, 0.05, 1.0)], false)
	dog.global_position = Vector3(2.05, 0.05, 1.0)
	dog.arrived.connect(func(): dog.set_pose(Dog.Pose.LIE), CONNECT_ONE_SHOT)
	player.teleport(Vector3(0.0, 0.05, 1.3), 0.0)
	player.head.rotation.x = deg_to_rad(-30.0)

	Audio.stop_music(1.0)
	await get_tree().create_timer(1.0).timeout
	await hud.fade(0.0, 3.0, Color(1.0, 0.94, 0.82)).finished
	await get_tree().create_timer(1.5).timeout
	await Audio.say("mom_morning_1", $"../Lights/HallLight")
	await get_tree().create_timer(1.5).timeout
	Audio.play_music("ch1_living_room", 3.0)
	await hud.fade(1.0, 3.0).finished
	await hud.show_title("End of Chapter 3", "The Last Light", 4.0).finished
	hud.show_memory("Press E to play again.", 600.0)
	_ended = true


func _unhandled_input(event: InputEvent) -> void:
	if _ended and event.is_action_pressed("interact"):
		Audio.stop_music(0.5)
		Audio.stop_voice()
		get_tree().reload_current_scene()
