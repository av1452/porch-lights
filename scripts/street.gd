class_name Street
extends Node3D
## The neighborhood outside the front window: yard, road, houses across the
## street and their porch lights. Built in code so it's easy to lay out by
## editing the arrays below. The street runs along Z; our porch faces -X.

## Houses across the street (x is where the house's front wall sits).
@export var across_z: PackedFloat32Array = [-44, -30, -16, -2, 12, 26, 40]
@export var across_front_x := -27.0
## Houses on our side (front wall lines up with ours).
@export var our_side_z: PackedFloat32Array = [-30, -16, 16, 30]
## The last light at the end of the street.
@export var far_light_pos := Vector3(-26.8, 1.6, -64)
@export var far_light_color := Color(1, 0.5, 0.15)
## Roof over our own living room (off when the house has its own shape).
@export var build_own_roof := true
## Where our front walk meets the steps, along the street.
@export var front_walk_z := 0.0

const GROUND_Y := -0.45
const SIDINGS := [Color(0.55, 0.6, 0.62), Color(0.7, 0.62, 0.5), Color(0.45, 0.5, 0.45),
	Color(0.62, 0.55, 0.6), Color(0.75, 0.72, 0.65), Color(0.5, 0.42, 0.38)]

## Porch lights in the order they go out in chapter 2: {light, material, energy}.
var porch_lights: Array[Dictionary] = []
var far_light: Dictionary
## Every house: {x, z, facing, roof_y}, for decorating by season.
var houses: Array[Dictionary] = []
## The Halloween-only things (carved pumpkins, the toilet-papered tree).
var _halloween: Array[Node3D] = []
var _ground_box: CSGBox3D
## The Hendersons' inflatable Santa, bowing in the wind (Christmas).
var _santa: Node3D
var _t := 0.0
## Neighbors out on the street (add_people), so the window lines are true.
var _people: Node3D
## Paint colors for the cars in everyone's driveways, and what they drive.
const CARS := [["sedan", Color(0.55, 0.1, 0.12)], ["pickup", Color(0.2, 0.25, 0.4)], ["wagon", Color(0.75, 0.72, 0.62)],
	["hatchback", Color(0.15, 0.4, 0.3)], ["suv", Color(0.12, 0.12, 0.14)], ["minivan", Color(0.6, 0.62, 0.66)],
	["sedan", Color(0.85, 0.85, 0.82)], ["pickup", Color(0.5, 0.12, 0.1)], ["wagon", Color(0.35, 0.25, 0.18)],
	["suv", Color(0.5, 0.55, 0.45)], ["hatchback", Color(0.8, 0.65, 0.2)]]
## Our van: the same green as the one you ride in (scripts/car_ride.gd).
const OUR_VAN := Color(0.2, 0.33, 0.27)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	_ground()
	if build_own_roof:
		_own_roof()
	_moon()
	for z in across_z:
		houses.append({ "x": across_front_x, "z": z, "facing": 1 })
	for z in our_side_z:
		houses.append({ "x": -3.1, "z": z, "facing": -1 })
	for h in houses:
		_house(h.x, h.z, h.facing, rng)
	_driveways(rng)
	_hendersons_tree()
	porch_lights.sort_custom(func(a, b): return a.z > b.z)
	far_light = _house(far_light_pos.x, far_light_pos.z, 1, rng, far_light_color, false)
	# Grandma-orange, and bright enough to read from the far end of the street.
	(far_light.light as OmniLight3D).light_energy = 3.0
	far_light.energy = 3.0
	(far_light.light as OmniLight3D).omni_range = 10.0
	(far_light.material as StandardMaterial3D).emission_energy_multiplier = 12.0
	(far_light.halo as MeshInstance3D).scale = Vector3.ONE * 2.5
	for i in 10:
		var z := rng.randf_range(-60, 50)
		if absf(z) < 4.0:
			z += 8.0
		_tree(Vector3(rng.randf_range(-11, -7.5) if i % 2 else rng.randf_range(-25.8, -24.6), GROUND_Y, z), rng)


