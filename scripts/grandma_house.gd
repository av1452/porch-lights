class_name GrandmaHouse
extends Node3D
## Grandma's real house (chapter 4), built in code far off to the side of the
## neighborhood. Local origin: floor level, front wall at x = 0. The living
## room is z 0..5, the kitchen z -5..0, and the front door opens west (-X)
## onto the porch, where the family car waits in the drive.

const W := 7.0
const D := 10.0
const H := 2.6

## Memories Leo can find, by id: chair, photo, leo_box, fridge, recipe, pantry.
var memories := {}
var porch_lamp: Interactable
var bulb: CSGBox3D
var pantry_door: Node3D

var _wall_mat: StandardMaterial3D
var _sheet := Build.mat(Color(0.9, 0.9, 0.86))
var _cardboard := Build.mat(Color(0.62, 0.47, 0.3))
var _wood := Build.mat(Color(0.45, 0.3, 0.18))


func _ready() -> void:
	_wall_mat = Build.mat(Color(0.78, 0.72, 0.6))
	_shell()
	_living_room()
	_kitchen()
	_porch_and_yard()


func _wall(pos: Vector3, size: Vector3, m: Material = null) -> void:
	Build.box(self, size, pos, m if m else _wall_mat, true)


func _shell() -> void:
	var floor_box := Build.box(self, Vector3(W, 0.1, D), Vector3(W / 2, -0.05, 0), Build.mat(Color(0.42, 0.3, 0.2), 0.0, 0.7), true)
	floor_box.set_meta("surface", "wood")
	Build.box(self, Vector3(W, 0.1, D), Vector3(W / 2, H + 0.05, 0), Build.mat(Color(0.92, 0.9, 0.85)), true)
	_wall(Vector3(W / 2, H / 2, -D / 2), Vector3(W, H, 0.15))
	_wall(Vector3(W / 2, H / 2, D / 2), Vector3(W, H, 0.15))
	_wall(Vector3(W, H / 2, 0), Vector3(0.15, H, D))
	# Front wall, with the door at z 1.9..2.9.
	var siding := Build.mat(Color(0.86, 0.82, 0.7))
	_wall(Vector3(0, H / 2, -1.55), Vector3(0.15, H, 6.9), siding)
	_wall(Vector3(0, H / 2, 3.95), Vector3(0.15, H, 2.1), siding)
	_wall(Vector3(0, 2.35, 2.4), Vector3(0.15, 0.5, 1.0), siding)
	# The door stands open against the wall inside.
	Build.box(self, Vector3(0.9, 2.05, 0.05), Vector3(0.52, 1.03, 1.93), Build.mat(Color(0.2, 0.32, 0.25)))
	# Living room / kitchen wall, doorway at x 2.8..4.0.
	_wall(Vector3(1.4, H / 2, 0), Vector3(2.8, H, 0.12))
	_wall(Vector3(5.5, H / 2, 0), Vector3(3.0, H, 0.12))
	_wall(Vector3(3.4, 2.35, 0), Vector3(1.2, 0.5, 0.12))

	_window(Vector3(0, 1.4, 4.1), Vector3.RIGHT)
	_window(Vector3(0, 1.4, -2.6), Vector3.RIGHT)
	_window(Vector3(W, 1.4, 2.5), Vector3.LEFT)
	_window(Vector3(3.5, 1.5, -D / 2), Vector3.BACK)

	# Roof: a gable along Z.
	var roof := CSGPolygon3D.new()
	roof.polygon = PackedVector2Array([Vector2(-W / 2 - 0.4, 0), Vector2(0, 2.0), Vector2(W / 2 + 0.4, 0)])
	roof.depth = D + 0.8
	roof.position = Vector3(W / 2, H + 0.1, D / 2 + 0.4)
	roof.material = Build.mat(Color(0.25, 0.2, 0.2))
	add_child(roof)

	# Overcast daylight through the windows, plus the ceiling lights.
	Build.light(self, Vector3(3.5, 2.3, 2.5), Color(1, 0.85, 0.65), 0.7, 6.0, true)
	Build.light(self, Vector3(3.5, 2.3, -2.5), Color(1, 0.88, 0.7), 0.7, 6.0, true)


