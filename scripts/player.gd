class_name Player
extends CharacterBody3D
## First-person controller tuned to feel like an 8-year-old:
## low eye height, short reach, slow walk, quick little sprint.

signal target_changed(target: Interactable)

@export_group("Movement")
@export var walk_speed := 2.4
@export var sprint_speed := 4.0
@export var crouch_speed := 1.2
@export var acceleration := 12.0

@export_group("Look")
@export var mouse_sensitivity := 0.0022
@export var base_fov := 75.0

@export_group("Body")
@export var stand_eye_height := 1.15
@export var crouch_eye_height := 0.65
@export var stand_height := 1.3
@export var crouch_height := 0.8

@export_group("Head bob")
@export var bob_amount := 0.03
@export var bob_frequency := 2.2

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var body_shape: CollisionShape3D = $CollisionShape3D

## Set true during cutscenes and transitions.
var input_locked := false
var crouching := false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bob_t := 0.0
var _target: Interactable = null
var _capsule: CapsuleShape3D


func _ready() -> void:
	_setup_inputs()
	_capsule = body_shape.shape as CapsuleShape3D
	camera.fov = base_fov
	ray.add_exception(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured and not input_locked:
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * mouse_sensitivity)
		head.rotate_x(-motion.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and not input_locked and _target:
		_target.interact(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	_update_crouch(delta)

	var input_dir := Vector2.ZERO
	if not input_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var speed := walk_speed
	if crouching:
		speed = crouch_speed
	elif Input.is_action_pressed("sprint") and not input_locked:
		speed = sprint_speed

	var w := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, dir.x * speed, w)
	velocity.z = lerpf(velocity.z, dir.z * speed, w)
	move_and_slide()

	_update_bob(delta)
	_update_target()


func _update_crouch(delta: float) -> void:
	crouching = Input.is_action_pressed("crouch") and not input_locked
	var h := crouch_height if crouching else stand_height
	_capsule.height = move_toward(_capsule.height, h, delta * 4.0)
	body_shape.position.y = _capsule.height / 2.0
	var eye := crouch_eye_height if crouching else stand_eye_height
	head.position.y = lerpf(head.position.y, eye, clampf(10.0 * delta, 0.0, 1.0))


func _update_bob(delta: float) -> void:
	var hspeed := Vector2(velocity.x, velocity.z).length()
	var target := Vector3.ZERO
	if is_on_floor() and hspeed > 0.2:
		_bob_t += delta * bob_frequency * TAU * (hspeed / walk_speed) * 0.5
		target = Vector3(cos(_bob_t * 0.5) * bob_amount * 0.6, sin(_bob_t) * bob_amount, 0)
	camera.position = camera.position.lerp(target, clampf(10.0 * delta, 0.0, 1.0))


func _update_target() -> void:
	var found: Interactable = null
	if ray.is_colliding() and not input_locked:
		var c := ray.get_collider()
		if c is Interactable and (c as Interactable).enabled:
			found = c
	if found != _target:
		_target = found
		target_changed.emit(_target)


## Smoothly change field of view (used for dream transitions).
func tween_fov(fov: float, time: float) -> Tween:
	var t := create_tween()
	t.tween_property(camera, "fov", fov, time)
	return t


func teleport(pos: Vector3, yaw_degrees: float = 0.0) -> void:
	global_position = pos
	rotation.y = deg_to_rad(yaw_degrees)
	head.rotation.x = 0.0
	velocity = Vector3.ZERO


func _setup_inputs() -> void:
	var map := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"crouch": [KEY_C, KEY_CTRL],
		"interact": [KEY_E],
	}
	for action: String in map:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: Key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("interact", click)