func _noise_mat(a: Color, b: Color, freq: float, rough := 0.95) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.frequency = freq
	var ramp := Gradient.new()
	ramp.set_color(0, a)
	ramp.set_color(1, b)
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.color_ramp = ramp
	tex.seamless = true
	tex.width = 256
	tex.height = 256
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.25
	m.roughness = rough
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, collide := false, rot := Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation_degrees = rot
	b.material = mat
	b.use_collision = collide
	add_child(b)
	return b


func _ground() -> void:
	var grass := _noise_mat(Color(0.1, 0.13, 0.07), Color(0.2, 0.2, 0.1), 0.08)
	var concrete := _noise_mat(Color(0.35, 0.35, 0.34), Color(0.45, 0.44, 0.42), 0.2)
	var asphalt := _noise_mat(Color(0.07, 0.07, 0.08), Color(0.16, 0.16, 0.17), 0.35, 0.8)
	var ground := _box(Vector3(80, 0.2, 160), Vector3(-20, GROUND_Y - 0.1, -10), grass, true)
	ground.set_meta("surface", "porch")
	_box(Vector3(1.5, 0.04, 160), Vector3(-12.8, GROUND_Y + 0.01, -10), concrete)
	_ground_box = ground
	_box(Vector3(9, 0.04, 160), Vector3(-17.8, GROUND_Y - 0.01, -10), asphalt)
	_box(Vector3(1.5, 0.04, 160), Vector3(-23.3, GROUND_Y + 0.01, -10), concrete)
	# front walk from our steps to the sidewalk
	_box(Vector3(6.4, 0.04, 1.1), Vector3(-9.0, GROUND_Y + 0.01, front_walk_z), concrete)


func _process(delta: float) -> void:
	if _santa == null or not _santa.visible:
		return
	# The inflatable Santa bows, straightens up, bows again: polite.
	_t += delta
	_santa.rotation.z = sin(_t * 0.9) * 0.18 + sin(_t * 2.3) * 0.04
	_santa.rotation.x = sin(_t * 0.6) * 0.06


## A driveway beside every house, with a car on it (a different kind at each
## house), and ours: the green van, nose to the house.
func _driveways(rng: RandomNumberGenerator) -> void:
	var concrete := _noise_mat(Color(0.4, 0.4, 0.39), Color(0.5, 0.49, 0.47), 0.2)
	var spots: Array = []
	for i in houses.size():
		var h: Dictionary = houses[i]
		var dz: float = h.z + 4.6
		if h.facing == 1:
			# Across the street: from the sidewalk back along the side of the house.
			spots.append([Vector3(-28.5, 0, dz), 9.0, 90.0, i])
		else:
			spots.append([Vector3(-7.6, 0, dz), 8.9, -90.0, i])
	# Ours, past the kitchen end of the house.
	spots.append([Vector3(-7.6, 0, 9.9), 8.9, -90.0, -1])
	for sp: Array in spots:
		var at: Vector3 = sp[0]
		_box(Vector3(sp[1], 0.04, 3.0), Vector3(at.x, GROUND_Y + 0.015, at.z), concrete)
		var c: Array = CARS[posmod(sp[3] * 5 + 3, CARS.size())] if sp[3] >= 0 else ["minivan", OUR_VAN]
		var car := Props.car(c[0], c[1])
		var back := 1.2 if sp[3] >= 0 else 2.6
		car.position = Vector3(at.x + (back if sp[2] < 0.0 else -back), GROUND_Y + 0.03, at.z + rng.randf_range(-0.2, 0.2))
		car.rotation_degrees.y = sp[2] + rng.randf_range(-3.0, 3.0)
		add_child(car)


