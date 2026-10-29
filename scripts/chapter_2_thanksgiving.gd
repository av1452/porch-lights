extends Chapter
## Chapter 2 — November. Thanksgiving at Grandma's.
## Say hi to Grandma → kids' table → dinner (time skip) → pie with Grandma →
## Chapter 3, the drive home.

enum Step { HI_GRANDMA, FIND_SEAT, DINNER, FIND_GRANDMA, END }

@onready var env: Environment = $WorldEnvironment.environment
@onready var lights: Node3D = $Lights
@onready var story: Node3D = $Story
@onready var grandma_standing: Interactable = $Story/Grandma
@onready var grandma_stool: Node3D = $Story/GrandmaStool
@onready var grandma_table: Node3D = $Story/GrandmaAtTable
@onready var diners: Node3D = $Story/Diners
@onready var cousins: Node3D = $Story/Cousins
@onready var seat: Interactable = $Story/YourSeat
@onready var window_day: Node3D = $House/Furniture/WindowDay
@onready var tv_cart: Node3D = $House/Furniture/TVCart

var _tv: TvScreen
var _tv_flicker_t := 0.0


func _ready() -> void:
	super._ready()
	stash(grandma_stool)
	stash(grandma_table)
	_install_tv()

	grandma_standing.used.connect(_on_grandma_hi)
	(grandma_stool.get_node("Grandma") as Interactable).used.connect(_on_grandma_stool)
	(grandma_table.get_node("Grandma") as Interactable).used.connect(_on_grandma_table)
	seat.used.connect(_on_seat)

	add_chatter(diners.get_node("UncleRay"), "Uncle Ray", [
		"There's my favorite nephew. Leo! You got taller. Or I got shorter.",
		"Pull my finger. ...No? Smart kid.",
	])
	add_chatter(diners.get_node("AuntLisa"), "Aunt Lisa", [
		"You got so big! What grade are you in now?",
		"Maddie's been asking when you'd get here all morning.",
	])
	add_chatter(diners.get_node("Dad"), "Dad", [
		"Save room. Grandma made two pies and she'll know if you didn't have both.",
		"The dog show's on after the parade. Biscuit would win. Don't tell the other dogs.",
		"Uncle Ray's telling the fishing story again. Act surprised.",
	])
	add_chatter(diners.get_node("Mom"), "Mom", [
		"Elbows, hon.",
		"Go sit with your cousins. Grown-up table's full.",
	])
	add_chatter(diners.get_node("Jamie"), "Jamie", [
		"I'm at the big table now. It's honestly kind of boring.",
		"Don't tell anyone, but I miss the kids' table.",
	])
	add_chatter(cousins.get_node("Maddie"), "Maddie", ["Want to go look at Grandma's button jar after dinner?"])
	add_chatter(cousins.get_node("Tyler"), "Tyler", ["I can burp the whole alphabet. I'm saving it for dessert."])
	add_chatter(cousins.get_node("Ben"), "Ben", ["I'm four and three-quarters."])

	Audio.make_loop("room_tone", self, -22.0, "SFX", false)
	await open_chapter("November", "Thanksgiving at Grandma's")
	hud.show_memory("The car ride took forever. Grandma's house smells exactly the same as last year.", 5.0)
	await wait(2.5)
	objective("Say hi to Grandma")


## The game's on all day: put a live picture on Grandma's TV cart. Drop a
## real clip in as media/football.ogv and it plays instead (TvScreen).
func _install_tv() -> void:
	var old := tv_cart.get_node("Screen") as Node3D
	var picture := MeshInstance3D.new()
	picture.name = "Picture"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.44, 0.32)
	picture.mesh = quad
	picture.position = old.position + Vector3(0, 0, 0.012)
	tv_cart.add_child(picture)
	old.visible = false
	_tv = TvScreen.new()
	_tv.screen_path = ^"../Picture"
	_tv.channel = "football"
	tv_cart.add_child(_tv)


func _process(delta: float) -> void:
	super._process(delta)
	# The TV light flickers with the picture, like a real one.
	_tv_flicker_t -= delta
	if _tv_flicker_t > 0.0 or _tv == null:
		return
	_tv_flicker_t = randf_range(0.08, 0.25)
	var glow := lights.get_node("TVGlow") as OmniLight3D
	glow.light_energy = 0.5 * randf_range(0.75, 1.15)
	glow.light_color = glow.light_color.lerp(_tv.light_color(), 0.5)


func _exit_tree() -> void:
	free_stashed([grandma_standing, grandma_stool, grandma_table, diners, cousins])


