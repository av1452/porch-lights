extends HouseChapter
## Chapter 7 — January 3. The last day of winter break. The last chapter.
## Same house as Chapter 1, the morning after the holidays are over.
## Help Mom take down the tree (an ornament memory for each) → write
## Grandma a thank-you note → one more round of Jamie's new game, practicing
## what you'll tell everyone at school → the porch light, on since Christmas
## Eve, finally goes off until next Halloween → The End.

enum Step { ORNAMENTS, THANK_YOU, JAMIE, PORCH_LIGHT, END }

const ORNAMENTS := [
	"Your kindergarten handprint ornament. Your hand was so small. Mom always hangs it in front.",
	"Jamie's macaroni star from second grade. Half the macaroni is gone. Jamie says it's 'vintage.'",
	"The glass bell from Grandma. You wrap it in two whole pages of newspaper, extra careful.",
]

var mom: Interactable
var jamie: Interactable
var _box: Interactable
var _note: Interactable
var _packed := 0


func _ready() -> void:
	super._ready()
	Decorations.christmas_tree(self, true)
	tv_screen.channel = "winter"
	set_porch_light(true)
	($House/Kitchen/Furniture/CalendarMonth as Label3D).text = "JANUARY"
	mom = $Story/Mom
	mom.visible = true
	mom.collision_layer = 1
	mom.enabled = true
	mom.position = Vector3(-1.5, 0.0, 0.3)
	mom.rotation.y = deg_to_rad(-140.0)
	dad.position = Vector3(1.9, 0.0, -1.9)
	dad.rotation.y = deg_to_rad(-30.0)
	jamie = Figure.person(self, "Jamie", Vector3(-0.5, 0.0, 2.05), 180.0, 1.62, Figure.JAMIE, true)

	_box = box_thing("OrnamentBox", Vector3(-1.6, 0.15, -0.6), Vector3(0.45, 0.3, 0.35), Color(0.62, 0.48, 0.32), "Pack an ornament")
	_note = box_thing("ThankYouNote", Vector3(4.6, 0.77, 0.4), Vector3(0.2, 0.01, 0.15), Color(0.95, 0.93, 0.85), "Write to Grandma")
	_note.enabled = false
	box_thing("Racer", Vector3(0.9, 0.09, 1.0), Vector3(0.3, 0.12, 0.18), Color(0.15, 0.35, 0.8), "Mega Robo Racer",
		"It's climbed the couch, Grandma's footstool, and Biscuit. Biscuit has filed a complaint.",
		"The batteries are already running low. Grandma said they would. She sent more.")
	var window := $House/LivingRoom/Things/Window as Interactable
	window.memory_text = "The snowman in the Kowalskis' yard has lost its head. Somebody's Christmas tree is out on the curb."
	window.repeat_text = "Gray sky, wet snow. Tomorrow there's school. Today there's still today."

	_box.used.connect(_on_box)
	_note.used.connect(_on_note)
	mom.used.connect(_on_mom)
	jamie.used.connect(_on_jamie)
	porch_switch.used.connect(_on_switch)
	add_chatter(dad, "Dad", [
		"Last box to the basement. Then the tree goes out to the curb. Sad day. Sad, sad day.",
		"Every year I say we'll take it down on New Year's. Every year it's the third.",
	])

	Audio.make_loop("wind", $Exterior/Ambience, -14.0)
	Audio.play_music("ch1_living_room", 4.0, -8.0)
	await open_chapter("January 3", "The Last Day of Winter Break")
	hud.show_memory("Last day of break. The tree's dropping needles everywhere. Biscuit has three of them stuck in his ear.", 5.5)
	await wait(3.0)
	objective("Help Mom take down the tree")


# --- Step 0: the ornaments ----------------------------------------------

func _on_box(_by: Node) -> void:
	if busy or step != Step.ORNAMENTS:
		return
	hud.show_memory(ORNAMENTS[_packed], 4.5)
	_packed += 1
	if _packed < ORNAMENTS.size():
		return
	step = Step.THANK_YOU
	_box.enabled = false
	busy = true
	await wait(3.0)
	await say([
		["Mom", "Every year I think I'll remember which box is which. Every year I write NEXT YEAR, LABEL THE BOXES on the lid."],
		["Mom", "Hey. Before you forget, write Grandma her thank-you note. Kitchen table. Use your best handwriting."],
	])
	_note.enabled = true
	busy = false
	objective("Write Grandma a thank-you note")