## The big maple in front of the Hendersons' (across the street from us),
## and, the night of Halloween, the toilet paper in it.
func _hendersons_tree() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var base := Vector3(-25.0, GROUND_Y, 2.5)
	_tree(base, rng)
	var tp := Node3D.new()
	tp.name = "ToiletPaper"
	tp.visible = false
	add_child(tp)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.95, 0.95, 0.93)
	for i in 9:
		var a := i * TAU / 9.0 + rng.randf_range(-0.2, 0.2)
		var strip := CSGBox3D.new()
		var length := rng.randf_range(1.2, 2.8)
		strip.size = Vector3(0.1, length, 0.01)
		strip.position = base + Vector3(cos(a) * rng.randf_range(0.8, 1.6), 4.2 - length / 2.0, sin(a) * rng.randf_range(0.8, 1.6))
		strip.rotation = Vector3(rng.randf_range(-0.15, 0.15), a, rng.randf_range(-0.15, 0.15))
		strip.material = white
		tp.add_child(strip)
	# Smashed pumpkin on the sidewalk, by our walk.
	var orange := StandardMaterial3D.new()
	orange.albedo_color = Color(0.85, 0.4, 0.08)
	for i in 5:
		var bit := CSGSphere3D.new()
		bit.radius = rng.randf_range(0.06, 0.14)
		bit.scale = Vector3(1, 0.35, 1)
		bit.position = Vector3(-12.6 + rng.randf_range(-0.4, 0.4), GROUND_Y + 0.04, -3.0 + rng.randf_range(-0.4, 0.4))
		bit.material = orange
		tp.add_child(bit)
	_halloween.append(tp)


## The night after trick-or-treating: TP in the Hendersons' tree, a smashed pumpkin.
func show_halloween_aftermath() -> void:
	(get_node("ToiletPaper") as Node3D).visible = true


## Dress the street for the time of year. "halloween" is how it's built.
## "fall": the jack-o'-lanterns are just pumpkins now, and there's mums on
## the steps. "christmas": lights along every roof, wreaths on the doors, the
## Hendersons' inflatable Santa, and (if `snowy`) snow on every roof and lawn.
func decorate(season: String, snowy := false) -> void:
	if season == "halloween":
		return
	for n in _halloween:
		if n is CSGSphere3D and season == "fall":
			# Not carved anymore, not lit: just pumpkins.
			var m := ((n as CSGSphere3D).material as StandardMaterial3D).duplicate() as StandardMaterial3D
			m.emission_enabled = false
			(n as CSGSphere3D).material = m
		else:
			n.visible = false
	if season == "fall":
		_leaves()
		var mum := StandardMaterial3D.new()
		mum.albedo_color = Color(0.75, 0.35, 0.1)
		for h in houses:
			var ball := CSGSphere3D.new()
			ball.radius = 0.25
			ball.scale = Vector3(1, 0.7, 1)
			ball.position = Vector3(h.x + h.facing * 0.6, GROUND_Y + 0.17, h.z + 1.2)
			ball.material = mum
			add_child(ball)
		return
	if season != "christmas":
		return
	_eave_lights()
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.1, 0.32, 0.15)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.8, 0.08, 0.1)
	for h in houses:
		var wreath := CSGTorus3D.new()
		wreath.inner_radius = 0.16
		wreath.outer_radius = 0.3
		wreath.rotation_degrees.z = 90.0
		wreath.position = Vector3(h.x + h.facing * 0.08, GROUND_Y + 1.5, h.z)
		wreath.material = green
		add_child(wreath)
		var bow := CSGBox3D.new()
		bow.size = Vector3(0.04, 0.12, 0.2)
		bow.position = wreath.position + Vector3(h.facing * 0.03, -0.24, 0)
		bow.material = red
		add_child(bow)
	_inflatable_santa()
	if snowy:
		var snow := _noise_mat(Color(0.86, 0.88, 0.93), Color(0.97, 0.98, 1.0), 0.15)
		_ground_box.material = snow
		var roof_snow := _noise_mat(Color(0.85, 0.87, 0.92), Color(0.96, 0.97, 1.0), 0.4)
		for h in houses:
			if h.has("roof"):
				(h.roof as CSGPolygon3D).material = roof_snow


