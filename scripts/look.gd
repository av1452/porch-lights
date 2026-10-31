class_name Look
## The "less low-poly" pass, run on every chapter when it starts (Chapter._ready).
## Keeps the early-2000s style but smooths it toward a late-PS2 look:
## - round shapes get enough segments to actually look round
## - flat-color materials get a subtle surface grain and bumpiness (plaster,
##   fabric, wood) from two shared noise textures
## - block people get rounded bodies, real legs, hands, shoes and faces
## - shadow-casting lights get soft, lamp-sized shadows instead of hard edges
## Safe to run more than once: anything already upgraded is skipped.

static var _grain: NoiseTexture2D
static var _bumps: NoiseTexture2D
static var _done_materials := {}


static func upgrade(root: Node) -> void:
	_make_textures()
	_walk(root)


static func _walk(n: Node) -> void:
	if n is Node3D and n.has_node("Head") and n.has_node("Torso") and not n.has_meta("look_person"):
		_person(n as Node3D)
	if n is CSGSphere3D:
		var s := n as CSGSphere3D
		s.radial_segments = maxi(s.radial_segments, 16)
		s.rings = maxi(s.rings, 10)
	elif n is CSGCylinder3D:
		var c := n as CSGCylinder3D
		c.sides = maxi(c.sides, 16)
	elif n is CSGTorus3D:
		var t := n as CSGTorus3D
		t.sides = maxi(t.sides, 20)
		t.ring_sides = maxi(t.ring_sides, 8)
	if n is Light3D:
		_soften(n as Light3D)
	if n is CSGShape3D:
		_material((n as CSGShape3D).get("material"))
	elif n is MeshInstance3D:
		_material((n as MeshInstance3D).material_override)
	for c in n.get_children():
		_walk(c)


## Real lamps are lampshades and bulbs, not points: give their shadows a
## soft edge that widens with distance (Forward+), plus a little blur.
static func _soften(l: Light3D) -> void:
	if not l.shadow_enabled or l.has_meta("look_soft"):
		return
	l.set_meta("look_soft", true)
	if l is DirectionalLight3D:
		l.light_angular_distance = maxf(l.light_angular_distance, 1.5)
		l.shadow_blur = maxf(l.shadow_blur, 1.5)
	else:
		l.light_size = maxf(l.light_size, 0.25)
		l.shadow_blur = maxf(l.shadow_blur, 2.0)
		l.shadow_bias = maxf(l.shadow_bias, 0.04)


static func _make_textures() -> void:
	if _grain:
		return
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08
	noise.fractal_octaves = 4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.9, 0.9, 0.9))
	ramp.set_color(1, Color(1, 1, 1))
	_grain = NoiseTexture2D.new()
	_grain.noise = noise
	_grain.color_ramp = ramp
	_grain.seamless = true
	_grain.width = 256
	_grain.height = 256
	var fine := FastNoiseLite.new()
	fine.frequency = 0.25
	_bumps = NoiseTexture2D.new()
	_bumps.noise = fine
	_bumps.as_normal_map = true
	_bumps.bump_strength = 2.0
	_bumps.seamless = true
	_bumps.width = 256
	_bumps.height = 256


static func _material(m: Variant) -> void:
	if not m is StandardMaterial3D:
		return
	var mat := m as StandardMaterial3D
	if _done_materials.has(mat) or mat.albedo_texture != null:
		return
	_done_materials[mat] = true
	# Glass, screens, bulbs and anything unshaded keep their clean look.
	if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or mat.emission_enabled \
			or mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or mat.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return
	mat.albedo_texture = _grain
	mat.normal_enabled = true
	mat.normal_texture = _bumps
	mat.normal_scale = 0.15
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(1.6, 1.6, 1.6)
	if mat.roughness >= 1.0:
		mat.roughness = 0.88


# ---------------------------------------------------------------- people

static func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot_deg := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scale
	parent.add_child(mi)
	return mi


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = maxf(height, radius * 2.0 + 0.001)
	c.radial_segments = 16
	c.rings = 6
	return c


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 10
	return s


static func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7
	return m


## Swaps a block person's boxes for rounded parts, and adds hands, shoes and
## a face. Works on the hand-built people in the scenes and on Figure people.
static func _person(p: Node3D) -> void:
	p.set_meta("look_person", true)
	var head := p.get_node("Head") as CSGSphere3D
	var skin: Material = head.material
	var rh := head.radius
	var shoe := _flat(Color(0.12, 0.1, 0.1))
	for part_name in ["Torso", "Legs", "ArmL", "ArmR", "Thighs", "Shins", "HairBack"]:
		var box := p.get_node_or_null(part_name) as CSGBox3D
		if box == null:
			continue
		var sz := box.size
		var pos := box.position
		var mat: Material = box.material
		match part_name:
			"Torso", "HairBack":
				# A capsule with an oval cross-section: rounded shoulders and sides.
				var depth := minf(sz.x, sz.z)
				var body := _mesh(p, _capsule(depth / 2.0, sz.y + depth * 0.4), mat, pos)
				body.scale = Vector3(sz.x / depth, 1.0, sz.z / depth)
			"Legs":
				for side in [-1, 1]:
					_mesh(p, _capsule(0.068, sz.y + 0.04), mat, pos + Vector3(0.075 * side, 0.01, 0))
					_mesh(p, _capsule(0.055, 0.2), shoe, Vector3(pos.x + 0.075 * side, 0.04, pos.z + 0.04), Vector3(90, 0, 0))
			"Shins":
				for side in [-1, 1]:
					_mesh(p, _capsule(0.062, sz.y + 0.04), mat, pos + Vector3(0.075 * side, 0.0, 0))
					_mesh(p, _capsule(0.055, 0.2), shoe, Vector3(pos.x + 0.075 * side, 0.04, pos.z + 0.06), Vector3(90, 0, 0))
			"Thighs":
				for side in [-1, 1]:
					_mesh(p, _capsule(0.072, sz.z + 0.08), mat, pos + Vector3(0.075 * side, 0, 0), Vector3(90, 0, 0))
			"ArmL", "ArmR":
				_mesh(p, _capsule(minf(sz.x, sz.z) / 2.0 + 0.005, sz.y + 0.04), mat, pos)
				_mesh(p, _sphere(0.045), skin, pos + Vector3(0, -sz.y / 2.0 - 0.03, 0.01))
		box.queue_free()
	# A face: nose, mouth and ears, in the head's own skin tone.
	var hp := head.position
	_mesh(p, _sphere(rh * 0.16), skin, hp + Vector3(0, -rh * 0.1, rh * 0.95))
	_mesh(p, BoxMesh.new(), _flat(Color(0.45, 0.2, 0.2)), hp + Vector3(0, -rh * 0.42, rh * 0.88), Vector3.ZERO,
		Vector3(rh * 0.38, rh * 0.06, rh * 0.06))
	for side in [-1, 1]:
		_mesh(p, _sphere(rh * 0.22), skin, hp + Vector3(rh * 0.97 * side, -rh * 0.05, 0), Vector3.ZERO, Vector3(0.5, 1, 1))
