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
	# "Home for Winter Break" (chapter_4_winter_break) is out of the order; its
	# moments are being folded into Christmas Eve and Winter Break.
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
	"master": 1.0, "music": 1.0, "voice": 1.0, "sfx": 1.0,
	"sensitivity": 1.0, "subtitles": true, "fullscreen": false,
}
## Each photo: { "file": "user://photos/...png" or "", "caption": "...", "stamp": "'03 12 24" }
var photos: Array = []

var _pause: CanvasLayer
## Headless runs (the playtests) never read or write your save or album.
var _testing := DisplayServer.get_name() == "headless"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


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

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var scene := get_tree().current_scene
	if scene == null or not scene is Chapter:
		return
	if _pause and _pause.visible:
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
