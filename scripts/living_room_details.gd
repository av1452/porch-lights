extends Node3D
## The little things that make the living room look lived in: a folded
## blanket and throw pillows on the couch, magazines and a stack of VHS tapes,
## school photos on the TV stand, a toy left on the rug. Plus, for Halloween
## only (Decorations.put_away_halloween hides it), paper bats taped up over
## the TV and candy wrappers on the floor.
## Positions are in the living room's space (the house scene's origin).

## Halloween-only things, so later chapters can put them away.
var halloween: Node3D


func _ready() -> void:
	_couch()
	_coffee_table()
	_tv_corner()
	_toys()
	halloween = Node3D.new()
	halloween.name = "Halloween"
	add_child(halloween)
	_paper_bats()
	_wrappers()


func _mat(c: Color) -> StandardMaterial3D:
	return Decorations.mat(c)


func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, rot := Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation_degrees = rot
	b.material = _mat(c)
	parent.add_child(b)
	return b


func _couch() -> void:
	# A plaid blanket, folded on the end of the couch: red with green stripes.
	var blanket := _box(self, Vector3(0.55, 0.07, 0.42), Vector3(-0.72, 0.485, 1.95), Color(0.6, 0.12, 0.12), Vector3(0, 8, 0))
	for k in 3:
		_box(blanket, Vector3(0.56, 0.072, 0.04), Vector3(0, 0, -0.14 + k * 0.14), Color(0.12, 0.3, 0.18))
	# Throw pillows leaning on the back.
	_box(self, Vector3(0.36, 0.34, 0.12), Vector3(-0.85, 0.66, 2.2), Color(0.8, 0.6, 0.2), Vector3(-15, 10, 6))
	_box(self, Vector3(0.36, 0.34, 0.12), Vector3(0.9, 0.66, 2.2), Color(0.2, 0.28, 0.5), Vector3(-15, -8, -5))


func _coffee_table() -> void:
	# A stack of magazines, the top one a little crooked.
	var colors := [Color(0.85, 0.2, 0.25), Color(0.2, 0.45, 0.75), Color(0.95, 0.8, 0.2)]
	for k in colors.size():
		_box(self, Vector3(0.21, 0.012, 0.28), Vector3(0.36, 0.408 + k * 0.013, 0.58), colors[k], Vector3(0, k * 9 - 6, 0))


func _tv_corner() -> void:
	# VHS tapes stacked on the floor by the TV stand, labels out.
	var labels := [Color(0.9, 0.85, 0.2), Color(0.85, 0.2, 0.2), Color(0.2, 0.5, 0.85), Color(0.95, 0.95, 0.9), Color(0.3, 0.7, 0.35)]
	for k in labels.size():
		var tape := _box(self, Vector3(0.105, 0.025, 0.19), Vector3(0.42, 0.013 + k * 0.026, -2.2), Color(0.05, 0.05, 0.06), Vector3(0, k * 7 - 10, 0))
		_box(tape, Vector3(0.002, 0.018, 0.12), Vector3(0.053, 0, 0), labels[k])
	# School photos on the end of the TV stand.
	for k in 2:
		var frame := _box(self, Vector3(0.13, 0.17, 0.02), Vector3(-1.1 + k * 0.17, 0.585, -2.18), Color(0.55, 0.4, 0.25), Vector3(-8, 15 - k * 25, 0))
		_box(frame, Vector3(0.1, 0.13, 0.004), Vector3(0, 0, 0.011), Color(0.45, 0.6, 0.75) if k == 0 else Color(0.7, 0.55, 0.45))


func _toys() -> void:
	# A toy dump truck, left on the rug.
	var truck := Node3D.new()
	truck.position = Vector3(1.25, 0.0, 0.85)
	truck.rotation_degrees.y = 35.0
	add_child(truck)
	_box(truck, Vector3(0.12, 0.06, 0.22), Vector3(0, 0.05, 0), Color(0.95, 0.75, 0.1))
	_box(truck, Vector3(0.11, 0.07, 0.12), Vector3(0, 0.1, 0.04), Color(0.9, 0.5, 0.1), Vector3(-15, 0, 0))
	for x in [-0.065, 0.065]:
		for z in [-0.07, 0.07]:
			var wheel := CSGCylinder3D.new()
			wheel.radius = 0.025
			wheel.height = 0.02
			wheel.rotation_degrees.z = 90.0
			wheel.position = Vector3(x, 0.025, z)
			wheel.material = _mat(Color(0.08, 0.08, 0.08))
			truck.add_child(wheel)


## Paper bats taped up on the wall over the TV.
func _paper_bats() -> void:
	var paper := _mat(Color(0.07, 0.06, 0.08))
	var wing := PackedVector2Array([
		Vector2(0, 0.03), Vector2(0.05, 0.06), Vector2(0.09, 0.04), Vector2(0.14, 0.07), Vector2(0.13, 0.01),
		Vector2(0.1, -0.02), Vector2(0.07, 0.0), Vector2(0.04, -0.03), Vector2(0, -0.01),
	])
	for spot in [Vector3(-1.4, 2.0, -2.49), Vector3(-0.6, 2.2, -2.49), Vector3(0.3, 1.95, -2.49), Vector3(1.0, 2.15, -2.49)]:
		var bat := Node3D.new()
		bat.position = spot
		bat.rotation_degrees.z = randf_range(-15, 15)
		halloween.add_child(bat)
		for side in [-1, 1]:
			var w := CSGPolygon3D.new()
			w.polygon = wing
			w.depth = 0.004
			w.scale = Vector3(side, 1, 1)
			w.material = paper
			bat.add_child(w)
		var body := CSGSphere3D.new()
		body.radius = 0.025
		body.material = paper
		bat.add_child(body)


## Candy wrappers on the floor where the sorting happened.
func _wrappers() -> void:
	var colors := [Color(0.9, 0.2, 0.2), Color(0.95, 0.75, 0.1), Color(0.5, 0.25, 0.1), Color(0.2, 0.6, 0.3), Color(0.6, 0.3, 0.7)]
	for k in 6:
		_box(halloween, Vector3(0.07, 0.004, 0.04), Vector3(-1.2 + k * 0.17 + randf_range(-0.05, 0.05), 0.003, 0.95 + randf_range(-0.2, 0.2)),
			colors[k % colors.size()], Vector3(0, randf_range(0, 180), 0))
