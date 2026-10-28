extends Chapter
## December 19 — The Class Party. The last day of school before winter break,
## in Mrs. Patterson's third-grade classroom (scripts/classroom.gd).
## Letter to Santa in the North Pole mailbox → cut a paper snowflake →
## Secret Santa (you get a Slinky, you give Maya glitter gel pens) → cupcakes,
## juice boxes, candy canes and the class picture → the claymation special on
## the TV cart and one last concert practice → the bell → Chapter 4 (home).

enum Step { LETTER, SNOWFLAKE, GIFT, MAYA, PARTY, RUG, BELL, END }

const TEACHER := { "legs": Color(0.25, 0.22, 0.3), "shirt": Color(0.75, 0.15, 0.18), "hair": Color(0.45, 0.3, 0.2), "long_hair": true }
const KIDS := {
	"Maya": { "legs": Color(0.2, 0.28, 0.45), "shirt": Color(0.6, 0.35, 0.75), "hair": Color(0.12, 0.08, 0.06), "long_hair": true },
	"Tyler B.": { "legs": Color(0.3, 0.3, 0.32), "shirt": Color(0.95, 0.55, 0.15), "hair": Color(0.85, 0.7, 0.4) },
	"Marcus": { "legs": Color(0.2, 0.28, 0.45), "shirt": Color(0.2, 0.55, 0.3), "hair": Color(0.08, 0.06, 0.05) },
	"Emily": { "legs": Color(0.85, 0.85, 0.9), "shirt": Color(0.95, 0.5, 0.65), "hair": Color(0.6, 0.3, 0.12), "long_hair": true },
	"Josh": { "legs": Color(0.2, 0.28, 0.45), "shirt": Color(0.2, 0.4, 0.8), "hair": Color(0.35, 0.22, 0.12) },
}

@onready var env: Environment = $WorldEnvironment.environment
@onready var room: Classroom = $Classroom

var teacher: Interactable
var kids := {}
var _mailbox: Interactable
var _crafts: Interactable
var _gifts: Interactable
var _snacks: Interactable
var _rug: Interactable
var _door: Interactable


