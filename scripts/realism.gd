class_name Realism
## Swaps the placeholder look for real assets when they're installed
## (python tools/fetch_realistic.py): photo-based materials on walls, floors
## and outside surfaces, and scanned furniture and props in place of the CSG
## blocks. The blocks stay as invisible collision, so nothing about how the
## rooms play changes. Without the assets, everything keeps the old look.

const MODELS := "res://assets/polyhaven/models/%s/%s_1k.gltf"
const TEXTURES := "res://assets/polyhaven/textures/%s/%s_%s_1k.jpg"

static var _pbr_cache := {}


static func has_assets() -> bool:
	return ResourceLoader.exists(TEXTURES % ["wood_floor", "wood_floor", "diff"])


# ---------------------------------------------------------------- materials

## A photo-based material. `tile` is how many meters one copy of the photo
## covers; `tint` colors it (white keeps the photo's own color).
static func pbr(id: String, tint := Color.WHITE, tile := 2.0, rough_scale := 1.0) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s" % [id, tint, tile, rough_scale]
	if _pbr_cache.has(key):
		return _pbr_cache[key]
	var m := StandardMaterial3D.new()
	var diff := TEXTURES % [id, id, "diff"]
	if not ResourceLoader.exists(diff):
		m.albedo_color = tint
		return m
	m.albedo_texture = load(diff)
	m.albedo_color = tint
	var nor := TEXTURES % [id, id, "nor_gl"]
	if ResourceLoader.exists(nor):
		m.normal_enabled = true
		m.normal_texture = load(nor)
		m.normal_scale = 1.0
	var rough := TEXTURES % [id, id, "rough"]
	if ResourceLoader.exists(rough):
		m.roughness_texture = load(rough)
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.roughness = rough_scale
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE / tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_pbr_cache[key] = m
	return m


static func _set_mat(n: Node, m: Material) -> void:
	if n is CSGShape3D:
		(n as CSGShape3D).set("material", m)


# ---------------------------------------------------------------- props

static func _aabb(n: Node, xf := Transform3D.IDENTITY) -> AABB:
	var box := AABB()
	var first := true
	var stack := [[n, xf]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var t: Transform3D = item[1]
		if node is Node3D and node != n:
			t = t * (node as Node3D).transform
		if node is MeshInstance3D and (node as MeshInstance3D).mesh:
			var b: AABB = t * (node as MeshInstance3D).mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		for c in node.get_children():
			stack.append([c, t])
	return box


## Places a scanned model with its bottom-center at `pos`, turned `yaw`
## degrees. `fit` is the size to fill in the model's own axes (0 = ignore an
## axis); `uniform` keeps proportions. `only_largest` keeps just the biggest
## piece of a set (Poly Haven sometimes ships three saplings in a row).
static func prop(parent: Node3D, id: String, pos: Vector3, yaw := 0.0, fit := Vector3.ZERO, uniform := true,
		only_largest := false) -> Node3D:
	var path := MODELS % [id, id]
	if not ResourceLoader.exists(path):
		return null
	var model := (load(path) as PackedScene).instantiate() as Node3D
	if only_largest:
		_keep_largest(model)
	var holder := Node3D.new()
	holder.name = id
	holder.add_child(model)
	var b := _aabb(model)
	model.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z)
	if fit != Vector3.ZERO:
		var s := Vector3(
			fit.x / b.size.x if fit.x > 0.0 else 0.0,
			fit.y / b.size.y if fit.y > 0.0 else 0.0,
			fit.z / b.size.z if fit.z > 0.0 else 0.0)
		var smallest := INF
		for k in [s.x, s.y, s.z]:
			if k > 0.0:
				smallest = minf(smallest, k)
		if uniform:
			holder.scale = Vector3.ONE * smallest
		else:
			holder.scale = Vector3(s.x if s.x > 0 else smallest, s.y if s.y > 0 else smallest, s.z if s.z > 0 else smallest)
	holder.position = pos
	holder.rotation_degrees.y = yaw
	parent.add_child(holder)
	return holder


static func _keep_largest(model: Node3D) -> void:
	var meshes: Array[MeshInstance3D] = []
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			meshes.append(n)
		stack.append_array(n.get_children())
	if meshes.size() < 2:
		return
	var best: MeshInstance3D = meshes[0]
	for m in meshes:
		if m.mesh.get_aabb().size.y > best.mesh.get_aabb().size.y:
			best = m
	for m in meshes:
		if m != best:
			m.get_parent().remove_child(m)
			m.free()


## Hide placeholder blocks but keep them as collision.
static func hide(root: Node, paths: Array) -> void:
	for p in paths:
		var n := root.get_node_or_null(p)
		if n is Node3D:
			(n as Node3D).visible = false


