class_name Player
extends CharacterBody3D
## Leo. First-person controller tuned to feel like an 8-year-old:
## low eye height, short reach, slow walk, quick little sprint.

signal target_changed(target: Interactable)

@export_group("Movement")
@export var walk_speed := 2.4
@export var sprint_speed := 4.0
@export var crouch_speed := 1.2
@export var acceleration := 12.0

@export_group("Look")
@export var mouse_sensitivity := 0.0022
## Right stick, full tilt, in radians per second (times the sensitivity setting).
@export var stick_look_speed := 2.6
@export var base_fov := 75.0

@export_group("Body")
@export var stand_eye_height := 1.15
@export var crouch_eye_height := 0.65
@export var stand_height := 1.3
@export var crouch_height := 0.8
@export var seated_eye_height := 0.92

@export_group("Head bob")
@export var bob_amount := 0.03
@export var bob_frequency := 2.2

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var body_shape: CollisionShape3D = $CollisionShape3D

## Set true during cutscenes and transitions.
var input_locked := false
var _run_on := false
var _crouch_on := false
var crouching := false
## While seated you can look around but not walk.
var seated := false
## Something out of arm's reach you can still use by looking at it: Jamie
## across the yard with a snowball in your hand, the dice from the couch.
## Looking within `aim_degrees` of `aim_point` targets it. Clear with aim_at(null).
var aim_target: Interactable = null
var aim_point := Vector3.ZERO
var aim_degrees := 10.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bob_t := 0.0
var _target: Interactable = null
var _capsule: CapsuleShape3D
var _step_index := 0
## Set a "surface" metadata string on floor nodes ("wood", "porch") to pick
## footstep sounds.
var _surface := "wood"


func _ready() -> void:
	_setup_inputs()
	add_to_group("player")
	_capsule = body_shape.shape as CapsuleShape3D
	base_fov = Game.settings.fov
	camera.fov = base_fov
	ray.add_exception(self)
	ray.collision_mask |= Dog.PET_LAYER # so Biscuit can be petted without being a wall
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured and not input_locked:
		var motion := event as InputEventMouseMotion
		var sens: float = mouse_sensitivity * Game.settings.sensitivity
		rotate_y(-motion.relative.x * sens)
		head.rotate_x(-motion.relative.y * sens * (-1.0 if Game.settings.invert_y else 1.0))
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	elif event.is_action_pressed("pause") and not Controls.is_pad(event):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and not input_locked and _target:
		_target.interact(self)
	# Toggle run / toggle crouch (Settings > Controls): tap once instead of holding.
	elif event.is_action_pressed("sprint") and Game.settings.toggle_run:
		_run_on = not _run_on
	elif event.is_action_pressed("crouch") and Game.settings.toggle_crouch:
		_crouch_on = not _crouch_on


## Field of view, from Settings. Leaves cutscene zooms alone.
func apply_settings() -> void:
	var was := base_fov
	base_fov = Game.settings.fov
	if is_equal_approx(camera.fov, was):
		camera.fov = base_fov


func _process(delta: float) -> void:
	# Right stick look, eased so small tilts are precise and full tilt turns fast.
	if input_locked or get_tree().paused:
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look == Vector2.ZERO:
		return
	look *= look.length()
	var speed: float = stick_look_speed * Game.settings.sensitivity * delta
	rotate_y(-look.x * speed)
	head.rotate_x(-look.y * speed * 0.8 * (-1.0 if Game.settings.invert_y else 1.0))
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))


func _physics_process(delta: float) -> void:
	if seated:
		velocity = Vector3.ZERO
		_update_crouch(delta)
		_update_bob(delta)
		_update_target()
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta

	_update_crouch(delta)

	var input_dir := Vector2.ZERO
	if not input_locked and not seated:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var speed := walk_speed
	if crouching:
		speed = crouch_speed
	elif _running() and not input_locked:
		speed = sprint_speed

	var w := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, dir.x * speed, w)
	velocity.z = lerpf(velocity.z, dir.z * speed, w)
	move_and_slide()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y > 0.7 and c.get_collider() is Object:
			_surface = str((c.get_collider() as Object).get_meta("surface", "wood"))

	_update_bob(delta)
	_update_target()