## Strings of colored bulbs along the front edge of every roof, as one
## MultiMesh (a few hundred bulbs).
func _eave_lights() -> void:
	var colors := [Color(1, 0.2, 0.2), Color(0.2, 1, 0.35), Color(0.35, 0.5, 1), Color(1, 0.8, 0.25), Color(1, 0.95, 0.85)]
	var spots: Array[Vector3] = []
	for h in houses:
		var z0: float = h.z - 3.3
		while z0 <= h.z + 3.3:
			spots.append(Vector3(h.x + h.facing * 0.32, GROUND_Y + 2.78, z0))
			z0 += 0.3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bulb := SphereMesh.new()
	bulb.radius = 0.045
	bulb.height = 0.09
	bulb.radial_segments = 8
	bulb.rings = 4
	mm.mesh = bulb
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, Transform3D(Basis(), spots[i]))
		mm.set_instance_color(i, colors[i % colors.size()])
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.6, 1.6, 1.6)
	var mi := MultiMeshInstance3D.new()
	mi.name = "EaveLights"
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Who's out on the street: "trick_or_treat" (two big kids, no costumes,
## just pillowcases) or "sleds" (kids with sleds on the lawn across the
## street, and somebody's dad on the tiniest hill in the world).
func add_people(kind: String) -> void:
	clear_people()
	_people = Node3D.new()
	_people.name = "People"
	add_child(_people)
	var coats := [Color(0.8, 0.15, 0.15), Color(0.2, 0.4, 0.8), Color(0.95, 0.75, 0.15), Color(0.3, 0.6, 0.35)]
	match kind:
		"trick_or_treat":
			for i in 2:
				var kid := Figure.person(_people, "Kids", Vector3(-23.2, GROUND_Y, 5.0 + i * 0.8), 180.0, 1.55,
					{ "legs": Color(0.2, 0.25, 0.35), "shirt": [Color(0.15, 0.15, 0.18), Color(0.35, 0.2, 0.15)][i], "hair": Color(0.15, 0.1, 0.08) }, false, "Big kids")
				kid.memory_text = "Big kids, no costumes, pillowcases half full. They're hitting the houses that still have their lights on."
				var bag := Props.box(kid, Vector3(0.3, 0.42, 0.15), Vector3(0.3, 0.45, 0.05), Color(0.95, 0.95, 0.92))
				bag.rotation_degrees.z = 8.0
		"sleds":
			# A little hill on the Hendersons' side lawn.
			var hill := CSGSphere3D.new()
			hill.radius = 1.6
			hill.scale = Vector3(0.8, 0.3, 1.2)
			hill.position = Vector3(-25.6, GROUND_Y, 9.0)
			var snow := StandardMaterial3D.new()
			snow.albedo_color = Color(0.93, 0.95, 1.0)
			hill.material = snow
			_people.add_child(hill)
			var spots := [[Vector3(-24.6, GROUND_Y, 7.4), 1.15, -60.0], [Vector3(-25.2, GROUND_Y, 11.0), 1.25, 200.0],
				[Vector3(-23.6, GROUND_Y, -6.0), 1.05, 10.0]]
			for i in spots.size():
				var sp: Array = spots[i]
				var kid := Figure.person(_people, "Kids", sp[0], sp[2], sp[1],
					{ "legs": Color(0.15, 0.2, 0.35), "shirt": coats[i], "hair": Color(0.3, 0.2, 0.1) }, false, "Kids with sleds")
				kid.memory_text = "Neighborhood kids in brand-new snow boots, pulling sleds toward the big hill behind the school."
				Props.ball(kid, 0.1 * sp[1], Vector3(0, 0.95 * sp[1], 0), coats[(i + 2) % coats.size()], Vector3(1, 0.7, 1))
				var sled := Props.box(_people, Vector3(0.45, 0.06, 0.9), (sp[0] as Vector3) + Vector3(0.0, 0.04, -0.9).rotated(Vector3.UP, deg_to_rad(sp[2] as float)), [Color(0.85, 0.1, 0.1), Color(0.1, 0.5, 0.85), Color(0.95, 0.6, 0.1)][i])
				sled.rotation_degrees.y = sp[2]
			# Somebody's dad, on a sled, on the hill, losing.
			var dad := Figure.person(_people, "Neighbor", Vector3(-25.6, GROUND_Y + 0.4, 8.6), 100.0, 1.8,
				{ "legs": Color(0.3, 0.3, 0.32), "shirt": Color(0.45, 0.3, 0.55), "hair": Color(0.2, 0.15, 0.1) }, true, "Neighbor")
			dad.memory_text = "Somebody's dad on a brand-new sled, on the tiniest hill in the world. He's losing."
			var big := Props.box(_people, Vector3(0.6, 0.06, 1.1), Vector3(-25.6, GROUND_Y + 0.38, 8.6), Color(0.15, 0.6, 0.3))
			big.rotation_degrees = Vector3(0, 100, -12)
	Look.upgrade(_people)