# ---------------------------------------------------------------- lighting

const HDRIS := "res://assets/polyhaven/hdris/%s_1k.hdr"


## Bounce light, and a photographed sky instead of the painted one: a moonlit
## night sky for dark chapters, a snowy winter sky for daytime ones.
static func light(env: Environment) -> void:
	if not has_assets() or env == null:
		return
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_bounce_feedback = 0.5
	env.sdfgi_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if env.background_mode != Environment.BG_SKY or env.sky == null:
		return
	var night := true
	if env.sky.sky_material is ProceduralSkyMaterial:
		night = (env.sky.sky_material as ProceduralSkyMaterial).sky_top_color.v < 0.25
	var id := "qwantani_night_puresky" if night else "snow_field_2_puresky"
	if not ResourceLoader.exists(HDRIS % id):
		return
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load(HDRIS % id)
	pano.energy_multiplier = 0.5 if night else 1.0
	env.sky = env.sky.duplicate()
	env.sky.sky_material = pano


# ---------------------------------------------------------------- the family house

## The family house (Chapter 1 and every chapter that inherits it).
static func dress_house(house: Node3D) -> void:
	if not has_assets() or house.has_meta("realism"):
		return
	house.set_meta("realism", true)
	var plaster := {
		"LivingRoom": pbr("painted_plaster_wall", Color(1.0, 0.95, 0.85), 2.5),
		"Kitchen": pbr("painted_plaster_wall", Color(1.0, 0.97, 0.8), 2.5),
		"Hallway": pbr("painted_plaster_wall", Color(0.97, 0.94, 0.88), 2.5),
		"JamieRoom": pbr("painted_plaster_wall", Color(0.75, 0.8, 0.9), 2.5),
		"KidRoom": pbr("painted_plaster_wall", Color(0.82, 0.92, 0.85), 2.5),
	}
	var floors := {
		"LivingRoom": pbr("wood_floor", Color.WHITE, 2.5),
		"Kitchen": pbr("old_linoleum_flooring_01", Color.WHITE, 1.5),
		"Hallway": pbr("dirty_carpet", Color(0.95, 0.88, 0.75), 1.5),
		"JamieRoom": pbr("dirty_carpet", Color(0.6, 0.65, 0.75), 1.5),
		"KidRoom": pbr("dirty_carpet", Color(0.85, 0.78, 0.65), 1.5),
	}
	var ceiling := pbr("painted_plaster_wall", Color(1.0, 1.0, 0.98), 3.0)
	for room in plaster:
		var r := house.get_node_or_null("House/" + room) as Node3D
		if r == null:
			continue
		for n in r.find_children("*", "CSGShape3D", true, false):
			var name := String(n.name)
			if name == "Floor":
				_set_mat(n, floors[room])
			elif name == "Ceiling":
				_set_mat(n, ceiling)
			elif name.begins_with("Wall") or name.ends_with("Header") or name == "EndWall":
				_set_mat(n, plaster[room])
	var wood := pbr("oak_wood_planks", Color(0.75, 0.6, 0.45), 1.5)
	for p in ["House/LivingRoom/Furniture/TVStand", "House/Kitchen/Furniture/CounterBase",
			"House/Kitchen/Furniture/UpperA", "House/Kitchen/Furniture/UpperB", "House/KidRoom/Furniture/Dresser"]:
		var n := house.get_node_or_null(p)
		if n:
			_set_mat(n, wood)
	var counter := pbr("laminate_floor_02", Color(0.95, 0.92, 0.85), 1.0)
	var top := house.get_node_or_null("House/Kitchen/Furniture/CounterTop")
	if top:
		_set_mat(top, counter)
	for p in ["House/LivingRoom/Furniture/Rug", "House/Hallway/Runner"]:
		var n := house.get_node_or_null(p)
		if n:
			_set_mat(n, pbr("fabric_pattern_05", Color(0.95, 0.75, 0.6), 1.2))
	var bed_fabric := pbr("fabric_pattern_05", Color(0.55, 0.7, 0.95), 0.8)
	for p in ["House/KidRoom/Things/Bed/Blanket"]:
		var n := house.get_node_or_null(p)
		if n:
			_set_mat(n, bed_fabric)
	# Windows at night: dark glass with reflections, not a flat blue panel.
	for p in ["House/LivingRoom/Things/Window/Glass", "House/Kitchen/Furniture/WindowGlass"]:
		var g := house.get_node_or_null(p)
		if g:
			_set_mat(g, night_glass())
	var curtain := pbr("fabric_pattern_05", Color(0.7, 0.25, 0.25), 0.8)
	for p in ["House/LivingRoom/Things/Window/CurtainL", "House/LivingRoom/Things/Window/CurtainR"]:
		var c := house.get_node_or_null(p)
		if c:
			_set_mat(c, curtain)
	_dress_exterior(house)
	_furnish_house(house)


