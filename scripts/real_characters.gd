class_name RealCharacters
## Drop-in realistic people and Biscuit. Put exported models in:
##   assets/people/<name>.fbx (or .glb/.gltf/.dae)    standing
##   assets/people/<name>_sitting.fbx                  sitting (optional)
##   assets/animals/biscuit.glb (or biscuit/scene.gltf)
## where <name> is the character's name in lowercase with no spaces or
## periods: mom, dad, jamie, grandma, mrspatterson, tylerb, uncleray...
## Anyone without a model keeps the built-in figure. See docs/REAL_CHARACTERS.md.

const PEOPLE := "res://assets/people/"
const ANIMALS := "res://assets/animals/"
const EXTENSIONS := [".glb", ".gltf", ".fbx", ".dae", "/scene.gltf"]


static func key_for(person_name: String) -> String:
	return person_name.to_lower().replace(" ", "").replace(".", "").replace("_", "")


static func find_model(folder: String, base: String) -> String:
	for ext in EXTENSIONS:
		if ResourceLoader.exists(folder + base + ext):
			return folder + base + ext
	return ""


## Swaps a built-in person for their real model, if one is installed.
## The person's height (top of the head) and seat are kept.
static func apply_person(p: Node3D) -> bool:
	var key := key_for(String(p.get_meta("person_name", p.name)))
	var seated := p.has_node("Thighs") or p.has_node("Shins")
	var path := find_model(PEOPLE, key + ("_sitting" if seated else ""))
	if path == "" and seated:
		return false
	if path == "":
		path = find_model(PEOPLE, key)
	if path == "":
		return false
	var head := p.get_node_or_null("Head") as CSGSphere3D
	var top := (head.position.y + head.radius) if head else 1.6
	var model := (load(path) as PackedScene).instantiate() as Node3D
	var holder := Node3D.new()
	holder.name = "RealModel"
	holder.add_child(model)
	var b := Realism._aabb(model)
	model.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z)
	holder.scale = Vector3.ONE * (top / maxf(b.size.y, 0.01))
	# The block body goes; the collision shape stays.
	for c in p.get_children():
		if c is Node3D and not c is CollisionShape3D:
			(c as Node3D).visible = false
	p.add_child(holder)
	_play_idle(model)
	return true


## Loads Biscuit's real model, if installed. Returns the model's
## AnimationPlayer (or null), so the dog script can play walk/sit/lie.
static func apply_dog(dog: Node3D, shoulder_height := 0.42) -> AnimationPlayer:
	var path := find_model(ANIMALS, "biscuit")
	if path == "":
		return null
	var model := (load(path) as PackedScene).instantiate() as Node3D
	var holder := Node3D.new()
	holder.name = "RealModel"
	holder.add_child(model)
	var b := Realism._aabb(model)
	model.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z)
	# Models are usually measured nose-to-tail; fit the overall height to a
	# medium dog (head a little above the shoulder).
	holder.scale = Vector3.ONE * (shoulder_height * 1.3 / maxf(b.size.y, 0.01))
	# Most exports face +Z; the dog's script treats -Z as forward.
	holder.rotation_degrees.y = 180.0
	dog.add_child(holder)
	var anim := model.find_children("*", "AnimationPlayer", true, false)
	return anim[0] as AnimationPlayer if not anim.is_empty() else null


## Plays an idle/standing animation if the model came with one.
static func _play_idle(model: Node) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var ap := players[0] as AnimationPlayer
	for name in ap.get_animation_list():
		if "idle" in name.to_lower() or "stand" in name.to_lower() or "breath" in name.to_lower():
			ap.play(name)
			return


## Picks the animation whose name best matches one of `words`.
static func animation_like(ap: AnimationPlayer, words: Array) -> String:
	if ap == null:
		return ""
	for w in words:
		for name in ap.get_animation_list():
			if w in name.to_lower():
				return name
	return ""
