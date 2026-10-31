class_name SchoolHallway
extends Node3D
## The hallway outside Room 12, built in code like the classroom. It runs from
## the exit doors (z = 0, snow-bright windows onto the parking lot) toward -Z:
## lockers, classroom doors, art taped up, fluorescent panels, and the bench
## by the doors where you wait for your ride.
## Set `dream` (before adding it) for the dream version: much longer, dim and
## purple, snow falling indoors, and a door at the far end outlined in
## Christmas lights.

const WIDTH := 3.2
const H := 3.0
## Where you sit and wait (floor level, against the east wall).
const BENCH := Vector3(1.15, 0.0, -2.4)

@export var dream := false
@export var length := 22.0

## The door at the far end (dream only), and where Biscuit waits in front of it.
var far_door: Interactable
var far_spot := Vector3.ZERO
## The ceiling lights, so the chapter can switch some off as the school empties.
var panel_lights: Array[OmniLight3D] = []


func _ready() -> void:
	if dream:
		length = 70.0
	_shell()
	_lockers_and_doors()
	_exit_doors()
	if dream:
		_dream_end()
	else:
		_bench()


func _mat(c: Color, glow := 0.0, rough := 0.85) -> StandardMaterial3D:
	var m := Decorations.mat(c, glow)
	m.roughness = rough
	return m


func _box(size: Vector3, pos: Vector3, m: Material, collide := false) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = m
	b.use_collision = collide
	add_child(b)
	return b


func _text(t: String, pos: Vector3, size: int, color: Color, yaw := 0.0) -> void:
	var l := Label3D.new()
	l.text = t
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.rotation_degrees.y = yaw
	add_child(l)


func _shell() -> void:
	var mid := -length / 2.0
	var tile := _mat(Color(0.8, 0.78, 0.7), 0.0, 0.45)
	var floor_box := _box(Vector3(WIDTH, 0.1, length), Vector3(0, -0.05, mid), tile, true)
	floor_box.set_meta("surface", "wood")
	var fleck := _mat(Color(0.6, 0.58, 0.52), 0.0, 0.45)
	for z in range(0, int(length), 3):
		_box(Vector3(0.6, 0.004, 0.6), Vector3(-0.5 + (z % 2) * 0.9, 0.002, -z - 1.2), fleck)
	_box(Vector3(WIDTH, 0.1, length), Vector3(0, H + 0.05, mid), _mat(Color(0.92, 0.91, 0.87)), true)
	var block := _mat(Color(0.93, 0.89, 0.74))
	_box(Vector3(0.2, H, length), Vector3(-WIDTH / 2 - 0.1, H / 2, mid), block, true)
	_box(Vector3(0.2, H, length), Vector3(WIDTH / 2 + 0.1, H / 2, mid), block, true)
	_box(Vector3(WIDTH, H, 0.2), Vector3(0, H / 2, -length - 0.1), block, true)
	var stripe := _mat(Color(0.2, 0.35, 0.6))
	for side in [-1, 1]:
		_box(Vector3(0.02, 0.12, length), Vector3(side * (WIDTH / 2 - 0.01), 2.2, mid), stripe)
	# Fluorescent panels down the middle.
	var panel := _mat(Color(0.95, 0.97, 1.0), 0.6 if dream else 2.5)
	for z in range(2, int(length), 4):
		_box(Vector3(0.6, 0.03, 1.2), Vector3(0, H - 0.02, -z), panel)
		var l := OmniLight3D.new()
		l.light_color = Color(0.55, 0.45, 0.9) if dream else Color(0.95, 0.97, 1.0)
		l.light_energy = 0.25 if dream else 0.6
		l.omni_range = 5.0
		l.position = Vector3(0, H - 0.3, -z)
		add_child(l)
		panel_lights.append(l)