static func _dress_exterior(house: Node3D) -> void:
	var ext := house.get_node_or_null("Exterior") as Node3D
	if ext == null:
		return
	var siding := pbr("weathered_plank_siding", Color(0.75, 0.82, 0.9), 2.0)
	var deck := pbr("wood_floor_deck", Color(0.85, 0.8, 0.75), 2.0)
	for n in ext.find_children("*", "CSGShape3D", true, false):
		var name := String(n.name)
		if name.begins_with("Facade"):
			_set_mat(n, siding)
		elif name == "Floor" or name.begins_with("Step"):
			_set_mat(n, deck)
		elif name == "Roof":
			_set_mat(n, pbr("grey_roof_tiles", Color.WHITE, 1.5))


static func _furnish_house(house: Node3D) -> void:
	var lr := "House/LivingRoom/"
	# Couch: a real sofa (and pillows) where the block one was.
	if prop(house, "Sofa_01", Vector3(0, 0, 2.05), 180.0, Vector3(2.15, 0, 0)):
		hide(house, [lr + "Things/Couch/Seat", lr + "Things/Couch/Back", lr + "Things/Couch/ArmL",
			lr + "Things/Couch/ArmR", lr + "Things/Couch/Afghan"])
		prop(house, "throw_pillows_01", Vector3(0.6, 0.42, 2.12), 180.0, Vector3(0.7, 0, 0))
	if prop(house, "CoffeeTable_01", Vector3(0, 0, 0.5), 0.0, Vector3(1.1, 0, 0.6), false):
		hide(house, [lr + "Furniture/CoffeeTable"])
	if prop(house, "wooden_bookshelf_worn", Vector3(-2.8, 0, -1.6), 90.0, Vector3(1.0, 1.7, 0.4), false):
		hide(house, [lr + "Furniture/Bookshelf"])
		for y in [0.62, 1.05]:
			prop(house, "book_encyclopedia_set_01", Vector3(-2.82, y, -1.6), 90.0, Vector3(0.7, 0, 0))
	if prop(house, "potted_plant_02", Vector3(2.65, 0, -2.1), 0.0, Vector3(0, 0.9, 0)):
		hide(house, [lr + "Furniture/PlantPot", lr + "Furniture/PlantLeaves", lr + "Furniture/PlantLeavesTop"])
	if prop(house, "side_table_01", Vector3(-2.75, 0, 0), 90.0, Vector3(0.5, 0.6, 0.4), false):
		hide(house, [lr + "Furniture/SideTable"])
	if prop(house, "wall_clock", Vector3(1, 1.84, -2.49), 0.0, Vector3(0.3, 0, 0)):
		hide(house, [lr + "Furniture/ClockRim", lr + "Furniture/ClockFace", lr + "Furniture/HourHand", lr + "Furniture/MinuteHand"])
	var frames := [["hanging_picture_frame_01", Vector3(-2.4, 1.52, -2.49), 0.3], ["hanging_picture_frame_02", Vector3(-1.95, 1.66, -2.49), 0.36],
		["hanging_picture_frame_02", Vector3(-2.15, 1.22, -2.49), 0.26]]
	var placed := 0
	for f in frames:
		if prop(house, f[0], f[1], 0.0, Vector3(f[2], 0, 0)):
			placed += 1
	if placed > 0:
		var ps: Array = []
		for i in 3:
			ps.append(lr + "Furniture/Frame%d" % i)
			ps.append(lr + "Furniture/Photo%d" % i)
		hide(house, ps)
	if prop(house, "gaming_console", Vector3(0.05, 0, -1.62), 0.0, Vector3(0.28, 0, 0)):
		hide(house, [lr + "Things/Console/Body", lr + "Things/Console/Light"])
		prop(house, "gamepad", Vector3(0.25, 0, -1.0), 30.0, Vector3(0.16, 0, 0))
		hide(house, [lr + "Furniture/Controller"])

	# Kitchen: table and chairs, stove, microwave, kettle.
	var k := "House/Kitchen/Furniture/"
	if prop(house, "dining_table", Vector3(4.6, 0, 0.4), 90.0, Vector3(1.0, 0.75, 1.3), false):
		hide(house, [k + "Table", k + "TableLeg0", k + "TableLeg1", k + "TableLeg2", k + "TableLeg3"])
		for c in [[Vector3(3.75, 0, 0.4), 90.0], [Vector3(5.45, 0, 0.4), -90.0], [Vector3(4.6, 0, -0.35), 0.0], [Vector3(4.6, 0, 1.15), 180.0]]:
			prop(house, "dining_chair_02", c[0], c[1], Vector3(0, 0.95, 0))
		hide(house, [k + "Chair0", k + "Chair1", k + "Chair2", k + "Chair3"])
	if prop(house, "electric_stove", Vector3(6.68, 0, -0.6), -90.0, Vector3(0.62, 0.94, 0), false):
		hide(house, [k + "Burner0", k + "Burner1", k + "Burner2", k + "Burner3", k + "OvenDoor"])
	if prop(house, "vintage_microwave", Vector3(6.72, 0.94, 2.05), -90.0, Vector3(0.52, 0, 0)):
		hide(house, [k + "Microwave", k + "MicrowaveClock"])
	prop(house, "vintage_electric_kettle", Vector3(6.65, 0.94, 0.15), -90.0, Vector3(0.22, 0, 0))

	# Bedrooms.
	if prop(house, "painted_wooden_nightstand", Vector3(5.75, 0, -6.15), -90.0, Vector3(0.42, 0.5, 0.4), false):
		hide(house, ["House/KidRoom/Furniture/Nightstand"])
	prop(house, "alarm_clock_01", Vector3(5.7, 0.5, -6.3), -110.0, Vector3(0.12, 0, 0))
	prop(house, "boombox", Vector3(1.2, 0.62, -5.85), 0.0, Vector3(0.45, 0, 0))


