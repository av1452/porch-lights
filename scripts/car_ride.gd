class_name CarRide
extends Node3D
## The family minivan, built in code. The car stays still and the road slides
## past: lane dashes, reflector posts, sodium streetlights that sweep through
## the cabin at night, and the occasional oncoming car. Set `daytime` before
## adding it for an autumn afternoon: lights off, fall trees along the road.
## Van faces -Z. Middle row: Leo on the right (+X, by the sliding door),
## Jamie on the left. A third row behind them, then the rear hatch.

@export var speed := 24.0
## Seconds between oncoming cars (randomized around this).
@export var traffic_gap := 9.0
## Autumn daytime instead of night (set before the car enters the tree).
@export var daytime := false
## What the dashboard clock says (set before the car enters the tree).
@export var clock_text := "11:48":
	set(v):
		clock_text = v
		if _clock_label:
			_clock_label.text = v

const ROAD_LENGTH := 320.0
const ROAD_Y := -0.35

var _movers: Array[Node3D] = []
var _oncoming: Array[Node3D] = []
var _traffic_t := 3.0
var _hum: AudioStreamPlayer
var _cabin: Node3D
var _beams: SpotLight3D
## The radio in the dash: use it to ask Dad to change the station
## (chapters connect `used` and call set_station()).
var radio: Interactable
var _radio_label: Label3D
var _radio_sound: AudioStreamPlayer3D
var _arrows: Array[StandardMaterial3D] = []
var _blink_left := 0.0
var _blink_t := 0.0
var _clock_label: Label3D
var _dome: OmniLight3D
var _dome_lens: StandardMaterial3D


func _ready() -> void:
	_build_cabin()
	_build_dash()
	_build_clutter()
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
	# The turn signal: the dash arrow blinks along with the click.
	if _blink_left > 0.0:
		_blink_left -= delta
		_blink_t += delta
		var on := fmod(_blink_t, 0.75) < 0.38 and _blink_left > 0.0
		for m in _arrows:
			m.emission_energy_multiplier = 3.0 if on else 0.0
	# A little road shake (off with head bob, for motion comfort).
	_cabin.position.y = 0.0 if not Game.settings.head_bob else sin(Time.get_ticks_msec() * 0.011) * 0.004 + sin(Time.get_ticks_msec() * 0.023) * 0.002


## Dad's turn signal: the click, and the green arrow on the dash blinking with it.
func blink(seconds := 11.0) -> void:
	_blink_left = seconds
	_blink_t = 0.0
	Audio.play_sfx("blinker", null, -14.0)


## The dome light over the middle row, on or off.
func set_dome(on: bool) -> void:
	_dome.visible = on
	_dome_lens.emission_energy_multiplier = 2.5 if on else 0.0