func _update_crouch(delta: float) -> void:
	var want_crouch := _crouch_on if Game.settings.toggle_crouch else Input.is_action_pressed("crouch")
	crouching = want_crouch and not input_locked and not seated
	var h := crouch_height if crouching else stand_height
	_capsule.height = move_toward(_capsule.height, h, delta * 4.0)
	body_shape.position.y = _capsule.height / 2.0
	var eye := stand_eye_height
	if seated:
		eye = seated_eye_height
	elif crouching:
		eye = crouch_eye_height
	head.position.y = lerpf(head.position.y, eye, clampf(10.0 * delta, 0.0, 1.0))


func _running() -> bool:
	return _run_on if Game.settings.toggle_run else Input.is_action_pressed("sprint")


func _update_bob(delta: float) -> void:
	var hspeed := Vector2(velocity.x, velocity.z).length()
	var target := Vector3.ZERO
	if is_on_floor() and hspeed > 0.2:
		_bob_t += delta * bob_frequency * TAU * (hspeed / walk_speed) * 0.5
		var bob := bob_amount if Game.settings.head_bob else 0.0
		target = Vector3(cos(_bob_t * 0.5) * bob * 0.6, sin(_bob_t) * bob, 0)
		var step := int(_bob_t / PI)
		if step != _step_index:
			_step_index = step
			var vol := -14.0 if crouching else (-4.0 if hspeed > walk_speed + 0.3 else -8.0)
			# Dreams echo; soft, dreamy footsteps instead of loud ones.
			if Audio.dreaming:
				vol -= 12.0
			Audio.play_sfx("footstep_" + _surface, global_position, vol, 0.08, 4)
	camera.position = camera.position.lerp(target, clampf(10.0 * delta, 0.0, 1.0))


func _update_target() -> void:
	var found: Interactable = null
	if aim_target and is_instance_valid(aim_target) and aim_target.enabled and not input_locked:
		var to := aim_point - camera.global_position
		if (-camera.global_basis.z).angle_to(to) < deg_to_rad(aim_degrees):
			found = aim_target
	if found == null and ray.is_colliding() and not input_locked:
		var c := ray.get_collider()
		if c is Interactable and (c as Interactable).enabled:
			found = c
	if found != _target:
		_target = found
		target_changed.emit(_target)


## Lets `it` be used by looking toward `point` from anywhere (see aim_target).
func aim_at(it: Interactable, point := Vector3.ZERO, degrees := 10.0) -> void:
	aim_target = it
	aim_point = point
	aim_degrees = degrees


## Smoothly change field of view (used for dream transitions).
func tween_fov(fov: float, time: float) -> Tween:
	var t := create_tween()
	t.tween_property(camera, "fov", fov, time)
	return t


## Smoothly turn body and head to face a world point (for cutscenes).
func tween_look_at(point: Vector3, time: float) -> Tween:
	var to := point - head.global_position
	var yaw := atan2(-to.x, -to.z)
	var pitch := atan2(to.y, Vector2(to.x, to.z).length())
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "rotation:y", rotation.y + wrapf(yaw - rotation.y, -PI, PI), time)
	t.tween_property(head, "rotation:x", pitch, time)
	return t


func teleport(pos: Vector3, yaw_degrees: float = 0.0) -> void:
	global_position = pos
	rotation.y = deg_to_rad(yaw_degrees)
	head.rotation.x = 0.0
	velocity = Vector3.ZERO


## Sit at a spot (chair, couch). Movement stops; looking still works.
func sit(pos: Vector3, yaw_degrees: float) -> void:
	teleport(pos, yaw_degrees)
	seated = true
	body_shape.disabled = true


func stand(pos: Vector3, yaw_degrees: float) -> void:
	seated = false
	body_shape.disabled = false
	teleport(pos, yaw_degrees)


func _setup_inputs() -> void:
	Controls.setup()