## A window cut by light alone: a glowing pane through the wall, a frame,
## curtains. `inward` points into the room.
func _window(pos: Vector3, inward: Vector3) -> void:
	var rot := Vector3(0, 90.0 if inward.x != 0.0 else 0.0, 0)
	Build.box(self, Vector3(1.1, 1.0, 0.18), pos, Build.mat(Color(0.82, 0.86, 0.92), 1.1), false, rot)
	var frame := Build.mat(Color(0.95, 0.94, 0.9))
	Build.box(self, Vector3(1.2, 0.06, 0.22), pos + Vector3(0, -0.53, 0), frame, false, rot)
	Build.box(self, Vector3(1.2, 0.06, 0.22), pos + Vector3(0, 0.53, 0), frame, false, rot)
	var light := Build.light(self, pos + inward * 0.8, Color(0.8, 0.85, 0.95), 0.5, 4.0)
	light.light_volumetric_fog_energy = 0.5
	var curtain := Build.mat(Color(0.7, 0.35, 0.3))
	var side := Vector3(0, 0, 1) if inward.x != 0.0 else Vector3(1, 0, 0)
	for s in [-1, 1]:
		Build.box(self, Vector3(0.25, 1.3, 0.04), pos + side * s * 0.68 + inward * 0.12 + Vector3(0, -0.05, 0), curtain, false, rot)


