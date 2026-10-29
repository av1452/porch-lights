class_name Dog
extends CharacterBody3D
## Biscuit, the family beagle mix. Body is built from simple meshes in code
## (swap for a rigged model later). Free mode: naps, follows Leo around,
## sniffs. Chapter scripts can take over with go_to(), sit, whine, bark.

signal arrived

enum Pose { STAND, SIT, LIE }

@export var walk_speed := 1.5
@export var run_speed := 3.2
@export var follow_distance := 1.3
## In free mode, follow Leo when he's this far away (and not too far).
@export var notice_distance := 2.4
@export var coat := Color(0.66, 0.45, 0.24)
@export var saddle := Color(0.18, 0.12, 0.08)
@export var white := Color(0.93, 0.9, 0.84)

var free_roam := true
var player: Node3D
var pose := Pose.LIE

var _path: Array[Vector3] = []
var _face_point := Vector3.INF
var _run := false
var _whining := false
var _whine_t := 0.0
var _tag_t := 0.0
var _anim_t := 0.0
var _wag := 1.0
var _petted_t := 0.0
var _stuck_t := 0.0
var _dodge_t := 0.0
var _dodge_dir := Vector3.ZERO
var _idle_t := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# rig
var _model: Node3D
var _torso: Node3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []
var _pet_body: Interactable


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.17
	capsule.height = 0.5
	shape.shape = capsule
	shape.position.y = 0.25
	add_child(shape)
	_build_model()
	_pet_body = get_node_or_null("PetBody") as Interactable
	if _pet_body:
		add_collision_exception_with(_pet_body)
		_pet_body.used.connect(_on_petted)


# ---------------------------------------------------------------- commands

## Walk (or run) through points; emits `arrived` at the last one.
func go_to(points: Array[Vector3], run := false, face: Vector3 = Vector3.INF) -> void:
	free_roam = false
	_path = points.duplicate()
	_run = run
	_face_point = face
	pose = Pose.STAND


## Back to free mode: follow Leo around on his own.
func release() -> void:
	_path.clear()
	_face_point = Vector3.INF
	free_roam = true
	pose = Pose.STAND


func set_pose(p: Pose) -> void:
	pose = p


func set_whining(on: bool) -> void:
	_whining = on
	_whine_t = 0.5


func bark(times := 1) -> void:
	for i in times:
		Audio.play_sfx("dog_bark", _head, 2.0, 0.06, 2)
		_wag = 0.0
		await get_tree().create_timer(0.45).timeout


func growl() -> void:
	_wag = 0.0
	Audio.play_sfx("dog_growl", _head, -2.0)


func set_active(on: bool) -> void:
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	collision_layer = 2 if on else 0
	if _pet_body:
		_pet_body.collision_layer = 1 if on else 0


# ---------------------------------------------------------------- behavior

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	var want := Vector3.ZERO
	var speed := walk_speed
	_petted_t -= delta

	if not _path.is_empty():
		var to := _path[0] - global_position
		to.y = 0
		if to.length() < 0.25:
			_path.pop_front()
			if _path.is_empty():
				arrived.emit()
		else:
			want = to.normalized()
			speed = run_speed if _run else walk_speed
	elif free_roam and player and _petted_t <= 0.0:
		_free_roam(delta)
		var to := player.global_position - global_position
		to.y = 0
		var d := to.length()
		if pose == Pose.STAND and d > follow_distance and d < 9.0 and _idle_t <= 0.0:
			want = to.normalized()
			speed = run_speed if d > 4.0 else walk_speed

	if _dodge_t > 0.0:
		_dodge_t -= delta
		want = (want + _dodge_dir).normalized()

	var target_vel := want * speed
	velocity.x = lerpf(velocity.x, target_vel.x, clampf(8.0 * delta, 0, 1))
	velocity.z = lerpf(velocity.z, target_vel.z, clampf(8.0 * delta, 0, 1))
	move_and_slide()

	var hspeed := Vector2(velocity.x, velocity.z).length()
	if want != Vector3.ZERO:
		pose = Pose.STAND
		if hspeed < 0.15:
			_stuck_t += delta
			if _stuck_t > 0.6:
				_stuck_t = 0.0
				_dodge_t = 0.7
				_dodge_dir = want.cross(Vector3.UP) * (1 if randf() > 0.5 else -1)
		else:
			_stuck_t = 0.0
		_turn_toward(global_position + Vector3(velocity.x, 0, velocity.z), delta, 8.0)
	elif _face_point != Vector3.INF and _path.is_empty():
		_turn_toward(_face_point, delta, 4.0)
	elif player and (_petted_t > 0.0 or (free_roam and pose != Pose.LIE)):
		_turn_toward(player.global_position, delta, 3.0)

	_sounds(delta, hspeed)
	_animate(delta, hspeed)


func _free_roam(delta: float) -> void:
	var d := global_position.distance_to(player.global_position)
	_idle_t -= delta
	match pose:
		Pose.LIE:
			# get up when Leo comes over or wanders off
			if d < notice_distance * 0.8 or d > 6.0:
				pose = Pose.STAND
				_idle_t = 0.6
		Pose.STAND:
			if d <= follow_distance + 0.2 and randf() < delta * 0.15:
				pose = Pose.SIT
		Pose.SIT:
			if d > notice_distance:
				pose = Pose.STAND


func _on_petted(_by: Node) -> void:
	_petted_t = 2.5
	_wag = 3.0
	if pose == Pose.LIE:
		pose = Pose.SIT
	Audio.play_sfx("dog_tags", self, -6.0, 0.05)


func _turn_toward(point: Vector3, delta: float, rate: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	var yaw := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(rate * delta, 0, 1))