func _ready() -> void:
	super._ready()
	teacher = Figure.person(self, "Mrs. Patterson", Classroom.TEACHER_DESK + Vector3(-1.4, 0, 0.5), 20.0, 1.65, TEACHER)
	var spots := {
		"Maya": [Vector3(-3.3, 0, 0.2), 150.0, false],
		"Tyler B.": [Vector3(2.3, 0, 2.3), 200.0, false],
		"Marcus": [Vector3(3.3, 0, 2.2), 160.0, false],
		"Emily": [Vector3(-3.9, 0, -1.3), 60.0, false],
		"Josh": [Vector3(0.8, 0, 0.42), 180.0, true],
	}
	for kid_name in spots:
		var s: Array = spots[kid_name]
		kids[kid_name] = Figure.person(self, kid_name, s[0], s[1], 1.3, KIDS[kid_name], s[2])
	add_chatter(kids["Tyler B."], "Tyler B.", [
		"My mom made the cupcakes. The sprinkles are the crunchy kind. You're welcome.",
		"I'm getting the new game system for Christmas. My cousin said. My cousin knows everything.",
	])
	add_chatter(kids["Marcus"], "Marcus", [
		"Did you see the Book Fair poster? It's in January. I already know what I'm getting.",
		"Two weeks with no school. That's like a hundred days.",
	])
	add_chatter(kids["Emily"], "Emily", [
		"I made my snowflake with eight sides. Mrs. Patterson says real ones have six. Mine's special.",
		"Are you a reindeer in the concert? I'm a bell. Bells are better.",
	])
	add_chatter(kids["Josh"], "Josh", [
		"I'm drawing a dragon on my letter to Santa, so he knows I'm serious.",
		"Is it three o'clock yet? Is it three o'clock now?",
	])

	_mailbox = _spot("NorthPoleMailbox", Classroom.TEACHER_DESK + Vector3(0.55, 0.82, -0.15), Vector3(0.25, 0.25, 0.25), "North Pole mailbox")
	_crafts = _spot("Crafts", Classroom.CRAFT_TABLE + Vector3(0, 0.66, 0), Vector3(1.1, 0.12, 0.6), "Make a paper snowflake")
	_gifts = _spot("SecretSanta", Classroom.GIFT_PILE + Vector3(0, 0.2, 0.05), Vector3(1.1, 0.4, 0.4), "Secret Santa pile")
	_snacks = _spot("Snacks", Classroom.PARTY_TABLE + Vector3(0, 0.75, 0), Vector3(1.9, 0.15, 0.7), "Party table")
	_rug = _spot("Rug", Classroom.RUG + Vector3(0, 0.05, 0), Vector3(2.8, 0.1, 1.9), "Sit on the reading rug")
	_door = _spot("Door", Classroom.DOOR + Vector3(-0.05, 1.05, 0), Vector3(0.1, 2.0, 0.9), "Go home for winter break!")
	for it in [_crafts, _gifts, _snacks, _rug, _door]:
		it.enabled = false
	var chalk := _spot("Chalkboard", Vector3(-0.4, 1.55, -3.95), Vector3(5.2, 1.3, 0.1), "Chalkboard")
	chalk.memory_text = "Somebody drew a snowman in the corner. Mrs. Patterson left it up. It's a pretty good snowman."
	var board := _spot("BulletinBoard", Vector3(4.95, 1.7, 1.2), Vector3(0.1, 1.2, 3.4), "Bulletin board")
	board.memory_text = "Your handprint turkey is up there from November. And the paper bats from October. Mrs. Patterson never takes anything down."
	board.repeat_text = "Your turkey says 'I am thankful for Biscuit and pie.' Correct."
	var window := _spot("Window", Vector3(-4.85, 1.75, 0.0), Vector3(0.1, 1.3, 1.8), "Look outside")
	window.memory_text = "It's starting to snow. The whole class saw it at the same time. Nobody can sit still now."

	_mailbox.used.connect(_on_mailbox)
	_crafts.used.connect(_on_crafts)
	_gifts.used.connect(_on_gifts)
	kids["Maya"].used.connect(_on_maya)
	_snacks.used.connect(_on_snacks)
	_rug.used.connect(_on_rug)
	_door.used.connect(_on_door)
	teacher.used.connect(_on_teacher)

	Audio.make_loop("classroom", self, -20.0, "SFX", false)
	await open_chapter("December 19", "The Class Party")
	hud.show_memory("Last day of school before winter break. Nobody's doing any work. Mrs. Patterson isn't even pretending.", 5.5)
	await wait(3.0)
	objective("Put your letter to Santa in the North Pole mailbox")


func _spot(node_name: String, pos: Vector3, size: Vector3, prompt_text: String) -> Interactable:
	var it := Interactable.new()
	it.name = node_name
	it.prompt = prompt_text
	it.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	it.add_child(shape)
	add_child(it)
	return it


func _on_teacher(_by: Node) -> void:
	if busy:
		return
	var pool := ["Inside voices! It's a party, not a stampede.", "Did everybody sign the card for the custodian? Mr. Ruiz is going to love it.",
		"Two weeks, and I want everybody reading something. Comic books count."]
	say([["Mrs. Patterson", pool[randi() % pool.size()]]])


# --- Step 0-1: letter to Santa, paper snowflake --------------------------

func _on_mailbox(_by: Node) -> void:
	if busy or step != Step.LETTER:
		return
	step = Step.SNOWFLAKE
	await say([
		["", "Dear Santa: Mega Robo Racer. Please. Thank you. P.S. I know it's a lot of batteries."],
		["Mrs. Patterson", "Into the North Pole mailbox! I'll make sure it gets there. I have connections."],
	])
	_crafts.enabled = true
	objective("Make a paper snowflake")


func _on_crafts(_by: Node) -> void:
	if busy or step != Step.SNOWFLAKE:
		return
	step = Step.GIFT
	busy = true
	_crafts.enabled = false
	Audio.play_sfx("scissors", _crafts, -2.0)
	await say([
		["", "Fold, fold, fold, snip, snip. You open it up and it's a perfect snowflake. Mostly perfect. One arm looks a little like a duck."],
		["Mrs. Patterson", "Beautiful! Tape it on the window with the others."],
	])
	room.add_snowflake(Vector3(Classroom.WINDOW_X + 0.05, 1.6, -0.2), Decorations.mat(Color(0.95, 0.85, 0.95)))
	_gifts.enabled = true
	busy = false
	objective("Secret Santa: find the gift with your name on it")


# --- Step 2-3: Secret Santa ---------------------------------------------