func clear_people() -> void:
	if _people:
		_people.queue_free()
		_people = null


## Fall: leaves all over our front yard, and a rake somebody gave up on.
func _leaves() -> void:
	var colors := [Color(0.8, 0.3, 0.08), Color(0.9, 0.6, 0.12), Color(0.6, 0.18, 0.08), Color(0.7, 0.5, 0.15)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var leaf := BoxMesh.new()
	leaf.size = Vector3(0.09, 0.006, 0.07)
	mm.mesh = leaf
	mm.instance_count = 420
	for i in mm.instance_count:
		var pos := Vector3(rng.randf_range(-11.8, -4.0), GROUND_Y + 0.005 + rng.randf() * 0.01, rng.randf_range(-8.0, 8.0))
		# A pile, by the tree Dad was going to rake under.
		if i < 140:
			pos = Vector3(-8.0, GROUND_Y, 4.5) + Vector3(rng.randf_range(-0.7, 0.7), 0.0, rng.randf_range(-0.7, 0.7))
			pos.y += maxf(0.0, 0.25 - Vector2(pos.x + 8.0, pos.z - 4.5).length() * 0.3) + rng.randf() * 0.04
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), pos))
		mm.set_instance_color(i, colors[i % colors.size()])
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	var mi := MultiMeshInstance3D.new()
	mi.name = "Leaves"
	mi.multimesh = mm
	mi.material_override = mat
	add_child(mi)
	var rake := Node3D.new()
	rake.position = Vector3(-7.2, GROUND_Y, 4.9)
	rake.rotation_degrees = Vector3(0, 30, 80)
	add_child(rake)
	Props.cyl(rake, 0.018, 1.5, Vector3(0, 0.75, 0), Color(0.6, 0.45, 0.25))
	Props.box(rake, Vector3(0.45, 0.02, 0.06), Vector3(0, 1.5, 0), Color(0.2, 0.5, 0.25))


## A giant inflatable Santa on the Hendersons' lawn, across from our porch.
func _inflatable_santa() -> void:
	_santa = Node3D.new()
	_santa.name = "InflatableSanta"
	_santa.position = Vector3(-25.6, GROUND_Y, -0.8)
	add_child(_santa)
	var parts := [
		[0.75, Vector3(0, 0.75, 0), Color(0.85, 0.1, 0.1), Vector3(1, 1.1, 1)],
		[0.2, Vector3(0, 0.8, 0), Color(0.08, 0.08, 0.08), Vector3(3.9, 0.35, 3.9)],
		[0.42, Vector3(0, 1.85, 0), Color(0.96, 0.82, 0.72), Vector3.ONE],
		[0.38, Vector3(0, 1.62, 0.2), Color(0.97, 0.97, 0.97), Vector3(1, 1, 0.8)],
		[0.1, Vector3(0, 1.95, 0.4), Color(0.95, 0.6, 0.55), Vector3.ONE],
	]
	for p: Array in parts:
		var b := CSGSphere3D.new()
		b.radius = p[0]
		b.position = p[1]
		b.scale = p[3]
		var m := StandardMaterial3D.new()
		m.albedo_color = p[2]
		m.roughness = 0.4
		b.material = m
		_santa.add_child(b)
	var hat := CSGCylinder3D.new()
	hat.cone = true
	hat.radius = 0.4
	hat.height = 0.75
	hat.position = Vector3(0, 2.5, -0.05)
	hat.rotation_degrees.x = -12.0
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.85, 0.1, 0.1)
	hat.material = hm
	_santa.add_child(hat)
	# Santa faces the street (+X here); turn him so his face is toward us.
	_santa.rotation_degrees.y = 90.0
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1, 0.85, 0.7)
	lamp.light_energy = 0.8
	lamp.omni_range = 3.0
	lamp.position = Vector3(1.0, 0.4, 0)
	_santa.add_child(lamp)