func _sounds(delta: float, hspeed: float) -> void:
	if hspeed > 0.4:
		_tag_t -= delta * hspeed
		if _tag_t <= 0.0:
			_tag_t = randf_range(1.5, 3.0)
			Audio.play_sfx("dog_tags", self, -14.0, 0.1)
	if _whining:
		_whine_t -= delta
		if _whine_t <= 0.0:
			_whine_t = randf_range(2.5, 4.5)
			Audio.play_sfx("dog_whine", _head, -4.0, 0.08)


# ---------------------------------------------------------------- model

func _mat(c: Color, rough := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot_deg := Vector3.ZERO, rough := 0.95) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color, rough)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 12
	m.rings = 4
	return m


func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2
	m.radial_segments = 12
	m.rings = 6
	return m


func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _build_model() -> void:
	_model = _pivot(self, Vector3.ZERO)
	_torso = _pivot(_model, Vector3(0, 0.32, 0))
	# body runs along -Z (forward)
	_part(_torso, _capsule(0.12, 0.56), coat, Vector3.ZERO, Vector3(90, 0, 0))
	_part(_torso, _capsule(0.1, 0.4), saddle, Vector3(0, 0.045, 0.04), Vector3(90, 0, 0))
	_part(_torso, _sphere(0.115), white, Vector3(0, -0.03, -0.2))

	_head = _pivot(_torso, Vector3(0, 0.1, -0.27))
	_part(_head, _sphere(0.095), coat, Vector3(0, 0.03, -0.03))
	_part(_head, _capsule(0.05, 0.16), white, Vector3(0, -0.01, -0.11), Vector3(90, 0, 0))
	_part(_head, _sphere(0.022), Color(0.05, 0.04, 0.04), Vector3(0, 0.01, -0.19), Vector3.ZERO, 0.3)
	for side in [-1, 1]:
		_part(_head, _sphere(0.014), Color(0.03, 0.02, 0.02), Vector3(side * 0.045, 0.06, -0.09), Vector3.ZERO, 0.1)
		var ear := _part(_head, BoxMesh.new(), saddle.lightened(0.15), Vector3(side * 0.085, 0.0, -0.01), Vector3(0, 0, side * 12))
		ear.scale = Vector3(0.025, 0.15, 0.08)
	var collar := TorusMesh.new()
	collar.inner_radius = 0.075
	collar.outer_radius = 0.095
	_part(_torso, collar, Color(0.75, 0.08, 0.08), Vector3(0, 0.04, -0.24), Vector3(70, 0, 0), 0.6)
	_part(_torso, _sphere(0.018), Color(0.85, 0.75, 0.3), Vector3(0, -0.04, -0.3), Vector3.ZERO, 0.2)

	for p in [Vector3(-0.07, -0.05, -0.18), Vector3(0.07, -0.05, -0.18), Vector3(-0.07, -0.05, 0.18), Vector3(0.07, -0.05, 0.18)]:
		var hip := _pivot(_torso, p)
		_part(hip, _capsule(0.035, 0.28), coat, Vector3(0, -0.12, 0))
		_part(hip, _sphere(0.035), white, Vector3(0, -0.25, -0.01))
		_legs.append(hip)

	_tail = _pivot(_torso, Vector3(0, 0.06, 0.28))
	_part(_tail, _capsule(0.022, 0.24), coat, Vector3(0, 0.1, 0.03), Vector3(-20, 0, 0))
	_part(_tail, _sphere(0.024), white, Vector3(0, 0.21, 0.07))


func _animate(delta: float, hspeed: float) -> void:
	_anim_t += delta
	var k := clampf(6.0 * delta, 0, 1)
	var torso_y := 0.32
	var torso_pitch := 0.0
	var head_pitch := 0.0
	var front := 0.0
	var back := 0.0

	match pose:
		Pose.SIT:
			torso_y = 0.25
			torso_pitch = 28.0
			head_pitch = -20.0
			front = -28.0
			back = 75.0
		Pose.LIE:
			torso_y = 0.16
			head_pitch = 18.0
			front = -80.0
			back = 80.0

	_torso.position.y = lerpf(_torso.position.y, torso_y, k)
	_torso.rotation_degrees.x = lerpf(_torso.rotation_degrees.x, torso_pitch, k)

	var stride := 0.0
	if hspeed > 0.1:
		var f := 9.0 if hspeed > walk_speed + 0.3 else 7.0
		stride = sin(_anim_t * f) * clampf(hspeed / walk_speed, 0, 1.5) * 28.0
		_torso.position.y += absf(sin(_anim_t * f)) * 0.015
	for i in _legs.size():
		var base := front if i < 2 else back
		var phase := stride * (1 if i in [0, 3] else -1)
		_legs[i].rotation_degrees.x = lerpf(_legs[i].rotation_degrees.x, base + phase, clampf(14.0 * delta, 0, 1))

	# breathing, looking around, ear-perk when alert
	var breathe := 1.0 + sin(_anim_t * (5.0 if hspeed > 1 else 2.2)) * 0.015
	_torso.scale = Vector3(breathe, breathe, 1.0)
	var look := sin(_anim_t * 0.6) * 12.0 if pose != Pose.STAND or hspeed < 0.1 else 0.0
	_head.rotation_degrees.x = lerpf(_head.rotation_degrees.x, head_pitch - torso_pitch * 0.6, k)
	_head.rotation_degrees.y = lerpf(_head.rotation_degrees.y, look, k * 0.5)

	_wag = lerpf(_wag, 1.0, delta * 0.4)
	var wag_speed := 10.0 + _wag * 6.0
	_tail.rotation_degrees.z = sin(_anim_t * wag_speed) * 25.0 * _wag
	_tail.rotation_degrees.x = lerpf(_tail.rotation_degrees.x, -10.0 if _wag > 0.4 else 35.0, k)