func _on_grandma_hi(_by: Node) -> void:
	if busy or step != Step.HI_GRANDMA:
		return
	step = Step.FIND_SEAT
	busy = true
	await say([
		["Grandma", "There's my favorite. Don't tell your cousins."],
		["Grandma", "Look at you. You'll be taller than me by Christmas."],
	])
	# She climbs up on her step stool to supervise the kitchen, like a queen.
	await hud.fade(0.6, 0.6).finished
	stash(grandma_standing)
	unstash(grandma_stool, story)
	await hud.fade(0.0, 0.8).finished
	await say([
		["", "She hands you the can opener and the cranberry sauce. It slides out in one piece, ridges and all. Perfect."],
		["Grandma", "Now that's a cranberry log. Go find your seat, honey. Kids' table's by the window."],
	])
	seat.enabled = true
	busy = false
	objective("Find your seat at the kids' table")


func _on_grandma_stool(_by: Node) -> void:
	if busy:
		return
	var pool := ["Did you wash your hands? Show me. ...Good.", "Taste this gravy. Too much pepper? Don't tell your uncle."]
	say([["Grandma", pool[randi() % pool.size()]]])


func _on_seat(_by: Node) -> void:
	if busy or step != Step.FIND_SEAT:
		return
	step = Step.DINNER
	busy = true
	seat.enabled = false
	objective("")
	player.sit(Vector3(-1.5, 0.05, 1.25), 180.0)
	await say([
		["Maddie", "Jamie's at the big table this year."],
		["Tyler", "That's so unfair. They're not even that old."],
		["Ben", "I'm gonna sit at the big table when I'm eleven."],
		["Maddie", "You have to be, like, in high school."],
		["", "You look over. Jamie's laughing at something Uncle Ray said. They don't look back."],
		["Aunt Lisa", "Kids' table, look up! Say 'turkey!'"],
	])
	await Game.take_photo("The kids' table", "'03 11 27")
	Audio.play_sfx("switch_click", null, 2.0)
	await hud.fade(0.85, 0.05, Color.WHITE).finished
	await hud.fade(0.0, 0.6, Color.WHITE).finished
	await wait(1.5)
	await _after_dinner()


func _after_dinner() -> void:
	busy = true
	lock(true)
	await hud.fade(1.0, 2.0).finished
	hud.show_line("", "Turkey. Too many rolls. Somebody knocks over the cranberry sauce.")
	await wait(3.5)
	hud.show_line("", "Pie. Football. The grown-ups' voices getting louder and happier.")
	await wait(3.5)
	hud.clear_line()

	# Evening: everyone drifts to the den. The house goes quiet.
	stash(diners)
	stash(cousins)
	stash(grandma_stool)
	unstash(grandma_table, story)
	window_day.visible = false
	(lights.get_node("WindowLight") as OmniLight3D).light_energy = 0.0
	(lights.get_node("KitchenLight") as OmniLight3D).light_energy = 0.4
	env.ambient_light_energy = 0.3
	player.stand(Vector3(-1.5, 0.05, 1.25), 180.0)

	await wait(1.0)
	await hud.fade(0.0, 2.5).finished
	lock(false)
	busy = false
	step = Step.FIND_GRANDMA
	hud.show_memory("Everyone's in the den watching the game. The house got quiet all at once.", 5.0)
	await wait(5.5)
	# Through the wall, under the game: Mom and Dad, quietly.
	await say([
		["Mom (den)", "She's moving slower this year."],
		["Dad (den)", "She's allowed to slow down a little, hon."],
		["Mom (den)", "I know. I just noticed, that's all."],
	])
	await wait(1.0)
	objective("Find Grandma")


func _on_grandma_table(_by: Node) -> void:
	if busy or step != Step.FIND_GRANDMA:
		return
	step = Step.END
	busy = true
	objective("")
	player.sit(Vector3(-0.7, 0.05, -1.95), 180.0)
	Audio.play_music("ending", 4.0, -2.0)
	await say([
		["Grandma", "Come sit with me a minute."],
		["", "She cuts you the first slice of pie, even though dinner was twenty minutes ago."],
		["Grandma", "Your mom used to sit right there. Same spot. Same face when she ate pie."],
		["Grandma", "Don't grow up too fast on me, okay? Promise."],
		["", "You promise. It seems like an easy one to keep."],
	])
	await wait(2.0)
	lock(true)
	await hud.fade(1.0, 3.0).finished
	Audio.stop_music(3.0)
	await wait(1.0)
	go_to_chapter("res://scenes/chapter_3_drive_home.tscn")