## Gable roof: a triangle (in X/Y) extruded along Z, sitting on `base`.
func _roof(base: Vector3, half_width: float, height: float, depth: float, mat: Material) -> CSGPolygon3D:
	var r := CSGPolygon3D.new()
	r.polygon = PackedVector2Array([Vector2(-half_width, 0), Vector2(0, height), Vector2(half_width, 0)])
	r.depth = depth
	r.material = mat
	# Extrusion runs along -Z, so shift forward by half to center it.
	r.position = base + Vector3(0, 0, depth / 2.0)
	add_child(r)
	return r


func _moon() -> void:
	# Sits opposite the Moon light's direction, far off over the houses.
	var moon_light := get_node_or_null("../Lights/Moon") as DirectionalLight3D
	var dir := Vector3(-0.75, 0.55, -0.35).normalized()
	if moon_light:
		dir = moon_light.global_transform.basis.z.normalized()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.4, 1.35, 1.2)
	mat.disable_fog = true
	var mesh := SphereMesh.new()
	mesh.radius = 6.0
	mesh.height = 12.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = dir * 300.0


func _own_roof() -> void:
	var shingles := _noise_mat(Color(0.12, 0.1, 0.1), Color(0.22, 0.18, 0.17), 0.5)
	_roof(Vector3(0, 2.7, 0), 3.35, 1.6, 5.7, shingles)
	# porch roof
	# porch roof, sloping down away from the house
	_box(Vector3(2.7, 0.12, 5.4), Vector3(-4.42, 2.62, 0), shingles, false, Vector3(0, 0, 8))


func _house(front_x: float, z: float, facing: int, rng: RandomNumberGenerator, light_color := Color(1, 0.78, 0.5), record := true) -> Dictionary:
	var depth := 7.0
	var cx := front_x - facing * depth / 2.0
	var siding := StandardMaterial3D.new()
	siding.albedo_color = SIDINGS[rng.randi() % SIDINGS.size()]
	siding.roughness = 0.9
	var roof := _noise_mat(Color(0.1, 0.09, 0.09), Color(0.2, 0.17, 0.16), 0.5)
	var h := 2.8
	_box(Vector3(depth, h, 6.5), Vector3(cx, GROUND_Y + h / 2.0, z), siding)
	var roof_node := _roof(Vector3(cx, GROUND_Y + h, z), depth / 2.0 + 0.3, 2.2, 6.9, roof)
	for e in houses:
		if e.z == z and e.x == front_x:
			e["roof"] = roof_node

	var door := StandardMaterial3D.new()
	door.albedo_color = Color(0.25, 0.12, 0.08)
	var fx := front_x + facing * 0.03
	_box(Vector3(0.06, 2.0, 0.9), Vector3(fx, GROUND_Y + 1.0, z), door)

	# windows: some lit, some dark
	for wz in [z - 2.0, z + 2.0]:
		var win := StandardMaterial3D.new()
		var lit := rng.randf() < 0.4
		win.albedo_color = Color(0.05, 0.06, 0.1)
		if lit:
			win.emission_enabled = true
			win.emission = Color(1, 0.7, 0.4) if rng.randf() < 0.7 else Color(0.5, 0.6, 1.0)
			win.emission_energy_multiplier = 0.8
		_box(Vector3(0.06, 1.0, 1.2), Vector3(fx, GROUND_Y + 1.5, wz), win)

	# porch light: bulb + lamp
	var bulb := StandardMaterial3D.new()
	bulb.albedo_color = light_color
	bulb.emission_enabled = true
	bulb.emission = light_color
	bulb.emission_energy_multiplier = 4.0
	var lp := Vector3(front_x + facing * 0.15, GROUND_Y + 2.1, z + 0.75)
	_box(Vector3(0.12, 0.18, 0.12), lp, bulb)
	var light := OmniLight3D.new()
	light.light_color = light_color
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.light_volumetric_fog_energy = 2.0
	light.position = lp + Vector3(facing * 0.3, -0.1, 0)
	add_child(light)

	# a jack-o'-lantern on some steps
	if rng.randf() < 0.5:
		var pumpkin := StandardMaterial3D.new()
		pumpkin.albedo_color = Color(0.9, 0.4, 0.05)
		pumpkin.emission_enabled = true
		pumpkin.emission = Color(1, 0.5, 0.1)
		pumpkin.emission_energy_multiplier = 0.6
		var p := CSGSphere3D.new()
		p.radius = 0.2
		p.material = pumpkin
		p.position = Vector3(front_x + facing * 0.8, GROUND_Y + 0.2, z - 0.9)
		add_child(p)
		_halloween.append(p)

	var halo := _halo(light_color, lp + Vector3(facing * 0.1, 0, 0))
	var entry := { "light": light, "material": bulb, "halo": halo, "energy": light.light_energy, "z": z }
	if record:
		porch_lights.append(entry)
	return entry