func _on_gifts(_by: Node) -> void:
	if busy or step != Step.GIFT:
		return
	step = Step.MAYA
	_gifts.enabled = false
	Audio.play_sfx("candy_rustle", _gifts, -2.0)
	await say([
		["", "A little box with your name on it in somebody's best handwriting. A Slinky!"],
		["", "You stretch it across two desks. It tangles immediately. Perfect."],
	])
	objective("Give Maya her Secret Santa gift")


func _on_maya(_by: Node) -> void:
	if busy:
		return
	if step != Step.MAYA:
		var pool := ["I'm writing you a note in purple. Purple glitter.", "Do you think it'll snow enough for a snow fort? I think it will."]
		say([["Maya", pool[randi() % pool.size()]]])
		return
	step = Step.PARTY
	await say([
		["", "You hand Maya the gel pens. Ten colors. Including glitter."],
		["Maya", "GLITTER GEL PENS. Okay. You're officially the best Secret Santa."],
	])
	_snacks.enabled = true
	objective("Get a cupcake from the party table")


# --- Step 4: the party, and the class picture ---------------------------

func _on_snacks(_by: Node) -> void:
	if busy or step != Step.PARTY:
		return
	step = Step.RUG
	busy = true
	_snacks.enabled = false
	await say([
		["", "Green frosting, the crunchy sprinkles. A juice box with a tiny straw you have to stab in exactly right."],
		["Tyler B.", "Told you. Crunchy sprinkles. Best cupcakes in the whole third grade."],
		["Mrs. Patterson", "Candy canes for everyone! And everybody squish together for a picture. Say 'winter break!'"],
	])
	await camera_flash("Mrs. Patterson's class party", "'03 12 19")
	await say([["Mrs. Patterson", "Okay, everybody on the reading rug. I have a surprise. It has wheels."]])
	_rug.enabled = true
	busy = false
	objective("Sit on the reading rug")


func camera_flash(caption: String, stamp: String) -> void:
	await Game.take_photo(caption, stamp)
	Audio.play_sfx("switch_click", null, 2.0)
	await hud.fade(0.85, 0.05, Color.WHITE).finished
	await hud.fade(0.0, 0.6, Color.WHITE).finished


# --- Step 5: the TV cart, the song, the bell -----------------------------

func _on_rug(_by: Node) -> void:
	if busy or step != Step.RUG:
		return
	step = Step.BELL
	busy = true
	objective("")
	_rug.enabled = false
	player.sit(Classroom.RUG + Vector3(0.3, -0.25, 0.3), -150.0)
	lock(true)
	room.tv_screen.channel = "winter"
	await player.tween_look_at(Classroom.TV_CART + Vector3(0, 1.5, 0), 1.0).finished
	await say([
		["", "Mrs. Patterson rolls in the TV cart. Everybody cheers like it's a rocket launch. The claymation reindeer special, on VHS."],
		["", "Halfway through, the tape goes fuzzy and Mrs. Patterson whacks the side of the TV. It works. Everybody cheers again."],
		["Mrs. Patterson", "Okay! One more practice for tonight's concert. From the top. Jingle bells..."],
	])
	room.tv_screen.channel = "off"
	Audio.play_music("school_jingle_bells", 1.0, -2.0)
	await say([
		["", "Everybody sings. You sing the loudest. 'Batman smells' goes around the back row. Mrs. Patterson pretends not to hear."],
		["", "Then the clock says 2:59, and everybody is very, very quiet."],
	])
	Audio.stop_music(1.5)
	await wait(2.0)
	Audio.play_sfx("school_bell", null, 0.0)
	await wait(1.0)
	await say([["Mrs. Patterson", "That's the bell! Have a wonderful winter break, everybody! Read a book! Any book!"]])
	player.stand(Classroom.RUG + Vector3(0.6, 0.05, -0.6), -90.0)
	lock(false)
	_door.enabled = true
	busy = false
	objective("Go home for winter break!")


func _on_door(_by: Node) -> void:
	if busy or step != Step.BELL:
		return
	step = Step.END
	busy = true
	lock(true)
	Audio.play_sfx("door_close", _door)
	await hud.fade(1.0, 2.0).finished
	await say([["", "The bus ride home is the loudest bus ride of the year. Two whole weeks. And it's snowing."]])
	await wait(1.5)
	go_to_chapter("res://scenes/chapter_4_winter_break.tscn")
