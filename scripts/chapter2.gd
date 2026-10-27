extends Node
## Chapter 2: The Porch Light. After the dream, it's the middle of the night.
## Biscuit whines at the front door. Turn the porch light back on, let him
## out, and watch the porch lights go out down the street, one at a time,
## until only one is left.

@onready var main = get_parent() # main.gd
@onready var player: Player = $"../Player"
@onready var hud: GameHud = $"../HUD"
@onready var dog: Dog = $"../Biscuit"
@onready var street: Street = $"../Street"
@onready var door_hinge: Node3D = $"../Interactables/FrontDoorHinge"
@onready var front_door: Interactable = $"../Interactables/FrontDoorHinge/FrontDoor"
@onready var porch_switch: Interactable = $"../Interactables/PorchSwitch"
@onready var spot_door: Marker3D = $"../DogSpots/InsideDoor"
@onready var spot_doorway: Marker3D = $"../DogSpots/Doorway"
@onready var spot_porch: Marker3D = $"../DogSpots/Porch"

const STREET_POINT := Vector3(-18.0, 0.6, 0.0)

var active := false
var _porch_on := false
var _door_open := false
var _sequence_started := false
var _ended := false
var _step_warned_t := 0.0


func _ready() -> void:
	front_door.used.connect(_on_front_door_used)
	porch_switch.used.connect(_on_switch_used)
	_make_trigger(Vector3(-4.4, 1.0, 0.0), Vector3(1.4, 2.0, 4.8), _on_porch_entered)
	_make_trigger(Vector3(-5.3, 1.0, 0.0), Vector3(0.6, 2.0, 1.4), _on_steps_entered)


func _make_trigger(pos: Vector3, size: Vector3, callback: Callable) -> void:
	var area := Area3D.new()
	area.collision_mask = 1
	area.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node3D):
		if body == player:
			callback.call())


func _process(delta: float) -> void:
	_step_warned_t -= delta


## Called by main.gd when Leo wakes up. `jumped` means we skipped chapter 1.
func start(jumped: bool) -> void:
	active = true
	main.chapter = 2
	main.call("_lock", true)
	if jumped:
		main.blanket.visible = true
		main.set_porch_light(false)
		main.lamp.light_energy *= 0.25
		player.teleport(Vector3(0.0, 0.05, 1.1), 0.0)
	else:
		Audio.stop_music(2.0)
		await hud.fade(1.0, 2.0).finished
	main.tv_screen.channel = "static"
	Audio.play_sfx("title_sting", null, -6.0)
	await hud.show_title("Chapter 2", "The Porch Light", 2.5).finished
	Audio.play_music("ch2_night", 4.0)

	dog.global_position = spot_door.global_position + Vector3(1.5, 0, 0.6)
	dog.go_to([spot_door.global_position], false, door_hinge.global_position + Vector3(0, 0, 0.45))
	dog.arrived.connect(func():
		dog.set_pose(Dog.Pose.SIT)
		dog.set_whining(true), CONNECT_ONE_SHOT)

	await hud.fade(0.0, 2.5).finished
	main.call("_lock", false)
	await get_tree().create_timer(2.5).timeout
	await Audio.say("ch2_dog_door")
	hud.set_objective("Biscuit wants to go out.")


func _on_switch_used(_by: Node) -> void:
	if not active:
		return
	_porch_on = not _porch_on
	main.set_porch_light(_porch_on)
	if _porch_on and porch_switch.times_used == 1:
		Audio.say("switch_ch2")
	if _porch_on and not _door_open:
		hud.set_objective("Let Biscuit out.")


func _on_front_door_used(_by: Node) -> void:
	if not active or _door_open:
		return
	if not _porch_on:
		Audio.say("front_door_dark")
		hud.set_objective("Turn on the porch light.")
		return
	_door_open = true
	front_door.enabled = false
	# It swings back against the wall; don't let it shove Leo or Biscuit.
	front_door.collision_layer = 0
	Audio.play_sfx("door_open", front_door)
	create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) \
		.tween_property(door_hinge, "rotation_degrees:y", 100.0, 1.6)
	main.fade_crickets(0.0, 1.5)
	Audio.say("front_door_open")
	hud.set_objective("Follow Biscuit.")
	dog.set_whining(false)
	await get_tree().create_timer(0.8).timeout
	dog.go_to([spot_doorway.global_position, spot_porch.global_position], true, STREET_POINT)
	dog.arrived.connect(func(): dog.set_pose(Dog.Pose.SIT), CONNECT_ONE_SHOT)


func _on_steps_entered() -> void:
	if active and not _sequence_started and _step_warned_t <= 0.0:
		_step_warned_t = 8.0
		Audio.say("porch_steps_block")


func _on_porch_entered() -> void:
	if not active or not _door_open or _sequence_started:
		return
	_sequence_started = true
	await get_tree().create_timer(2.0).timeout
	_porch_sequence()


func _porch_sequence() -> void:
	main.call("_lock", true)
	hud.set_objective("")
	await player.tween_look_at(STREET_POINT, 2.0).finished
	main.fade_crickets(-60.0, 4.0)
	Audio.stop_music(5.0)
	await get_tree().create_timer(2.5).timeout
	await Audio.say("porch_quiet")
	await get_tree().create_timer(1.0).timeout

	var lights := street.porch_lights
	for i in lights.size():
		var e: Dictionary = lights[i]
		var at: Vector3 = (e.light as Node3D).global_position
		player.tween_look_at(at, 0.9)
		await get_tree().create_timer(0.7).timeout
		street.kill_light(e)
		Audio.play_sfx("light_out", at, 8.0)
		if i == 2:
			Audio.say("lights_out")
		if i == 6:
			dog.set_pose(Dog.Pose.STAND)
			dog.growl()
		await get_tree().create_timer(0.9 if i < 3 else 0.6).timeout

	var far: Vector3 = (street.far_light.light as Node3D).global_position
	player.tween_fov(30.0, 4.0)
	await player.tween_look_at(far, 3.0).finished
	await get_tree().create_timer(1.0).timeout
	await Audio.say("last_light")
	await get_tree().create_timer(1.5).timeout
	player.tween_fov(player.base_fov, 1.0)

	# Our own light gives out.
	Audio.play_sfx("bulb_flicker", main.porch_light, 2.0)
	for i in 7:
		main.set_porch_light(i % 2 == 1)
		await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
	main.set_porch_light(false)
	await get_tree().create_timer(0.6).timeout
	await dog.bark(2)
	await get_tree().create_timer(1.5).timeout

	await hud.fade(1.0, 2.0).finished
	await get_tree().create_timer(1.0).timeout
	await Audio.say("dad_1")
	await get_tree().create_timer(1.0).timeout
	await Audio.say("leo_final")
	await get_tree().create_timer(1.5).timeout
	Audio.play_music("ending", 3.0)
	await hud.show_title("End of Chapter 2", "To be continued...", 4.0).finished
	hud.show_memory("Press E to play again.", 600.0)
	_ended = true


func _unhandled_input(event: InputEvent) -> void:
	if _ended and event.is_action_pressed("interact"):
		Audio.stop_music(0.5)
		Audio.stop_voice()
		get_tree().reload_current_scene()