## Soft billboard glow so distant bulbs read as lights, not dots.
func _halo(color: Color, pos: Vector3) -> MeshInstance3D:
	var grad := Gradient.new()
	grad.set_color(0, Color(color, 0.9))
	grad.set_color(1, Color(color, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = tex
	mat.disable_fog = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	add_child(mi)
	return mi


func _tree(base: Vector3, rng: RandomNumberGenerator) -> void:
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.12, 0.09, 0.07)
	var trunk := CSGCylinder3D.new()
	var height := rng.randf_range(4.0, 6.5)
	trunk.radius = 0.18
	trunk.height = height
	trunk.position = base + Vector3(0, height / 2.0, 0)
	trunk.material = bark
	add_child(trunk)
	for i in 5:
		var branch := CSGCylinder3D.new()
		branch.radius = 0.06
		branch.height = rng.randf_range(1.5, 2.5)
		branch.material = bark
		var yaw := rng.randf_range(0, TAU)
		var y := height * rng.randf_range(0.55, 0.95)
		branch.position = base + Vector3(cos(yaw) * 0.6, y, sin(yaw) * 0.6)
		branch.rotation = Vector3(sin(yaw) * 0.9, 0, -cos(yaw) * 0.9)
		add_child(branch)


## Fades a porch light out with a little flicker.
func kill_light(entry: Dictionary, time := 0.4) -> void:
	var light: OmniLight3D = entry.light
	var mat: StandardMaterial3D = entry.material
	var t := create_tween()
	t.tween_property(light, "light_energy", entry.energy * 0.3, time * 0.3)
	t.tween_property(light, "light_energy", entry.energy * 0.8, time * 0.2)
	t.tween_property(light, "light_energy", 0.0, time * 0.5)
	t.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, time * 0.5)
	t.parallel().tween_property(entry.halo, "transparency", 1.0, time * 0.5)


## Every porch light on, the far one included.
func restore_lights() -> void:
	for e in porch_lights + [far_light]:
		(e.light as OmniLight3D).light_energy = e.energy
		(e.material as StandardMaterial3D).emission_energy_multiplier = 12.0 if e == far_light else 4.0
		(e.halo as GeometryInstance3D).transparency = 0.0


## Swap a porch light's bulb, glow and halo to another color (Christmas).
func set_light_color(entry: Dictionary, color: Color) -> void:
	(entry.light as OmniLight3D).light_color = color
	var mat: StandardMaterial3D = entry.material
	mat.albedo_color = color
	mat.emission = color
	var halo: GeometryInstance3D = entry.halo
	var hmat := (halo as MeshInstance3D).material_override as StandardMaterial3D
	var grad := ((hmat.albedo_texture as GradientTexture2D).gradient as Gradient).duplicate() as Gradient
	grad.set_color(0, Color(color, 0.9))
	grad.set_color(1, Color(color, 0.0))
	var tex := (hmat.albedo_texture as GradientTexture2D).duplicate() as GradientTexture2D
	tex.gradient = grad
	hmat.albedo_texture = tex


## End of trick-or-treating: the street's porch lights go off one at a time.
func lights_out_one_by_one(gap := 0.7) -> void:
	for e in porch_lights + [far_light]:
		kill_light(e)
		await get_tree().create_timer(gap).timeout
