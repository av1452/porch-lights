class_name Figure
## Builds the game's simple CSG people in code, with the same proportions as
## the people placed by hand in the chapter scenes (Mom is 1.68 m).
## Use person() for someone you can talk to.

## Shared outfits, matching the chapter scenes.
const MOM := { "legs": Color(0.2, 0.28, 0.45), "shirt": Color(0.6, 0.55, 0.75), "hair": Color(0.3, 0.2, 0.12), "long_hair": true }
const DAD := { "legs": Color(0.55, 0.48, 0.35), "shirt": Color(0.6, 0.2, 0.15), "hair": Color(0.3, 0.2, 0.12) }
const JAMIE := { "legs": Color(0.2, 0.28, 0.45), "shirt": Color(0.1, 0.1, 0.12), "hair": Color(0.08, 0.07, 0.07) }
const GRANDMA := { "legs": Color(0.4, 0.38, 0.42), "shirt": Color(0.85, 0.5, 0.6), "hair": Color(0.75, 0.75, 0.75), "apron": true }
const SKIN := Color(0.87, 0.7, 0.58)

static var _materials := {}


static func _mat(c: Color) -> StandardMaterial3D:
	if not _materials.has(c):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		_materials[c] = m
	return _materials[c]


static func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, part := "") -> CSGBox3D:
	var b := CSGBox3D.new()
	if part != "":
		b.name = part
	b.size = size
	b.position = pos
	b.material = _mat(c)
	parent.add_child(b)
	return b


static func _ball(parent: Node3D, r: float, pos: Vector3, c: Color, part := "") -> CSGSphere3D:
	var s := CSGSphere3D.new()
	if part != "":
		s.name = part
	s.radius = r
	s.radial_segments = 10
	s.rings = 6
	s.position = pos
	s.material = _mat(c)
	parent.add_child(s)
	return s


## Adds body parts to `parent`, facing +Z. Seated people sit on a 0.44 m seat
## with their thighs pointing forward.
static func build(parent: Node3D, height: float, look: Dictionary, seated := false) -> void:
	var h := height
	var drop := 0.136 * h if seated else 0.0
	if seated:
		_box(parent, Vector3(0.3, 0.14, 0.42), Vector3(0, 0.305 * h, 0.17), look.legs, "Thighs")
		_box(parent, Vector3(0.3, 0.263 * h, 0.13), Vector3(0, 0.131 * h, 0.36), look.legs, "Shins")
	else:
		_box(parent, Vector3(0.3, 0.47 * h, 0.17), Vector3(0, 0.235 * h, 0), look.legs, "Legs")
	var torso_y := 0.63 * h - drop
	_box(parent, Vector3(0.4, 0.32 * h, 0.22), Vector3(0, torso_y, 0), look.shirt, "Torso")
	for side in [-1, 1]:
		_box(parent, Vector3(0.09, 0.304 * h, 0.11), Vector3(0.25 * side, torso_y, 0.02), look.shirt, "ArmL" if side < 0 else "ArmR")
		_ball(parent, 0.00864 * h, Vector3(0.0274 * h * side, 0.8692 * h - drop, 0.067 * h), Color(0.05, 0.05, 0.06))
	_ball(parent, 0.072 * h, Vector3(0, 0.8656 * h - drop, 0), SKIN, "Head")
	_ball(parent, 0.0763 * h, Vector3(0, 0.8786 * h - drop, -0.013 * h), look.hair, "Hair")
	if look.get("long_hair", false):
		_box(parent, Vector3(0.144 * h, 0.158 * h, 0.043 * h), Vector3(0, 0.8224 * h - drop, -0.05 * h), look.hair, "HairBack")
	if look.get("apron", false):
		_box(parent, Vector3(0.34, 0.5, 0.02), Vector3(0, 0.65 - drop, 0.12), Color(0.95, 0.95, 0.95))
	# Rounded body, hands, shoes and a face (scripts/look.gd).
	Look.upgrade(parent)


## A person you can look at and talk to: an Interactable with a body.
static func person(parent: Node3D, name: String, pos: Vector3, yaw_degrees: float, height: float,
		look: Dictionary, seated := false, prompt := "") -> Interactable:
	var p := Interactable.new()
	p.name = name
	# Node names can't hold periods ("Mrs. Patterson"); keep the real name.
	p.set_meta("person_name", name)
	p.prompt = prompt if prompt != "" else "Talk to " + name
	p.position = pos
	p.rotation.y = deg_to_rad(yaw_degrees)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.55, height * (0.78 if seated else 1.0), 0.5)
	shape.shape = box
	shape.position.y = box.size.y / 2.0
	p.add_child(shape)
	build(p, height, look, seated)
	parent.add_child(p)
	return p
