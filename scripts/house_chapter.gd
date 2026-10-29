class_name HouseChapter
extends Chapter
## Base for chapters set in the family house after Halloween (the scenes
## inherit chapter_1_halloween.tscn). Puts Halloween away, stashes Chapter 1's
## dream pieces, keeps the TV glow flickering and the house sounds going.

@onready var env: Environment = $WorldEnvironment.environment
@onready var lights: Node3D = $Lights
@onready var dad: Interactable = $Story/Dad
@onready var phone: Interactable = $House/Kitchen/Things/Phone
@onready var couch: Interactable = $House/LivingRoom/Things/Couch
@onready var tv_screen: TvScreen = $House/LivingRoom/Things/TV/ScreenFeed
@onready var dog: Dog = $Biscuit
@onready var front_door: Interactable = $House/LivingRoom/Things/FrontDoor
@onready var porch_switch: Interactable = $Story/PorchSwitch
@onready var porch_light: OmniLight3D = $Lights/PorchLight
@onready var street: Street = $Street

var _flicker_t := 0.0
var _tv_energy := 0.0
var _porch_energy := 0.0
var _dream_hall: Node
var _jamie_dream: Node


func _ready() -> void:
	super._ready()
	# The house scene's environment is shared by every chapter that inherits
	# it; work on a copy so a sunny morning doesn't leak into another chapter.
	env = env.duplicate(true)
	($WorldEnvironment as WorldEnvironment).environment = env
	_tv_energy = (lights.get_node("TVGlow") as OmniLight3D).light_energy
	_porch_energy = porch_light.light_energy
	dog.player = player
	Decorations.put_away_halloween(self)
	# Chapter 1's dream pieces aren't used after Halloween.
	_dream_hall = $DreamHall
	_jamie_dream = $House/JamieRoom/JamieRoomDream
	stash(_dream_hall)
	stash(_jamie_dream)
	for it: Interactable in [phone, couch, front_door]:
		it.memory_text = ""
		it.repeat_text = ""
	phone.prompt = "Phone"
	couch.prompt = "Sit down"
	Audio.make_loop("clock_tick", $House/LivingRoom/Things/Clock, -14.0)
	Audio.make_loop("room_tone", $House/Kitchen/Things/Fridge, -10.0)


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


func hide_node(path: String) -> void:
	Decorations.hide(get_node(path) as Node3D)


func set_porch_light(on: bool) -> void:
	porch_light.light_energy = _porch_energy if on else 0.0
	($Story/PorchPaneOn as Node3D).visible = on
	(($Exterior/PorchLamp as CSGShape3D).material as StandardMaterial3D).emission_energy_multiplier = 4.0 if on else 0.0


## Something simple you can use: a colored box with a prompt.
func box_thing(node_name: String, pos: Vector3, size: Vector3, color: Color, prompt_text: String,
		first := "", again := "") -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt_text
	it.memory_text = first
	it.repeat_text = again
	it.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	it.add_child(shape)
	var mesh := CSGBox3D.new()
	mesh.size = size
	mesh.material = Decorations.mat(color)
	it.add_child(mesh)
	add_child(it)
	return it


## Swing the front door open around its hinge (its origin is its middle).
func open_front_door() -> void:
	front_door.enabled = false
	front_door.collision_layer = 0
	($Story/PorchPaneOn as Node3D).visible = false
	($Story/PorchPaneOff as Node3D).visible = false
	Audio.play_sfx("door_open", front_door)
	var hinge: Vector3 = front_door.position + Vector3(-0.5, 0, 0)
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).tween_method(func(a: float) -> void:
		front_door.rotation.y = a
		front_door.position = hinge + Vector3(cos(a), 0, -sin(a)) * 0.5, 0.0, deg_to_rad(95.0), 1.6)


func add_trigger(pos: Vector3, size: Vector3, callback: Callable) -> Trigger:
	var t := Trigger.new()
	t.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	t.add_child(shape)
	add_child(t)
	t.player_entered.connect(callback)
	return t