## Tunes the radio: what the display says, and what plays (a loop from
## audio/sfx or audio/music through the little speakers, or nothing).
func set_station(display: String, sound := "", folder := "sfx") -> void:
	_radio_label.text = display
	_radio_sound.stop()
	if sound != "":
		_radio_sound.stream = Audio.get_stream(folder, sound, true)
		_radio_sound.play()


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

	_box(_cabin, Vector3(1.5, 0.05, 4.2), Vector3(0, -0.02, 0.4), _mat(Color(0.15, 0.14, 0.14)))
	# A minivan's tall roof, with a dome light in the middle.
	_box(_cabin, Vector3(1.5, 0.05, 3.9), Vector3(0, 1.62, 0.45), headliner)
	var lens := _box(_cabin, Vector3(0.3, 0.03, 0.15), Vector3(0, 1.595, 0.3), _mat(Color(0.9, 0.88, 0.8), 0.6, 0.01))
	_dome_lens = lens.material as StandardMaterial3D
	_dome_lens.emission_energy_multiplier = 0.0
	_dome = OmniLight3D.new()
	_dome.light_color = Color(1.0, 0.9, 0.7)
	_dome.light_energy = 0.9
	_dome.omni_range = 2.6
	_dome.position = Vector3(0, 1.45, 0.3)
	_dome.visible = false
	_cabin.add_child(_dome)
	# middle row (Leo and Jamie)
	_box(_cabin, Vector3(1.4, 0.42, 0.5), Vector3(0, 0.21, 0.62), upholstery)
	_box(_cabin, Vector3(1.4, 0.62, 0.14), Vector3(0, 0.72, 0.9), upholstery, Vector3(-8, 0, 0))
	# third row, with the folding chairs Dad brings every year
	_box(_cabin, Vector3(1.4, 0.4, 0.45), Vector3(0, 0.2, 1.75), upholstery)
	_box(_cabin, Vector3(1.4, 0.6, 0.14), Vector3(0, 0.7, 2.02), upholstery, Vector3(-8, 0, 0))
	for k in 2:
		_box(_cabin, Vector3(0.45, 0.6, 0.04), Vector3(-0.3 + k * 0.12, 0.72, 2.25 + k * 0.05), _mat(Color(0.2, 0.3, 0.55)), Vector3(-12, 0, 0))
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
	clock.text = clock_text
	_clock_label = clock
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
	# doors, long side windows and pillars, front to back
	for side in [-1, 1]:
		_box(_cabin, Vector3(0.06, 0.62, 3.8), Vector3(0.75 * side, 0.5, 0.4), plastic)
		_box(_cabin, Vector3(0.02, 0.74, 3.7), Vector3(0.74 * side, 1.2, 0.4), glass)
		for z in [-1.25, -0.1, 1.2, 2.25]:
			_box(_cabin, Vector3(0.06, 0.76, 0.08), Vector3(0.74 * side, 1.2, z), plastic)
	# The sliding door's track and handle, on Leo's side.
	_box(_cabin, Vector3(0.03, 0.03, 1.2), Vector3(0.72, 0.84, 0.5), _mat(Color(0.35, 0.35, 0.37), 0.4))
	_box(_cabin, Vector3(0.04, 0.05, 0.16), Vector3(0.71, 0.7, 0.05), _mat(Color(0.3, 0.3, 0.32), 0.4))
	# A flat rear hatch window, and a steep, short windshield over a short hood.
	_box(_cabin, Vector3(1.4, 0.78, 0.02), Vector3(0, 1.2, 2.42), glass, Vector3(-8, 0, 0))
	_box(_cabin, Vector3(1.4, 0.8, 0.02), Vector3(0, 1.2, -1.58), glass, Vector3(38, 0, 0))
	# outside: the hood and the back of the van, so the windows aren't looking into nothing
	var paint := _mat(Color(0.2, 0.33, 0.27), 0.5)
	_box(_cabin, Vector3(1.6, 0.45, 0.9), Vector3(0, 0.5, -2.1), paint, Vector3(-6, 0, 0))
	_box(_cabin, Vector3(1.6, 1.2, 0.12), Vector3(0, 0.35, 2.52), paint)
	_box(_cabin, Vector3(1.0, 0.18, 0.02), Vector3(0, 0.55, 2.59), _mat(Color(0.85, 0.85, 0.82)))
	var beams := SpotLight3D.new()
	_beams = beams
	beams.visible = not daytime
	beams.light_color = Color(1, 0.95, 0.8)
	beams.light_energy = 9.0
	beams.spot_range = 45.0
	beams.spot_angle = 30.0
	beams.light_volumetric_fog_energy = 0.6
	beams.position = Vector3(0, 0.6, -2.85)
	beams.rotation_degrees = Vector3(-7, 0, 0)
	_cabin.add_child(beams)


