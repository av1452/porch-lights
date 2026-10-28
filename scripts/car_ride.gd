class_name CarRide
extends Node3D
## The family car at night, built in code. The car stays still and the road
## slides past: lane dashes, reflector posts, sodium streetlights that sweep
## through the cabin, and the occasional oncoming car.
## Car faces -Z. Back seat: Leo on the right (+X), Jamie on the left.

@export var speed := 24.0
## Seconds between oncoming cars (randomized around this).
@export var traffic_gap := 9.0

const ROAD_LENGTH := 320.0
const ROAD_Y := -0.35

var _movers: Array[Node3D] = []
var _oncoming: Array[Node3D] = []
var _traffic_t := 3.0
var _hum: AudioStreamPlayer
var _cabin: Node3D


func _ready() -> void:
	_build_cabin()
	_build_road()
	_hum = Audio.make_loop("car_interior", self, -6.0, "SFX", false) as AudioStreamPlayer


func _process(delta: float) -> void:
	var step := speed * delta
	for m in _movers:
		m.position.z += step
		if m.position.z > 40.0:
			m.position.z -= ROAD_LENGTH
	_traffic_t -= delta
	if _traffic_t <= 0.0:
		_traffic_t = randf_range(traffic_gap * 0.6, traffic_gap * 1.4)
		for c in _oncoming:
			if not c.visible:
				c.position.z = -ROAD_LENGTH + 40.0
				c.visible = true
				break
	for c in _oncoming:
		if c.visible:
			c.position.z += (speed + 26.0) * delta
			if c.position.z > 40.0:
				c.visible = false
	# A little road shake.
	_cabin.position.y = sin(Time.get_ticks_msec() * 0.011) * 0.004 + sin(Time.get_ticks_msec() * 0.023) * 0.002


func stop_engine(time := 2.0) -> void:
	create_tween().tween_property(_hum, "volume_db", -60.0, time)
	create_tween().tween_property(self, "speed", 0.0, time)


# ---------------------------------------------------------------- building

func _mat(c: Color, rough := 0.9, emissive := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emissive
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation_degrees = rot
	b.material = mat
	parent.add_child(b)
	return b


func _build_cabin() -> void:
	_cabin = Node3D.new()
	_cabin.name = "Cabin"
	add_child(_cabin)
	var upholstery := _mat(Color(0.32, 0.3, 0.33))
	var plastic := _mat(Color(0.12, 0.12, 0.13), 0.7)
	var headliner := _mat(Color(0.62, 0.58, 0.52))
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.5, 0.6, 0.7, 0.1)
	glass.roughness = 0.05
	glass.metallic_specular = 1.0

	_box(_cabin, Vector3(1.5, 0.05, 3.2), Vector3(0, -0.02, 0), _mat(Color(0.15, 0.14, 0.14)))
	_box(_cabin, Vector3(1.5, 0.05, 2.4), Vector3(0, 1.5, -0.1), headliner)
	# back seat
	_box(_cabin, Vector3(1.4, 0.42, 0.5), Vector3(0, 0.21, 0.62), upholstery)
	_box(_cabin, Vector3(1.4, 0.62, 0.14), Vector3(0, 0.72, 0.9), upholstery, Vector3(-8, 0, 0))
	# front seats (no headrests, so you can see Mom and Dad)
	for x in [-0.38, 0.38]:
		_box(_cabin, Vector3(0.52, 0.42, 0.5), Vector3(x, 0.21, -0.5), upholstery)
		_box(_cabin, Vector3(0.52, 0.45, 0.12), Vector3(x, 0.64, -0.2), upholstery, Vector3(-10, 0, 0))
	# dashboard, wheel and clock
	_box(_cabin, Vector3(1.5, 0.32, 0.45), Vector3(0, 0.74, -1.38), plastic)
	var wheel := CSGTorus3D.new()
	wheel.inner_radius = 0.15
	wheel.outer_radius = 0.18
	wheel.position = Vector3(-0.38, 0.95, -1.08)
	wheel.rotation_degrees = Vector3(70, 0, 0)
	wheel.material = plastic
	_cabin.add_child(wheel)
	var clock := Label3D.new()
	clock.text = "11:48"
	clock.font_size = 24
	clock.pixel_size = 0.0025
	clock.modulate = Color(0.4, 1.0, 0.6)
	clock.outline_size = 0
	clock.position = Vector3(0.05, 0.86, -1.15)
	clock.rotation_degrees = Vector3(-20, 0, 0)
	_cabin.add_child(clock)
	var dash_glow := OmniLight3D.new()
	dash_glow.light_color = Color(0.4, 1.0, 0.6)
	dash_glow.light_energy = 0.25
	dash_glow.omni_range = 1.2
	dash_glow.position = Vector3(0, 0.95, -1.05)
	_cabin.add_child(dash_glow)
	# doors, windows and pillars
	for side in [-1, 1]:
		_box(_cabin, Vector3(0.06, 0.62, 2.5), Vector3(0.75 * side, 0.5, -0.1), plastic)
		_box(_cabin, Vector3(0.02, 0.66, 2.4), Vector3(0.74 * side, 1.14, -0.1), glass)
		for z in [-1.25, 0.1, 1.05]:
			_box(_cabin, Vector3(0.06, 0.68, 0.08), Vector3(0.74 * side, 1.15, z), plastic)
	_box(_cabin, Vector3(1.4, 0.7, 0.02), Vector3(0, 1.15, 1.12), glass, Vector3(-25, 0, 0))
	_box(_cabin, Vector3(1.4, 0.72, 0.02), Vector3(0, 1.15, -1.55), glass, Vector3(30, 0, 0))
	# outside: hood and trunk so the windows aren't looking into nothing
	var paint := _mat(Color(0.22, 0.27, 0.33), 0.5)
	_box(_cabin, Vector3(1.6, 0.5, 1.2), Vector3(0, 0.45, -2.2), paint)
	_box(_cabin, Vector3(1.6, 0.5, 0.8), Vector3(0, 0.45, 1.6), paint)
	var beams := SpotLight3D.new()
	beams.light_color = Color(1, 0.95, 0.8)
	beams.light_energy = 9.0
	beams.spot_range = 45.0
	beams.spot_angle = 30.0
	beams.light_volumetric_fog_energy = 0.6
	beams.position = Vector3(0, 0.6, -2.85)
	beams.rotation_degrees = Vector3(-7, 0, 0)
	_cabin.add_child(beams)


