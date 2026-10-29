class_name Build
## Small helpers for building scenery and props in code (chapters 3-5).


static func mat(c: Color, emission := 0.0, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, m: Material, collide := false, rot := Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation_degrees = rot
	b.material = m
	b.use_collision = collide
	parent.add_child(b)
	return b


static func cylinder(parent: Node, radius: float, height: float, pos: Vector3, m: Material, rot := Vector3.ZERO) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.sides = 14
	c.position = pos
	c.rotation_degrees = rot
	c.material = m
	parent.add_child(c)
	return c


static func light(parent: Node, pos: Vector3, color: Color, energy: float, range: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range
	l.shadow_enabled = shadows
	parent.add_child(l)
	return l


## Something Leo can use. The collision box is `size`, offset by `shape_offset`.
static func interactable(parent: Node, pos: Vector3, size: Vector3, prompt: String, line := "", shape_offset := Vector3.ZERO) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt
	it.line_id = line
	it.speak = line != ""
	it.position = pos
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	shape.shape = b
	shape.position = shape_offset
	it.add_child(shape)
	parent.add_child(it)
	return it


## A full-size candy bar in Grandma-orange.
static func candy_bar(parent: Node, pos: Vector3, yaw := 0.0) -> CSGBox3D:
	return box(parent, Vector3(0.18, 0.025, 0.06), pos, mat(Color(0.95, 0.45, 0.08)), false, Vector3(0, yaw, 0))