## The driver's side of a late-90s family van: two round gauges under a hood,
## the turn-signal arrows, a tape-deck radio in the middle, vents, the
## rearview mirror with a pine-tree air freshener, and sun visors.
func _build_dash() -> void:
	var plastic := _mat(Color(0.1, 0.1, 0.11), 0.7)
	var trim := _mat(Color(0.2, 0.2, 0.21), 0.6)
	var glow := Color(0.45, 1.0, 0.65)
	# The gauge hood and two dials, tipped back toward the driver.
	_box(_cabin, Vector3(0.48, 0.1, 0.16), Vector3(-0.38, 0.96, -1.2), plastic, Vector3(-15, 0, 0))
	for k in 2:
		var dial := Node3D.new()
		dial.position = Vector3(-0.48 + k * 0.2, 0.93, -1.12)
		dial.rotation_degrees.x = -20.0
		_cabin.add_child(dial)
		var face := CSGCylinder3D.new()
		face.radius = 0.065
		face.height = 0.01
		face.rotation_degrees.x = 90.0
		face.material = _mat(Color(0.05, 0.06, 0.06), 0.5, 0.0 if daytime else 0.15)
		dial.add_child(face)
		for i in 7:
			var a := deg_to_rad(-120.0 + i * 40.0)
			_box(dial, Vector3(0.004, 0.012, 0.004), Vector3(sin(a), cos(a), 0) * 0.052 + Vector3(0, 0, 0.007), _mat(glow, 0.5, 1.0), Vector3(0, 0, -rad_to_deg(a)))
		var needle_a := deg_to_rad(10.0 if k == 0 else -60.0)
		_box(dial, Vector3(0.004, 0.05, 0.004), Vector3(sin(needle_a), cos(needle_a), 0) * 0.022 + Vector3(0, 0, 0.009), _mat(Color(1, 0.35, 0.1), 0.5, 1.5), Vector3(0, 0, -rad_to_deg(needle_a)))
	# Turn-signal arrows between the dials: dark until Dad signals.
	for side in [-1, 1]:
		var arrow := CSGPolygon3D.new()
		arrow.polygon = PackedVector2Array([Vector2(0, 0.012), Vector2(0.022 * side, 0), Vector2(0, -0.012)])
		arrow.depth = 0.004
		arrow.position = Vector3(-0.38 + side * 0.012, 0.955, -1.105)
		arrow.rotation_degrees.x = -20.0
		var m := _mat(glow, 0.5, 0.01)
		m.emission_energy_multiplier = 0.0
		arrow.material = m
		_arrows.append(m)
		_cabin.add_child(arrow)
	# The steering wheel's hub and the column shifter.
	var hub := CSGCylinder3D.new()
	hub.radius = 0.06
	hub.height = 0.05
	hub.position = Vector3(-0.38, 0.95, -1.08)
	hub.rotation_degrees.x = 70.0
	hub.material = plastic
	_cabin.add_child(hub)
	# Two spokes, out to the rim at nine and three o'clock.
	_box(_cabin, Vector3(0.3, 0.025, 0.02), Vector3(-0.38, 0.95, -1.08), plastic, Vector3(70, 0, 0))
	_box(_cabin, Vector3(0.015, 0.015, 0.2), Vector3(-0.2, 0.9, -1.0), trim, Vector3(25, -30, 0))
	_box(_cabin, Vector3(0.03, 0.03, 0.03), Vector3(-0.16, 0.86, -0.92), trim)
	# The center stack: two vents, the radio with its orange display, a tape slot.
	for v in 2:
		var vent := _box(_cabin, Vector3(0.1, 0.05, 0.02), Vector3(-0.07 + v * 0.14, 0.93, -1.16), trim)
		for i in 3:
			_box(vent, Vector3(0.095, 0.004, 0.022), Vector3(0, -0.015 + i * 0.015, 0.002), plastic)
	radio = Interactable.new()
	radio.name = "CarRadio"
	radio.prompt = "Ask Dad to change the station"
	radio.position = Vector3(0.0, 0.84, -1.16)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 0.12, 0.08)
	shape.shape = box
	radio.add_child(shape)
	_cabin.add_child(radio)
	_box(radio, Vector3(0.26, 0.08, 0.03), Vector3.ZERO, _mat(Color(0.08, 0.08, 0.09), 0.5))
	_box(radio, Vector3(0.12, 0.022, 0.004), Vector3(0, 0.015, 0.017), _mat(Color(0.12, 0.06, 0.02), 0.3))
	_box(radio, Vector3(0.1, 0.006, 0.004), Vector3(0, -0.022, 0.017), _mat(Color(0.02, 0.02, 0.02)))
	for x in [-0.1, 0.1]:
		var knob := CSGCylinder3D.new()
		knob.radius = 0.016
		knob.height = 0.02
		knob.rotation_degrees.x = 90.0
		knob.position = Vector3(x, 0, 0.02)
		knob.material = trim
		radio.add_child(knob)
	for i in 5:
		_box(radio, Vector3(0.018, 0.008, 0.006), Vector3(-0.04 + i * 0.02, -0.01, 0.017), trim)
	_radio_label = Label3D.new()
	_radio_label.text = ""
	_radio_label.font_size = 20
	_radio_label.pixel_size = 0.0012
	_radio_label.modulate = Color(1.0, 0.6, 0.2)
	_radio_label.outline_size = 0
	_radio_label.position = Vector3(0, 0.015, 0.0195)
	radio.add_child(_radio_label)
	_radio_sound = AudioStreamPlayer3D.new()
	_radio_sound.bus = "TV"
	_radio_sound.volume_db = -8.0
	_radio_sound.unit_size = 2.0
	radio.add_child(_radio_sound)
	# The rearview mirror, with a little pine tree hanging off it.
	_box(_cabin, Vector3(0.02, 0.08, 0.02), Vector3(0, 1.52, -1.38), plastic)
	_box(_cabin, Vector3(0.26, 0.07, 0.025), Vector3(0, 1.46, -1.36), plastic, Vector3(-8, 0, 0))
	_box(_cabin, Vector3(0.24, 0.055, 0.004), Vector3(0, 1.46, -1.345), _mat(Color(0.55, 0.6, 0.65), 0.05), Vector3(-8, 0, 0))
	_box(_cabin, Vector3(0.002, 0.12, 0.002), Vector3(0.05, 1.37, -1.37), _mat(Color(0.9, 0.9, 0.9)))
	var tree := CSGPolygon3D.new()
	tree.polygon = PackedVector2Array([Vector2(-0.03, 0), Vector2(0, 0.07), Vector2(0.03, 0)])
	tree.depth = 0.003
	tree.position = Vector3(0.05, 1.24, -1.37)
	tree.material = _mat(Color(0.1, 0.45, 0.2))
	_cabin.add_child(tree)
	# Sun visors, folded up.
	for x in [-0.38, 0.38]:
		_box(_cabin, Vector3(0.4, 0.02, 0.18), Vector3(x, 1.57, -1.25), _mat(Color(0.55, 0.52, 0.47)), Vector3(-10, 0, 0))
	# Glovebox on Mom's side.
	_box(_cabin, Vector3(0.36, 0.12, 0.01), Vector3(0.4, 0.72, -1.15), trim)
	_box(_cabin, Vector3(0.06, 0.015, 0.012), Vector3(0.4, 0.76, -1.143), plastic)


