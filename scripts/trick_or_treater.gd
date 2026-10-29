class_name TrickOrTreater
extends Node3D
## A kid in a costume (chapter 5). Built from simple shapes like Biscuit.
## Walks along points with a little bob; no physics, so keep paths clear.

signal arrived

const SKIN := Color(0.85, 0.66, 0.52)

@export var costume := "ghost"
@export var height := 1.15
@export var speed := 1.3

var _path: Array[Vector3] = []
var _t := 0.0
var _body: Node3D
var _bucket: Node3D


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_build()


func walk(points: Array[Vector3], pace := -1.0) -> void:
	_path = points.duplicate()
	if pace > 0.0:
		speed = pace


func is_walking() -> bool:
	return not _path.is_empty()


func face(point: Vector3) -> void:
	var to := point - global_position
	rotation.y = atan2(-to.x, -to.z)


func _process(delta: float) -> void:
	_t += delta
	var moving := not _path.is_empty()
	if moving:
		var to := _path[0] - global_position
		var flat := Vector3(to.x, 0, to.z)
		var step := speed * delta
		if flat.length() <= step:
			global_position = _path[0]
			_path.pop_front()
			if _path.is_empty():
				arrived.emit()
		else:
			global_position += flat.normalized() * step
			global_position.y = lerpf(global_position.y, _path[0].y, clampf(delta * 4.0, 0, 1))
			rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), clampf(delta * 8.0, 0, 1))
	# Bob while walking; a little fidget standing still.
	var bob := absf(sin(_t * 8.0)) * 0.04 if moving else sin(_t * 1.7) * 0.008
	_body.position.y = bob
	_body.rotation.z = sin(_t * 4.0) * (0.05 if moving else 0.015)
	if _bucket:
		_bucket.rotation.x = sin(_t * 8.0) * (0.3 if moving else 0.05)


func _m(c: Color, emission := 0.0) -> StandardMaterial3D:
	return Build.mat(c, emission)


func _sphere(parent: Node3D, r: float, pos: Vector3, c: Color, emission := 0.0) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = r
	s.radial_segments = 12
	s.rings = 6
	s.position = pos
	s.material = _m(c, emission)
	parent.add_child(s)
	return s


func _cone(parent: Node3D, r: float, h: float, pos: Vector3, c: Color) -> CSGCylinder3D:
	var c3 := Build.cylinder(parent, r, h, pos, _m(c))
	c3.cone = true
	return c3


## Body proportions scale with height: legs, torso, head.
func _build() -> void:
	var k := height / 1.15
	var head_y := 0.98 * k
	match costume:
		"ghost":
			var sheet := Color(0.95, 0.95, 0.93)
			Build.cylinder(_body, 0.26 * k, 0.9 * k, Vector3(0, 0.47 * k, 0), _m(sheet))
			_sphere(_body, 0.2 * k, Vector3(0, head_y, 0), sheet)
			for s in [-1, 1]:
				_sphere(_body, 0.035 * k, Vector3(s * 0.07 * k, head_y + 0.02, -0.18 * k), Color(0.02, 0.02, 0.02))
		"witch":
			Build.cylinder(_body, 0.2 * k, 0.75 * k, Vector3(0, 0.38 * k, 0), _m(Color(0.25, 0.1, 0.35)))
			_sphere(_body, 0.15 * k, Vector3(0, head_y - 0.1, 0), SKIN)
			Build.cylinder(_body, 0.26 * k, 0.02, Vector3(0, head_y + 0.02, 0), _m(Color(0.05, 0.05, 0.05)))
			_cone(_body, 0.15 * k, 0.4 * k, Vector3(0, head_y + 0.22, 0), Color(0.05, 0.05, 0.05))
		"pumpkin":
			_legs(k, Color(0.1, 0.25, 0.1))
			var body := _sphere(_body, 0.28 * k, Vector3(0, 0.6 * k, 0), Color(0.95, 0.45, 0.08))
			body.scale = Vector3(1, 0.85, 1)
			_sphere(_body, 0.14 * k, Vector3(0, head_y, 0), SKIN)
			Build.cylinder(_body, 0.15 * k, 0.08, Vector3(0, head_y + 0.12, 0), _m(Color(0.15, 0.4, 0.1)))
		"robot":
			_legs(k, Color(0.6, 0.62, 0.66))
			Build.box(_body, Vector3(0.42, 0.45, 0.3) * k, Vector3(0, 0.62 * k, 0), _m(Color(0.7, 0.72, 0.76)))
			Build.box(_body, Vector3(0.12, 0.08, 0.01), Vector3(0, 0.66 * k, -0.155 * k), _m(Color(1, 0.2, 0.2), 2.0))
			Build.box(_body, Vector3(0.3, 0.26, 0.28) * k, Vector3(0, head_y, 0), _m(Color(0.7, 0.72, 0.76)))
			Build.box(_body, Vector3(0.2, 0.05, 0.01) * k, Vector3(0, head_y, -0.145 * k), _m(Color(0.3, 0.8, 1.0), 2.0))
			Build.cylinder(_body, 0.01, 0.15, Vector3(0, head_y + 0.2, 0), _m(Color(0.4, 0.4, 0.4)))
			_sphere(_body, 0.025, Vector3(0, head_y + 0.28, 0), Color(1, 0.2, 0.2), 2.0)
		"skeleton":
			_legs(k, Color(0.05, 0.05, 0.05))
			Build.box(_body, Vector3(0.36, 0.45, 0.22) * k, Vector3(0, 0.62 * k, 0), _m(Color(0.05, 0.05, 0.05)))
			for i in 4:
				Build.box(_body, Vector3(0.28, 0.025, 0.01) * k, Vector3(0, (0.5 + i * 0.08) * k, -0.115 * k), _m(Color(0.9, 0.9, 0.85)))
			_sphere(_body, 0.15 * k, Vector3(0, head_y, 0), Color(0.92, 0.92, 0.88))
			for s in [-1, 1]:
				_sphere(_body, 0.035 * k, Vector3(s * 0.055 * k, head_y + 0.02, -0.12 * k), Color(0.02, 0.02, 0.02))
		_:
			# Plain clothes: the big brother, a hoodie and jeans.
			_legs(k, Color(0.2, 0.25, 0.4))
			Build.box(_body, Vector3(0.38, 0.48, 0.24) * k, Vector3(0, 0.66 * k, 0), _m(Color(0.15, 0.3, 0.2)))
			_sphere(_body, 0.15 * k, Vector3(0, head_y, 0), SKIN)
			_sphere(_body, 0.155 * k, Vector3(0, head_y + 0.04, 0.02), Color(0.2, 0.13, 0.08))
	# Everybody carries a pumpkin pail.
	_bucket = Node3D.new()
	_bucket.position = Vector3(0.24 * k, 0.55 * k, -0.05)
	_body.add_child(_bucket)
	Build.cylinder(_bucket, 0.012, 0.25, Vector3(0, 0.0, 0), _m(Color(0.1, 0.1, 0.1)))
	_sphere(_bucket, 0.1, Vector3(0, -0.18, 0), Color(1, 0.5, 0.1), 0.3)


func _legs(k: float, c: Color) -> void:
	for s in [-1, 1]:
		Build.cylinder(_body, 0.06 * k, 0.42 * k, Vector3(s * 0.08 * k, 0.21 * k, 0), _m(c))