# ---------------------------------------------------------------- Grandma's

static func dress_grandmas(house: Node3D) -> void:
	if not has_assets() or house.has_meta("realism"):
		return
	house.set_meta("realism", true)
	var room := house.get_node_or_null("House/Room") as Node3D
	if room == null:
		return
	var wall := pbr("yellow_plaster", Color(1.0, 0.95, 0.85), 2.5)
	for n in room.find_children("*", "CSGShape3D", true, false):
		var name := String(n.name)
		if name == "Floor":
			_set_mat(n, pbr("old_wooden_floor_01", Color.WHITE, 2.5))
		elif name == "KitchenFloor":
			_set_mat(n, pbr("old_linoleum_flooring_01", Color(0.95, 0.9, 0.85), 1.5))
		elif name == "Ceiling":
			_set_mat(n, pbr("painted_plaster_wall", Color(1.0, 0.98, 0.94), 3.0))
		elif name.begins_with("Wall"):
			_set_mat(n, wall)
	var f := "House/Furniture/"
	var wood := pbr("oak_wood_planks", Color(0.65, 0.5, 0.38), 1.5)
	for p in ["CounterBase", "Uppers", "ChinaCabinet"]:
		var n := house.get_node_or_null(f + p)
		if n:
			_set_mat(n, wood)
	# Grandma's dining chairs, turned to face her table.
	var table := house.get_node_or_null(f + "BigTable") as Node3D
	if table:
		for c in ["ChairN0", "ChairN1", "ChairN2", "ChairS0", "ChairS1", "ChairS2"]:
			var chair := house.get_node_or_null(f + c) as Node3D
			if chair == null:
				continue
			var to := table.position - chair.position
			if prop(house, "dining_chair_02", Vector3(chair.position.x, 0, chair.position.z), rad_to_deg(atan2(to.x, to.z)), Vector3(0, 0.95, 0)):
				chair.visible = false
	var side := house.get_node_or_null(f + "SideTable") as Node3D
	if side and prop(house, "side_table_01", side.position - Vector3(0, side.position.y, 0), 90.0, Vector3(0.45, 0.65, 0.45), false):
		side.visible = false


## Window glass at night: nearly black, glossy, so it reflects the room.
static func night_glass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.03, 0.05)
	m.roughness = 0.04
	m.metallic = 0.6
	m.metallic_specular = 1.0
	return m


# ---------------------------------------------------------------- outside

## Real materials for the neighborhood (scripts/street.gd).
static func street_materials(snowy: bool) -> Dictionary:
	if not has_assets():
		return {}
	return {
		"ground": pbr("snow_02", Color.WHITE, 3.0) if snowy else pbr("leafy_grass", Color(0.8, 0.75, 0.6), 3.0),
		"asphalt": pbr("asphalt_02", Color.WHITE, 3.0),
		"concrete": pbr("concrete_pavement", Color.WHITE, 2.0),
		"roof": pbr("grey_roof_tiles", Color.WHITE, 1.5),
		"siding": "weathered_plank_siding",
	}
