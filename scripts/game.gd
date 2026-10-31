extends Node
## Autoload "Game": the chapter order, saved progress, settings, the photo
## album, and the pause menu (Esc). Progress and photos live in user://.

## The story in order. Chapter scripts don't need to know their number.
const CHAPTERS := [
	{ "scene": "res://scenes/chapter_1_halloween.tscn", "date": "October 31", "title": "Halloween" },
	# Thanksgiving is one chapter in parts; each part is its own scene.
	{ "scene": "res://scenes/chapter_2_getting_ready.tscn", "date": "November", "title": "Thanksgiving: Getting Ready" },
	{ "scene": "res://scenes/chapter_2_thanksgiving.tscn", "date": "November", "title": "Thanksgiving: At Grandma's" },
	{ "scene": "res://scenes/chapter_3_drive_home.tscn", "date": "November", "title": "Thanksgiving: The Drive Home" },
	{ "scene": "res://scenes/school_class_party.tscn", "date": "December 19", "title": "The Last Day Before Winter Break" },
	{ "scene": "res://scenes/chapter_5_christmas_eve.tscn", "date": "December 24", "title": "Christmas Eve" },
	{ "scene": "res://scenes/chapter_6_christmas_morning.tscn", "date": "December 25", "title": "Christmas Morning" },
	{ "scene": "res://scenes/winter_break_days.tscn", "date": "December 28", "title": "Winter Break" },
	{ "scene": "res://scenes/chapter_7_new_years_eve.tscn", "date": "December 31", "title": "New Year's Eve" },
]
const MENU_SCENE := "res://scenes/main_menu.tscn"
const SAVE_PATH := "user://save.cfg"
const PHOTO_DIR := "user://photos"

## Highest chapter index you've started, and the one you're in (-1 = menu).
var reached := 0
var current := -1
var finished := false
var settings := {
	# audio
	"master": 1.0, "music": 1.0, "voice": 1.0, "sfx": 1.0, "mono": false,
	# display
	"fullscreen": false, "fov": 75.0,
	# controls
	"sensitivity": 1.0, "invert_y": false, "toggle_run": false, "toggle_crouch": false,
	# accessibility: text
	"subtitles": true, "text_size": 1, "text_background": false, "sound_captions": false, "text_hold": 1.0,
	# accessibility: vision and motion
	"read_aloud": false, "narrate_menus": false, "head_bob": true, "reduce_flashing": false, "crosshair": true,
}
## Where players download the game, leave feedback, and can support it.
const ITCH_URL := "https://aidanbuilds.itch.io/porch-lights"
## Subtitle / interface text sizes for the "text_size" setting.
const TEXT_SCALES := [0.85, 1.0, 1.3, 1.65]
const TEXT_SIZE_NAMES := ["Small", "Medium", "Large", "Extra large"]
var _tts_voice := ""
var _defaults := {}
## Each photo: { "file": "user://photos/...png" or "", "caption": "...", "stamp": "'03 12 24" }
var photos: Array = []

var _pause: CanvasLayer
## Headless runs (the playtests) never read or write your save or album.
var _testing := DisplayServer.get_name() == "headless"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Controls.setup()
	_defaults = settings.duplicate()
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	load_game()
	apply_settings()


# ---------------------------------------------------------------- saving

func load_game() -> void:
	if _testing:
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	reached = cfg.get_value("progress", "reached", 0)
	finished = cfg.get_value("progress", "finished", false)
	photos = cfg.get_value("album", "photos", [])
	for k in settings:
		settings[k] = cfg.get_value("settings", k, settings[k])


func save_game() -> void:
	if _testing:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "reached", reached)
	cfg.set_value("progress", "finished", finished)
	cfg.set_value("album", "photos", photos)
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SAVE_PATH)


func apply_settings() -> void:
	var buses := { "Master": "master", "Music": "music", "Voice": "voice", "SFX": "sfx" }
	for bus in buses:
		var i := AudioServer.get_bus_index(bus)
		if i != -1:
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(settings[buses[bus]], 0.001)) + (-8.0 if bus == "Music" else 0.0))
	# The TV and through-the-wall voices follow the voice slider too.
	for bus in ["TV", "Muffled"]:
		var i := AudioServer.get_bus_index(bus)
		if i != -1:
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(settings.voice, 0.001)) + (-4.0 if bus == "TV" else 0.0))
	_apply_mono(settings.mono)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	# Text size, background, crosshair and field of view update live.
	get_tree().call_group("hud", "apply_settings")
	get_tree().call_group("player", "apply_settings")


