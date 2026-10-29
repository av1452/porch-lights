class_name Decorations
## Shared set dressing for the chapters that reuse the Chapter 1 house:
## putting Halloween away, the Christmas tree, and falling snow.

const BULB_COLORS := [Color(1, 0.2, 0.2), Color(0.2, 1, 0.3), Color(0.3, 0.5, 1), Color(1, 0.85, 0.2), Color(1, 0.5, 0.1)]
## Where the tree goes in the living room (the jack-o'-lantern's corner).
const TREE_POS := Vector3(-2.35, 0.0, -0.65)


static func mat(c: Color, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


## Hides a node and makes it impossible to bump into or use.
static func hide(n: Node3D) -> void:
	n.visible = false
	if n is CollisionObject3D:
		(n as CollisionObject3D).collision_layer = 0
	if n is Interactable:
		(n as Interactable).enabled = false


## Chapter 1's Halloween things, and seated-at-the-computer Jamie.
static func put_away_halloween(house: Node) -> void:
	for p in ["Story/Candy", "Story/Mom", "House/LivingRoom/Things/Mask", "House/LivingRoom/Things/JackOLantern",
			"House/Kitchen/Things/CandyBowl", "House/JamieRoom/JamieRoomFull/Things/Jamie"]:
		hide(house.get_node(p) as Node3D)
	(house.get_node("Lights/PumpkinLight") as OmniLight3D).light_energy = 0.0
	(house.get_node("House/Kitchen/Furniture/CalendarMonth") as Label3D).text = "DECEMBER"


## The tree: three green cones, a star, presents, and a spiral of bulbs.
## Returns { "root", "bulbs" (materials), "glow", "checks" (bulbs you can
## check, if `checkable`) }. Light it with light_tree().
static func christmas_tree(parent: Node3D, lit: bool, checkable := false) -> Dictionary:
	var tree := Node3D.new()
	tree.name = "ChristmasTree"
	tree.position = TREE_POS
	parent.add_child(tree)
	var trunk := CSGCylinder3D.new()
	trunk.radius = 0.06
	trunk.height = 0.3
	trunk.position.y = 0.15
	trunk.material = mat(Color(0.3, 0.18, 0.1))
	tree.add_child(trunk)
	var green := mat(Color(0.1, 0.3, 0.15))
	for i in 3:
		var cone := CSGCylinder3D.new()
		cone.cone = true
		cone.radius = 0.55 - i * 0.14
		cone.height = 0.7 - i * 0.1
		cone.position.y = 0.55 + i * 0.42
		cone.sides = 10
		cone.material = green
		tree.add_child(cone)
	var star := CSGBox3D.new()
	star.size = Vector3(0.12, 0.12, 0.03)
	star.rotation_degrees.z = 45
	star.position.y = 1.72
	star.material = mat(Color(1, 0.85, 0.3), 3.0)
	tree.add_child(star)
	for i in 4:
		var gift := CSGBox3D.new()
		gift.size = Vector3(0.22, 0.16 + 0.05 * (i % 2), 0.2)
		gift.position = Vector3(0.35 * cos(i * 1.6), gift.size.y / 2.0, 0.35 * sin(i * 1.6) + 0.1)
		gift.rotation_degrees.y = i * 25.0
		gift.material = mat(BULB_COLORS[i].darkened(0.3))
		tree.add_child(gift)

	var bulbs: Array[StandardMaterial3D] = []
	var checks: Array[Interactable] = []
	var n := 18
	for i in n:
		var t := float(i) / n
		var pos := Vector3(cos(t * TAU * 3.0) * (0.12 + t * 0.42), 1.55 - t * 1.25, sin(t * TAU * 3.0) * (0.12 + t * 0.42))
		var m := StandardMaterial3D.new()
		m.albedo_color = BULB_COLORS[i % BULB_COLORS.size()].darkened(0.6)
		m.emission = BULB_COLORS[i % BULB_COLORS.size()]
		m.emission_enabled = true
		m.emission_energy_multiplier = 0.0
		bulbs.append(m)
		var bulb := CSGSphere3D.new()
		bulb.radius = 0.035
		bulb.radial_segments = 6
		bulb.rings = 4
		bulb.position = pos
		bulb.material = m
		tree.add_child(bulb)
		# Every third bulb is one you can check, when the string is dead.
		if checkable and i % 3 == 1 and checks.size() < 5:
			var check := Interactable.new()
			check.name = "Bulb%d" % checks.size()
			check.prompt = "Check bulb"
			check.enabled = false
			check.position = pos
			var shape := CollisionShape3D.new()
			var s := SphereShape3D.new()
			s.radius = 0.09
			shape.shape = s
			check.add_child(shape)
			tree.add_child(check)
			checks.append(check)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1, 0.75, 0.55)
	glow.omni_range = 4.0
	glow.position = Vector3(0.4, 1.0, 0.3)
	tree.add_child(glow)
	var result := { "root": tree, "bulbs": bulbs, "glow": glow, "checks": checks }
	light_tree(result, lit)
	return result


static func light_tree(tree: Dictionary, on: bool) -> void:
	for m: StandardMaterial3D in tree.bulbs:
		m.emission_energy_multiplier = 2.5 if on else 0.0
	(tree.glow as OmniLight3D).light_energy = 1.4 if on else 0.0


## Slow snow falling inside a box (centered on `pos`, `extents` half-size).
static func snow(pos: Vector3, extents: Vector3, amount := 500) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.position = pos
	p.visibility_aabb = AABB(-extents - Vector3(1, 4, 1), extents * 2.0 + Vector3(2, 5, 2))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0.05, -0.12, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.3
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.025)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material = m
	p.draw_pass_1 = quad
	return p