func _build_road() -> void:
	var asphalt := _mat(Color(0.08, 0.08, 0.09), 0.85)
	var field := _mat(Color(0.05, 0.06, 0.04))
	var paint := _mat(Color(0.85, 0.8, 0.5), 0.6)
	var white := _mat(Color(0.9, 0.9, 0.9), 0.5)
	var reflector := _mat(Color(1, 0.3, 0.2), 0.3, 2.0)
	var pole := _mat(Color(0.35, 0.35, 0.37), 0.5)
	var sodium := Color(1, 0.62, 0.3)
	var lamp := _mat(sodium, 0.3, 6.0)
	_box(self, Vector3(9, 0.02, 600), Vector3(-1.5, ROAD_Y, -250), asphalt)
	_box(self, Vector3(400, 0.02, 600), Vector3(0, ROAD_Y - 0.03, -250), field)
	for i in 32:
		var dash := _box(self, Vector3(0.12, 0.01, 3.0), Vector3(-1.5, ROAD_Y + 0.015, -i * 10.0), paint)
		_movers.append(dash)
	for i in 40:
		var post := _box(self, Vector3(0.1, 0.9, 0.1), Vector3(3.6, ROAD_Y + 0.45, -i * 8.0), white)
		_box(post, Vector3(0.11, 0.1, 0.11), Vector3(0, 0.3, 0), reflector)
		_movers.append(post)
	for i in 8:
		var light := Node3D.new()
		light.position = Vector3(5.0, ROAD_Y, -i * 40.0)
		add_child(light)
		_box(light, Vector3(0.15, 7.0, 0.15), Vector3(0, 3.5, 0), pole)
		_box(light, Vector3(2.2, 0.1, 0.12), Vector3(-1.1, 7.0, 0), pole)
		_box(light, Vector3(0.5, 0.08, 0.25), Vector3(-2.1, 6.92, 0), lamp)
		var omni := OmniLight3D.new()
		omni.light_color = sodium
		omni.light_energy = 2.5
		omni.omni_range = 14.0
		omni.light_volumetric_fog_energy = 1.5
		omni.position = Vector3(-2.1, 6.6, 0)
		light.add_child(omni)
		_movers.append(light)
	for i in 3:
		var car := Node3D.new()
		car.position = Vector3(-3.2, ROAD_Y, -ROAD_LENGTH)
		car.visible = false
		add_child(car)
		_box(car, Vector3(1.6, 0.8, 4.0), Vector3(0, 0.6, 0), _mat(Color(0.1, 0.1, 0.12)))
		for x in [-0.6, 0.6]:
			_box(car, Vector3(0.25, 0.12, 0.05), Vector3(x, 0.6, 2.02), _mat(Color(1, 0.97, 0.85), 0.2, 8.0))
		var beams := OmniLight3D.new()
		beams.light_color = Color(1, 0.97, 0.85)
		beams.light_energy = 3.0
		beams.omni_range = 12.0
		beams.position = Vector3(0, 0.8, 3.0)
		car.add_child(beams)
		_oncoming.append(car)
	# a town, far off
	var town := _mat(Color(1, 0.8, 0.5), 0.3, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		_box(self, Vector3(0.6, 0.6, 0.6), Vector3(rng.randf_range(-150, 120), ROAD_Y + rng.randf_range(0.5, 6.0), rng.randf_range(-420, -300)), town)
