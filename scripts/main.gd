extends Node3D
## Chapter 1 prototype: Halloween night in the living room.
## Lie on the couch to fall asleep. In the dream, the hallway keeps going.

@onready var player: Player = $Player
@onready var hud: GameHud = $HUD
@onready var env: Environment = $WorldEnvironment.environment
@onready var lamp: OmniLight3D = $Lights/Lamp
@onready var tv_glow: OmniLight3D = $Lights/TVGlow
@onready var room: Node3D = $Room
@onready var hall_end_wall: Node3D = $Room/HallEndWall
@onready var dream_hall: Node3D = $DreamHall
@onready var couch: Interactable = $Interactables/Couch
@onready var dream_door: Interactable = $DreamHall/DreamDoor

var dreaming := false
var _busy := false
var _awake_state := {}
var _flicker_t := 0.0


func _ready() -> void:
	player.target_changed.connect(hud.set_target)
	couch.used.connect(_on_couch_used)
	dream_door.used.connect(_on_dream_door_used)

	_awake_state = {
		"fog_density": env.fog_density,
		"fog_light_color": env.fog_light_color,
		"ambient_light_color": env.ambient_light_color,
		"ambient_light_energy": env.ambient_light_energy,
		"background_color": env.background_color,
		"lamp_energy": lamp.light_energy,
		"tv_energy": tv_glow.light_energy,
		"tv_color": tv_glow.light_color,
	}
	remove_child(dream_hall) # only exists while dreaming
	hud.fade(0.0, 2.5)

	await get_tree().create_timer(1.5).timeout
	hud.show_memory("Halloween night. Your costume is half off and your pillowcase is heavy.", 6.0)


func _exit_tree() -> void:
	# Free whichever pieces are currently detached from the scene.
	if not dream_hall.is_inside_tree():
		dream_hall.free()
	if not hall_end_wall.is_inside_tree():
		hall_end_wall.free()


func _process(delta: float) -> void:
	# CRT glow flicker.
	_flicker_t -= delta
	if _flicker_t > 0.0:
		return
	_flicker_t = randf_range(0.05, 0.25)
	var base: float = _awake_state.tv_energy * (0.6 if dreaming else 1.0)
	tv_glow.light_energy = base * randf_range(0.7, 1.15)
	if dreaming:
		tv_glow.light_color = Color.from_hsv(randf_range(0.7, 0.85), 0.6, 1.0)


func _lock(locked: bool) -> void:
	player.input_locked = locked
	hud.set_crosshair_visible(not locked)


func _on_couch_used(_by: Node) -> void:
	if dreaming or _busy:
		return
	_busy = true
	_lock(true)

	# Drift off: the room softens and gets far away.
	var t := create_tween().set_parallel(true)
	t.tween_property(player.camera, "fov", 100.0, 5.0)
	t.tween_property(env, "fog_density", 0.12, 5.0)
	t.tween_property(lamp, "light_energy", 0.3, 5.0)
	await get_tree().create_timer(3.0).timeout
	await hud.fade(1.0, 2.5).finished

	_enter_dream()
	await get_tree().create_timer(1.5).timeout
	await hud.fade(0.0, 3.0).finished
	_lock(false)
	_busy = false
	hud.show_memory("The hallway is longer than it should be.", 5.0)


func _enter_dream() -> void:
	dreaming = true
	add_child(dream_hall)
	room.remove_child(hall_end_wall)
	lamp.light_energy = 0.0
	env.ambient_light_color = Color(0.3, 0.25, 0.5)
	env.ambient_light_energy = 0.5
	env.background_color = Color(0.03, 0.02, 0.07)
	env.fog_light_color = Color(0.2, 0.15, 0.35)
	env.fog_density = 0.06
	player.camera.fov = 90.0
	player.teleport(Vector3(2.0, 0.05, -2.0), 0.0)


func _on_dream_door_used(_by: Node) -> void:
	if not dreaming or _busy:
		return
	_busy = true
	_lock(true)
	await get_tree().create_timer(2.0).timeout
	await hud.fade(1.0, 2.5, Color(1.0, 0.94, 0.82)).finished

	_exit_dream()
	player.teleport(Vector3(0.0, 0.05, 1.1), 0.0)
	await get_tree().create_timer(1.0).timeout
	await hud.fade(0.0, 3.0).finished
	_lock(false)
	_busy = false
	hud.show_memory("Someone turned off the porch light. You don't remember getting a blanket.", 6.0)


func _exit_dream() -> void:
	dreaming = false
	remove_child(dream_hall)
	room.add_child(hall_end_wall)
	env.fog_density = _awake_state.fog_density
	env.fog_light_color = _awake_state.fog_light_color
	env.ambient_light_color = _awake_state.ambient_light_color
	env.ambient_light_energy = _awake_state.ambient_light_energy
	env.background_color = _awake_state.background_color
	lamp.light_energy = _awake_state.lamp_energy
	tv_glow.light_color = _awake_state.tv_color
	player.camera.fov = player.base_fov