func _on_mom(_by: Node) -> void:
	if busy:
		return
	match step:
		Step.ORNAMENTS:
			say([["Mom", "Wrap the glass ones in newspaper, hon. Two pages for Grandma's bell."]])
		Step.PORCH_LIGHT:
			say([["Mom", "Go on. Porch light. You do the honors."]])
		_:
			say([["Mom", "Last day of break. You want pizza tonight? Real pizza. Not Dad pizza."]])


func _on_note(_by: Node) -> void:
	if busy or step != Step.THANK_YOU:
		return
	step = Step.JAMIE
	_note.enabled = false
	await say([
		["", "'Dear Grandma, thank you for the pajamas and the batteries. The robot car can climb the couch.'"],
		["", "'Love, Leo. P.S. Biscuit says thank you for the bandana. P.P.S. Your fudge is the best fudge.'"],
		["", "You draw the porch light at the bottom, with the light coming out of it in yellow marker."],
	])
	objective("Play one more round with Jamie")


# --- Step 2: player two ---------------------------------------------------

func _on_jamie(_by: Node) -> void:
	if busy:
		return
	if step != Step.JAMIE:
		say([["Jamie", "Hold on, I'm about to beat this level. Okay I'm not. Hold on."]])
		return
	step = Step.PORCH_LIGHT
	busy = true
	player.sit(Vector3(0.45, 0.05, 1.95), 0.0)
	lock(true)
	await say([
		["Jamie", "Last day of break. One more round. You can be player two."],
		["", "You're always player two. You don't care. You lose four times and win once, and it's the best win of your whole life."],
		["Jamie", "Tomorrow at school everybody's gonna ask what you got."],
		["", "You practice: robot car, climbs walls, batteries from Grandma, matching pajamas, snowball, the dead bulb you found yourself."],
		["Jamie", "Nobody's gonna care about the bulb."],
		["", "Everybody's going to care about the bulb."],
	])
	await wait(0.5)
	await say([["Dad", "Hold on! One picture left on the roll. Everybody on the couch. Biscuit too!"]])
	await Game.take_photo("Last picture on the roll", "'04 01 03")
	Audio.play_sfx("switch_click", null, 2.0)
	await hud.fade(0.85, 0.05, Color.WHITE).finished
	await hud.fade(0.0, 0.6, Color.WHITE).finished
	await say([["Mom", "Hey, Leo? The porch light's been on since Christmas Eve. Nine whole days. Want to do the honors?"]])
	player.stand(Vector3(0.45, 0.05, 1.3), 0.0)
	lock(false)
	busy = false
	objective("Turn off the porch light")


# --- Step 3: the porch light --------------------------------------------

func _on_switch(_by: Node) -> void:
	if busy or step != Step.PORCH_LIGHT:
		return
	step = Step.END
	busy = true
	objective("")
	lock(true)
	set_porch_light(false)
	await say([
		["", "Click."],
		["Mom", "There. Until next Halloween."],
		["Dad", "Okay! Who wants real pizza?"],
		["Jamie", "Not Dad pizza."],
		["Dad", "I heard that."],
	])
	await wait(1.0)
	await hud.fade(1.0, 3.0).finished
	Audio.play_music("ending", 4.0, -6.0)
	await say([
		["", "Candy taxes, and the kids' table, and the first Christmas song on the radio."],
		["", "Untangling lights. Snow blobs. Reindeer pajamas. Batteries from Grandma."],
		["", "Years from now, you'll forget what most of the presents were."],
		["", "You'll never forget the porch lights."],
	])
	await wait(2.0)
	await hud.chapter_card("Porch Lights", "The End", 5.0)
	hud.show_memory("For everyone who ever left a light on.", 6.0)
	await wait(7.0)
	Game.game_finished()
	_show_album()


## The pictures came back from the drugstore. Then back to the title screen.
func _show_album() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	layer.add_child(UI.centered(UI.album(Game.to_menu, "Your pictures are back from the drugstore")))
