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

const GROUND_Y := -0.45
const SIDINGS := [Color(0.55, 0.6, 0.62), Color(0.7, 0.62, 0.5), Color(0.45, 0.5, 0.45),
	Color(0.62, 0.55, 0.6), Color(0.75, 0.72, 0.65), Color(0.5, 0.42, 0.38)]

## Porch lights in the order they go out in chapter 2: {light, material, energy}.
var porch_lights: Array[Dictionary] = []
var far_light: Dictionary


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	_ground()
	_own_roof()
	_moon()
	var houses: Array[Dictionary] = []
	for z in across_z:
		houses.append({ "x": across_front_x, "z": z, "facing": 1 })
	for z in our_side_z:
		houses.append({ "x": -3.1, "z": z, "facing": -1 })
	for h in houses:
		_house(h.x, h.z, h.facing, rng)
	porch_lights.sort_custom(func(a, b): return a.z > b.z)
	far_light = _house(far_light_pos.x, far_light_pos.z, 1, rng, far_light_color, false)
	# Grandma-orange, and bright enough to read from the far end of the street.
	(far_light.light as OmniLight3D).light_energy = 3.0
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
	_box(Vector3(9, 0.04, 160), Vector3(-17.8, GROUND_Y - 0.01, -10), asphalt)
	_box(Vector3(1.5, 0.04, 160), Vector3(-23.3, GROUND_Y + 0.01, -10), concrete)
	# front walk from our steps to the sidewalk
	_box(Vector3(6.4, 0.04, 1.1), Vector3(-9.0, GROUND_Y + 0.01, 0), concrete)


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
	mi.position = dir * 300.0
	add_child(mi)


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
	_roof(Vector3(cx, GROUND_Y + h, z), depth / 2.0 + 0.3, 2.2, 6.9, roof)

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