func _label(parent: Node3D, text: String, pos: Vector3, yaw := 0.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 28
	l.pixel_size = 0.004
	l.modulate = Color(0.1, 0.1, 0.12)
	l.outline_size = 0
	l.position = pos
	l.rotation_degrees.y = yaw
	parent.add_child(l)


func _living_room() -> void:
	Build.box(self, Vector3(3.0, 0.02, 2.2), Vector3(3.6, 0.01, 2.6), Build.mat(Color(0.5, 0.18, 0.14)))
	# The couch, under a sheet.
	Build.box(self, Vector3(0.9, 0.8, 2.2), Vector3(6.4, 0.4, 2.6), _sheet, true)
	Build.box(self, Vector3(0.3, 0.5, 2.3), Vector3(6.75, 0.95, 2.6), _sheet)

	# Her rocking chair, under a sheet. It looks like a ghost.
	var chair := Build.interactable(self, Vector3(5.5, 0, 4.2), Vector3(0.75, 1.2, 0.75), "Look at the sheet", "ch4_chair", Vector3(0, 0.6, 0))
	Build.cylinder(chair, 0.38, 0.95, Vector3(0, 0.48, 0), _sheet)
	var head := CSGSphere3D.new()
	head.radius = 0.3
	head.position.y = 0.98
	head.material = _sheet
	chair.add_child(head)
	memories["chair"] = chair

	# Fireplace and mantel on the south wall, with the photo.
	var brick := Build.mat(Color(0.5, 0.25, 0.2))
	Build.box(self, Vector3(1.6, 1.1, 0.4), Vector3(3.0, 0.55, 4.72), brick, true)
	Build.box(self, Vector3(0.9, 0.7, 0.1), Vector3(3.0, 0.4, 4.52), Build.mat(Color(0.05, 0.04, 0.04)))
	Build.box(self, Vector3(1.9, 0.08, 0.5), Vector3(3.0, 1.14, 4.7), _wood)
	var photo := Build.interactable(self, Vector3(3.0, 1.32, 4.6), Vector3(0.4, 0.35, 0.2), "Look at photo", "ch4_photo")
	Build.box(photo, Vector3(0.3, 0.26, 0.03), Vector3(0, 0, 0.02), Build.mat(Color(0.75, 0.6, 0.3)), false, Vector3(-8, 180, 0))
	Build.box(photo, Vector3(0.24, 0.2, 0.01), Vector3(0, 0, 0.0), Build.mat(Color(0.25, 0.2, 0.25)), false, Vector3(-8, 180, 0))
	# The porch light in the photo, glowing orange.
	Build.box(photo, Vector3(0.03, 0.03, 0.012), Vector3(-0.07, 0.05, -0.006), Build.mat(Color(1, 0.55, 0.15), 3.0))
	memories["photo"] = photo
	for x in [2.35, 3.65]:
		Build.box(self, Vector3(0.12, 0.2, 0.02), Vector3(x, 1.28, 4.85), Build.mat(Color(0.5, 0.45, 0.4)))

	# Moving boxes.
	var stacks := [["BOOKS", Vector3(0.6, 0, 3.6)], ["LINENS", Vector3(0.6, 0, 0.8)], ["KITCHEN", Vector3(2.0, 0, 0.7)], ["XMAS", Vector3(0.6, 0.4, 0.8)]]
	for s in stacks:
		var b := Build.box(self, Vector3(0.55, 0.4, 0.45), s[1] + Vector3(0, 0.2, 0), _cardboard, true)
		_label(b, s[0], Vector3(0.28, 0.02, 0), 90.0)
	var leo_box := Build.interactable(self, Vector3(1.6, 0, 4.3), Vector3(0.6, 0.45, 0.5), "Open the box marked LEO", "ch4_leo_box", Vector3(0, 0.22, 0))
	Build.box(leo_box, Vector3(0.55, 0.38, 0.45), Vector3(0, 0.19, 0), _cardboard)
	_label(leo_box, "LEO", Vector3(0, 0.2, -0.23), 180.0)
	for i in 3:
		Build.box(leo_box, Vector3(0.3, 0.005, 0.22), Vector3(-0.05 + i * 0.04, 0.39 + i * 0.004, 0), Build.mat([Color(0.95, 0.95, 0.9), Color(0.9, 0.95, 1), Color(1, 0.95, 0.85)][i]), false, Vector3(0, i * 15 - 15, 0))
	memories["leo_box"] = leo_box

	# An empty bookshelf, a few books left.
	Build.box(self, Vector3(0.35, 1.8, 1.2), Vector3(6.8, 0.9, 4.2), _wood, true)
	Build.box(self, Vector3(0.25, 0.25, 0.3), Vector3(6.75, 1.0, 4.4), Build.mat(Color(0.2, 0.3, 0.45)))

	var clock := Build.cylinder(self, 0.16, 0.04, Vector3(W - 0.1, 1.9, 1.0), _wood, Vector3(0, 0, 90))
	clock.sides = 20


func _kitchen() -> void:
	var counter := Build.mat(Color(0.75, 0.68, 0.5))
	var top := Build.mat(Color(0.88, 0.86, 0.8), 0.0, 0.4)
	Build.box(self, Vector3(4.2, 0.9, 0.6), Vector3(3.5, 0.45, -4.6), counter, true)
	Build.box(self, Vector3(4.25, 0.04, 0.65), Vector3(3.5, 0.92, -4.6), top)
	Build.box(self, Vector3(4.2, 0.7, 0.35), Vector3(3.5, 2.0, -4.75), counter)
	Build.box(self, Vector3(0.7, 0.12, 0.45), Vector3(3.5, 0.88, -4.6), Build.mat(Color(0.6, 0.62, 0.65), 0.0, 0.3)) # sink

	# Fridge, with Leo's drawing.
	var fridge := Build.interactable(self, Vector3(6.4, 0, -4.4), Vector3(0.85, 1.8, 0.75), "Look at the fridge", "ch4_fridge", Vector3(0, 0.9, 0))
	Build.box(fridge, Vector3(0.8, 1.8, 0.7), Vector3(0, 0.9, 0), Build.mat(Color(0.9, 0.9, 0.85), 0.0, 0.4))
	Build.box(fridge, Vector3(0.32, 0.24, 0.01), Vector3(-0.08, 1.3, 0.355), Build.mat(Color(0.97, 0.96, 0.9)))
	Build.box(fridge, Vector3(0.14, 0.06, 0.012), Vector3(-0.1, 1.28, 0.357), Build.mat(Color(0.66, 0.45, 0.24))) # Biscuit, sort of
	for i in 6:
		Build.box(fridge, Vector3(0.008, 0.05, 0.012), Vector3(-0.155 + i * 0.022, 1.23, 0.358), Build.mat(Color(0.3, 0.2, 0.1)))
	memories["fridge"] = fridge

	# Table, chairs, and her recipe card.
	Build.box(self, Vector3(1.2, 0.05, 0.8), Vector3(3.5, 0.75, -2.3), _wood, true)
	for x in [-0.5, 0.5]:
		for z in [-0.32, 0.32]:
			Build.box(self, Vector3(0.05, 0.73, 0.05), Vector3(3.5 + x, 0.365, -2.3 + z), _wood)
	for x in [2.6, 4.4]:
		Build.box(self, Vector3(0.4, 0.05, 0.4), Vector3(x, 0.45, -2.3), _wood, true)
		Build.box(self, Vector3(0.05, 0.5, 0.4), Vector3(x + (-0.18 if x < 3.5 else 0.18), 0.7, -2.3), _wood)
	var recipe := Build.interactable(self, Vector3(3.3, 0.8, -2.2), Vector3(0.3, 0.1, 0.25), "Read the recipe card", "ch4_recipe")
	Build.box(recipe, Vector3(0.15, 0.004, 0.1), Vector3(0, -0.02, 0), Build.mat(Color(0.98, 0.96, 0.88)), false, Vector3(0, 12, 0))
	memories["recipe"] = recipe

	# The pantry, and what's inside.
	# Open-fronted cabinet: back, sides, top and a shelf.
	Build.box(self, Vector3(0.9, 2.1, 0.04), Vector3(0.6, 1.05, -4.88), counter, true)
	for x in [0.17, 1.03]:
		Build.box(self, Vector3(0.04, 2.1, 0.6), Vector3(x, 1.05, -4.6), counter, true)
	Build.box(self, Vector3(0.9, 0.04, 0.6), Vector3(0.6, 2.08, -4.6), counter)
	Build.box(self, Vector3(0.84, 0.03, 0.56), Vector3(0.6, 0.96, -4.6), counter)
	pantry_door = Node3D.new()
	pantry_door.position = Vector3(0.15, 0, -4.28)
	add_child(pantry_door)
	Build.box(pantry_door, Vector3(0.88, 2.0, 0.04), Vector3(0.44, 1.02, 0), Build.mat(Color(0.7, 0.62, 0.45)))
	var pantry := Build.interactable(self, Vector3(0.6, 1.0, -4.2), Vector3(0.9, 2.0, 0.2), "Open the pantry", "ch4_pantry")
	pantry.one_shot = true
	var crate := Build.box(self, Vector3(0.45, 0.25, 0.3), Vector3(0.6, 1.1, -4.6), _cardboard)
	_label(crate, "HALLOWEEN\nFULL SIZE ONLY", Vector3(0, 0, 0.16))
	for i in 4:
		Build.candy_bar(crate, Vector3(-0.12 + i * 0.08, 0.13, 0.0), 90.0)
	memories["pantry"] = pantry
	pantry.used.connect(func(_by):
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(pantry_door, "rotation_degrees:y", -110.0, 1.2))


func _porch_and_yard() -> void:
	var grass := Build.mat(Color(0.26, 0.24, 0.14))
	var ground := Build.box(self, Vector3(40, 0.2, 40), Vector3(0, -0.1, 0), grass, true)
	ground.set_meta("surface", "porch")
	var boards := Build.mat(Color(0.4, 0.32, 0.24))
	var white := Build.mat(Color(0.92, 0.9, 0.85))
	Build.box(self, Vector3(2.2, 0.03, 4.6), Vector3(-1.1, 0.015, 2.4), boards)
	for z in [0.15, 4.65]:
		Build.box(self, Vector3(0.1, 2.4, 0.1), Vector3(-2.15, 1.2, z), white)
		Build.box(self, Vector3(2.2, 0.06, 0.06), Vector3(-1.1, 0.85, z), white)
	Build.box(self, Vector3(2.4, 0.1, 4.9), Vector3(-1.1, 2.45, 2.4), Build.mat(Color(0.3, 0.25, 0.22)), false, Vector3(0, 0, -6))
	# A dead geranium, a doormat.
	Build.cylinder(self, 0.16, 0.25, Vector3(-0.4, 0.13, 3.6), Build.mat(Color(0.6, 0.3, 0.2)))
	Build.box(self, Vector3(0.6, 0.02, 0.9), Vector3(-0.4, 0.03, 2.4), Build.mat(Color(0.35, 0.22, 0.12)))

	# Her porch lamp, the orange bulb. Off.
	Build.box(self, Vector3(0.12, 0.08, 0.2), Vector3(-0.1, 2.12, 1.5), Build.mat(Color(0.15, 0.15, 0.15)))
	bulb = Build.box(self, Vector3(0.1, 0.14, 0.1), Vector3(-0.12, 1.98, 1.5), Build.mat(Color(1, 0.55, 0.2), 0.3))
	porch_lamp = Build.interactable(self, Vector3(-0.2, 1.98, 1.5), Vector3(0.35, 0.4, 0.35), "Take Grandma's bulb")
	porch_lamp.enabled = false

	# Leaves, a bare tree, and the car in the drive.
	for i in 8:
		Build.box(self, Vector3(randf_range(0.4, 1.0), 0.03, randf_range(0.4, 1.0)),
			Vector3(randf_range(-6, -2.8), 0.015, randf_range(-4, 7)), Build.mat(Color(0.6, 0.3, 0.1).lerp(Color(0.5, 0.4, 0.15), randf())),
			false, Vector3(0, randf() * 90, 0))
	var bark := Build.mat(Color(0.15, 0.11, 0.08))
	Build.cylinder(self, 0.2, 5.0, Vector3(-5.0, 2.5, -3.5), bark)
	for i in 4:
		Build.cylinder(self, 0.06, 1.8, Vector3(-5.0 + cos(i * 1.6) * 0.5, 3.4 + i * 0.4, -3.5 + sin(i * 1.6) * 0.5), bark, Vector3(sin(i * 1.6) * 50, 0, -cos(i * 1.6) * 50))
	var paint := Build.mat(Color(0.25, 0.35, 0.5), 0.0, 0.35)
	Build.box(self, Vector3(1.8, 0.8, 4.2), Vector3(-6.2, 0.6, 2.4), paint, true)
	Build.box(self, Vector3(1.7, 0.65, 2.2), Vector3(-6.2, 1.3, 2.7), paint)
	Build.box(self, Vector3(1.72, 0.5, 2.0), Vector3(-6.2, 1.32, 2.7), Build.mat(Color(0.12, 0.14, 0.18), 0.0, 0.1))
	for x in [-7.1, -5.3]:
		for z in [1.0, 3.8]:
			Build.cylinder(self, 0.33, 0.22, Vector3(x, 0.33, z), Build.mat(Color(0.08, 0.08, 0.08)), Vector3(0, 0, 90))
	for i in 3:
		Build.box(self, Vector3(0.4, 0.3, 0.35), Vector3(-6.2 + (i - 1) * 0.45, 1.15, 3.4), _cardboard)

	# Keep Leo between the porch and the house.
	var bounds := StaticBody3D.new()
	add_child(bounds)
	for wall in [[Vector3(-3.4, 1.5, 0), Vector3(0.3, 3, 10.4)], [Vector3(-1.7, 1.5, -5.15), Vector3(3.4, 3, 0.3)], [Vector3(-1.7, 1.5, 5.15), Vector3(3.4, 3, 0.3)]]:
		var shape := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = wall[1]
		shape.shape = b
		shape.position = wall[0]
		bounds.add_child(shape)