func restore_defaults() -> void:
	settings = _defaults.duplicate()
	apply_settings()
	save_game()


## "Narrate menus": say what's selected as focus moves.
func _on_focus_changed(c: Control) -> void:
	if not settings.narrate_menus or c == null:
		return
	var words := ""
	if c is CheckBox:
		words = "%s, %s" % [(c as CheckBox).text, "on" if (c as CheckBox).button_pressed else "off"]
	elif c is OptionButton:
		words = "%s, %s" % [c.tooltip_text, (c as OptionButton).text]
	elif c is Button:
		words = (c as Button).text
	elif c is Range:
		words = "%s slider" % c.tooltip_text
	elif c is TabBar:
		words = "%s tab" % (c as TabBar).get_tab_title((c as TabBar).current_tab)
	if words != "":
		speak_aloud(words)


## Mono audio: fold left and right together on the Master bus, so nothing is
## missed by someone who hears in one ear.
func _apply_mono(on: bool) -> void:
	var master := AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) is AudioEffectStereoEnhance:
			AudioServer.remove_bus_effect(master, i)
			break
	if on:
		var mono := AudioEffectStereoEnhance.new()
		mono.pan_pullout = 0.0
		AudioServer.add_bus_effect(master, mono)


## Speaks text with the operating system's voice (read-aloud and menu
## narration). Quietly does nothing where text-to-speech isn't available.
func speak_aloud(text: String, interrupt := true) -> void:
	if text.strip_edges() == "" or DisplayServer.get_name() == "headless":
		return
	if _tts_voice == "":
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if voices.is_empty():
			return
		_tts_voice = voices[0]
	DisplayServer.tts_speak(text, _tts_voice, 60, 1.0, 1.0, 0, interrupt)


# ---------------------------------------------------------------- chapters

func index_of(scene_path: String) -> int:
	for i in CHAPTERS.size():
		if CHAPTERS[i].scene == scene_path:
			return i
	return -1


## Chapter.gd calls this when a chapter starts.
func chapter_started(scene_path: String) -> void:
	current = index_of(scene_path)
	if current > reached:
		reached = current
		save_game()


func start_chapter(index: int) -> void:
	get_tree().paused = false
	current = index
	get_tree().change_scene_to_file(CHAPTERS[index].scene)


func game_finished() -> void:
	finished = true
	save_game()


func to_menu() -> void:
	get_tree().paused = false
	_close_pause()
	current = -1
	Audio.stop_voice()
	Audio.stop_music(1.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)


func new_game() -> void:
	start_chapter(0)


# ---------------------------------------------------------------- photos

## Snaps the screen (without the HUD) into the album, like a disposable
## camera. `stamp` is the orange date in the corner, e.g. "'03 12 24".
func take_photo(caption: String, stamp: String) -> void:
	var entry := { "file": "", "caption": caption, "stamp": stamp }
	if _testing:
		photos.append(entry)
		return
	var huds := get_tree().get_nodes_in_group("hud")
	for h in huds:
		(h as CanvasLayer).visible = false
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	for h in huds:
		(h as CanvasLayer).visible = true
	if image and not image.is_empty():
		DirAccess.make_dir_recursive_absolute(PHOTO_DIR)
		var path := "%s/photo_%d_%d.png" % [PHOTO_DIR, photos.size(), Time.get_unix_time_from_system()]
		image.save_png(path)
		entry.file = path
	# Retaking a picture replaces the old one with the same caption.
	for i in photos.size():
		if photos[i].caption == caption:
			photos[i] = entry
			save_game()
			return
	photos.append(entry)
	save_game()


func clear_photos() -> void:
	photos.clear()
	save_game()


# ---------------------------------------------------------------- pause

## Esc or Start pauses; Esc, Start or B closes the pause menu again.
func _unhandled_input(event: InputEvent) -> void:
	var paused_open := _pause != null and _pause.visible
	var pause := event.is_action_pressed("pause")
	if not (pause or (paused_open and event.is_action_pressed("ui_cancel"))):
		return
	var scene := get_tree().current_scene
	if scene == null or not scene is Chapter:
		return
	if paused_open:
		resume()
	else:
		_open_pause()
	get_viewport().set_input_as_handled()


func _open_pause() -> void:
	if _pause == null:
		_pause = load("res://scripts/pause_menu.gd").new()
		add_child(_pause)
	_pause.call("open")
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_pause() -> void:
	if _pause:
		_pause.visible = false


func resume() -> void:
	_close_pause()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