## The family-van stuff: Leo's booster seat, cupholders with Dad's travel mug,
## a tissue box on the dash, the road atlas in the door pocket, Mom's purse,
## and floor mats with Cheerios on them.
func _build_clutter() -> void:
	var fabric := _mat(Color(0.18, 0.2, 0.32))
	# Booster seat under Leo.
	_box(_cabin, Vector3(0.38, 0.08, 0.36), Vector3(0.38, 0.46, 0.62), fabric)
	for x in [0.2, 0.56]:
		_box(_cabin, Vector3(0.04, 0.1, 0.32), Vector3(x, 0.52, 0.62), fabric)
	# Seatbelt across the booster, from the pillar.
	_box(_cabin, Vector3(0.05, 0.6, 0.005), Vector3(0.6, 0.85, 0.82), _mat(Color(0.15, 0.15, 0.16)), Vector3(0, 0, 25))
	# Console between the front seats, two cupholders, Dad's travel mug.
	_box(_cabin, Vector3(0.2, 0.25, 0.45), Vector3(0, 0.12, -0.6), _mat(Color(0.14, 0.14, 0.15)))
	var mug := CSGCylinder3D.new()
	mug.radius = 0.035
	mug.height = 0.16
	mug.position = Vector3(-0.04, 0.32, -0.75)
	mug.material = _mat(Color(0.65, 0.66, 0.7), 0.3)
	_cabin.add_child(mug)
	_box(_cabin, Vector3(0.06, 0.012, 0.06), Vector3(-0.04, 0.405, -0.75), _mat(Color(0.1, 0.1, 0.1)))
	# A box of tissues riding on the dash, and the road atlas in Leo's door pocket.
	_box(_cabin, Vector3(0.22, 0.09, 0.11), Vector3(0.45, 0.94, -1.3), _mat(Color(0.55, 0.75, 0.85)))
	_box(_cabin, Vector3(0.05, 0.02, 0.03), Vector3(0.45, 0.995, -1.3), _mat(Color(0.97, 0.97, 0.97)))
	_box(_cabin, Vector3(0.02, 0.26, 0.34), Vector3(0.7, 0.4, 0.35), _mat(Color(0.2, 0.45, 0.7)), Vector3(0, 0, 8))
	# Mom's purse at her feet; floor mats; Cheerios.
	_box(_cabin, Vector3(0.28, 0.18, 0.12), Vector3(0.45, 0.1, -1.0), _mat(Color(0.35, 0.22, 0.14)))
	for z in [-0.9, 0.2, 1.3]:
		_box(_cabin, Vector3(1.2, 0.01, 0.55), Vector3(0, 0.01, z), _mat(Color(0.1, 0.1, 0.1)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 7:
		var o := CSGTorus3D.new()
		o.inner_radius = 0.003
		o.outer_radius = 0.008
		o.position = Vector3(rng.randf_range(0.1, 0.6), 0.02, rng.randf_range(0.0, 0.4))
		o.material = _mat(Color(0.85, 0.7, 0.4))
		_cabin.add_child(o)


func _build_road() -> void:
	var asphalt := _mat(Color(0.08, 0.08, 0.09), 0.85)
	var field := _mat(Color(0.42, 0.36, 0.22) if daytime else Color(0.05, 0.06, 0.04))
	var paint := _mat(Color(0.85, 0.8, 0.5), 0.6)
	var white := _mat(Color(0.9, 0.9, 0.9), 0.5)
	var reflector := _mat(Color(1, 0.3, 0.2), 0.3, 2.0)
	var pole := _mat(Color(0.35, 0.35, 0.37), 0.5)
	var sodium := Color(1, 0.62, 0.3)
	var lamp := _mat(sodium, 0.3, 0.0 if daytime else 6.0)
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
		omni.visible = not daytime
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
		beams.visible = not daytime
		car.add_child(beams)
		_oncoming.append(car)
	if daytime:
		_autumn_trees()
		return
	# a town, far off
	var town := _mat(Color(1, 0.8, 0.5), 0.3, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		_box(self, Vector3(0.6, 0.6, 0.6), Vector3(rng.randf_range(-150, 120), ROAD_Y + rng.randf_range(0.5, 6.0), rng.randf_range(-420, -300)), town)


## Fall trees on both sides of the road: red, orange and yellow crowns, a few
## evergreens and bare ones, and a split-rail fence. They slide past like the
## posts.
func _autumn_trees() -> void:
	var colors := [Color(0.72, 0.2, 0.08), Color(0.88, 0.45, 0.08), Color(0.9, 0.7, 0.15), Color(0.62, 0.32, 0.1)]
	var bark := _mat(Color(0.22, 0.16, 0.12))
	var pine := _mat(Color(0.12, 0.25, 0.14))
	var rail := _mat(Color(0.45, 0.38, 0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 80:
		var tree := Node3D.new()
		var side := -1.0 if i % 2 == 0 else 1.0
		tree.position = Vector3(side * rng.randf_range(7.0, 30.0) - 1.5, ROAD_Y, -i * 4.0 - rng.randf_range(0.0, 3.0))
		add_child(tree)
		var h := rng.randf_range(1.6, 3.2)
		_box(tree, Vector3(0.28, h, 0.28), Vector3(0, h / 2.0, 0), bark)
		var kind := rng.randf()
		if kind < 0.18:
			# An evergreen: stacked cones.
			for k in 3:
				var cone := CSGCylinder3D.new()
				cone.cone = true
				cone.radius = 1.4 - k * 0.35
				cone.height = 1.8
				cone.position.y = h * 0.5 + 0.9 + k * 1.0
				cone.material = pine
				tree.add_child(cone)
		elif kind < 0.95:
			# A round fall crown from a few overlapping clusters.
			var c: Color = colors[rng.randi() % colors.size()]
			for k in 3:
				var crown := CSGSphere3D.new()
				crown.radius = rng.randf_range(1.1, 1.8)
				crown.position = Vector3(rng.randf_range(-0.7, 0.7), h + rng.randf_range(0.3, 1.3), rng.randf_range(-0.7, 0.7))
				crown.material = _mat(c.lerp(colors[rng.randi() % colors.size()], 0.25))
				tree.add_child(crown)
		_movers.append(tree)
	# A split-rail fence along the right side.
	for i in 40:
		var section := Node3D.new()
		section.position = Vector3(6.2, ROAD_Y, -i * 8.0)
		add_child(section)
		_box(section, Vector3(0.14, 1.1, 0.14), Vector3(0, 0.55, 0), rail)
		_box(section, Vector3(0.08, 0.1, 8.0), Vector3(0, 0.85, -4.0), rail)
		_box(section, Vector3(0.08, 0.1, 8.0), Vector3(0, 0.45, -4.0), rail)
		_movers.append(section)