func _lockers_and_doors() -> void:
	var blue := _mat(Color(0.2, 0.32, 0.55), 0.0, 0.5)
	var vent := _mat(Color(0.12, 0.2, 0.38))
	var door := _mat(Color(0.55, 0.42, 0.28))
	var papers := [Color(0.95, 0.85, 0.3), Color(0.9, 0.5, 0.2), Color(0.95, 0.95, 0.95), Color(0.6, 0.8, 0.95), Color(0.85, 0.4, 0.5)]
	var room := 14
	for side in [-1, 1]:
		var x: float = side * (WIDTH / 2 - 0.2)
		var z := 4.0
		while z < length - 1.5:
			if int(z) % 9 == 0:
				# A classroom door, with its number and a paper snowflake or two.
				var dx: float = side * (WIDTH / 2 - 0.03)
				_box(Vector3(0.06, 2.1, 0.95), Vector3(dx, 1.05, -z), door)
				_box(Vector3(0.02, 0.5, 0.3), Vector3(dx - side * 0.02, 1.5, -z), _mat(Color(0.8, 0.9, 1.0), 0.4))
				_text("ROOM %d" % room, Vector3(dx - side * 0.04, 2.25, -z), 24, Color(0.2, 0.2, 0.2), -90.0 * side)
				room += 2
				z += 1.6
				continue
			_box(Vector3(0.4, 1.8, 0.38), Vector3(x, 0.9, -z), blue, true)
			for v in 3:
				_box(Vector3(0.01, 0.02, 0.22), Vector3(x - side * 0.2, 1.55 + v * 0.05, -z), vent)
			# Art taped above the lockers.
			if int(z * 10) % 3 == 0:
				var c: Color = papers[int(z) % papers.size()]
				_box(Vector3(0.01, 0.3, 0.24), Vector3(side * (WIDTH / 2 - 0.01), 2.0, -z), _mat(c))
			z += 0.4


func _exit_doors() -> void:
	var frame := _mat(Color(0.75, 0.75, 0.72), 0.0, 0.4)
	var snow_glass := _mat(Color(0.9, 0.93, 0.98), 0.35 if dream else 1.6)
	for x in [-0.55, 0.55]:
		_box(Vector3(1.0, 2.3, 0.08), Vector3(x, 1.15, 0.02), frame, true)
		_box(Vector3(0.6, 1.3, 0.02), Vector3(x, 1.45, -0.03), snow_glass)
	_box(Vector3(0.8, 0.04, 0.04), Vector3(0, 1.0, -0.04), frame)
	_text("EXIT", Vector3(0, 2.6, -0.05), 32, Color(0.9, 0.1, 0.1), 0.0)
	if not dream:
		var outside := OmniLight3D.new()
		outside.light_color = Color(0.85, 0.9, 1.0)
		outside.light_energy = 0.7
		outside.omni_range = 5.0
		outside.position = Vector3(0, 1.6, -1.0)
		add_child(outside)


func _bench() -> void:
	var wood := _mat(Color(0.6, 0.45, 0.28), 0.0, 0.6)
	_box(Vector3(0.45, 0.06, 1.6), BENCH + Vector3(0, 0.45, 0), wood, true)
	for dz in [-0.65, 0.65]:
		_box(Vector3(0.4, 0.45, 0.06), BENCH + Vector3(0, 0.22, dz), _mat(Color(0.3, 0.3, 0.32)), true)


## The far end of the dream: a door outlined in Christmas lights, glowing warm.
func _dream_end() -> void:
	var z := -length + 0.15
	far_spot = Vector3(0, 0.05, z + 1.4)
	_box(Vector3(1.0, 2.2, 0.08), Vector3(0, 1.1, z), _mat(Color(0.55, 0.42, 0.28)))
	_box(Vector3(1.04, 0.04, 0.06), Vector3(0, 0.02, z + 0.05), _mat(Color(1.0, 0.85, 0.6), 3.0)) # light under the door
	var i := 0
	for p in _door_outline(z + 0.06):
		var bulb := CSGSphere3D.new()
		bulb.radius = 0.035
		bulb.position = p
		bulb.material = _mat(Decorations.BULB_COLORS[i % Decorations.BULB_COLORS.size()], 4.0)
		add_child(bulb)
		i += 1
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.75, 0.5)
	glow.light_energy = 1.4
	glow.omni_range = 6.0
	glow.position = Vector3(0, 1.2, z + 1.0)
	add_child(glow)
	far_door = Interactable.new()
	far_door.name = "FarDoor"
	far_door.prompt = "Open the door"
	far_door.position = Vector3(0, 1.1, z + 0.1)
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(1.0, 2.2, 0.2)
	shape.shape = b
	far_door.add_child(shape)
	add_child(far_door)
	# Snow, falling indoors, the whole length of the hall.
	var snow := Decorations.snow(Vector3(0, 2.0, -length / 2.0), Vector3(WIDTH / 2 - 0.1, 1.0, length / 2.0), 900)
	add_child(snow)


func _door_outline(z: float) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for k in 9:
		pts.append(Vector3(-0.56, 0.1 + k * 0.27, z))
		pts.append(Vector3(0.56, 0.1 + k * 0.27, z))
	for k in 5:
		pts.append(Vector3(-0.45 + k * 0.225, 2.3, z))
	return pts
