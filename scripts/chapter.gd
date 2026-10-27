class_name Chapter
extends Node3D
## Shared helpers for every chapter: dialogue, objectives, locking input,
## blinking clocks, and moving between chapters.

@onready var player: Player = $Player
@onready var hud: GameHud = $HUD

## Set while a conversation or cutscene is playing.
var busy := false
var step := 0
var _blink_t := 0.0
var _blink_on := true


func _ready() -> void:
	player.target_changed.connect(hud.set_target)


func _process(delta: float) -> void:
	# Anything in the "blink" group (VCR clocks, etc) flashes like it's 12:00.
	_blink_t += delta
	if _blink_t >= 0.6:
		_blink_t = 0.0
		_blink_on = not _blink_on
		for n in get_tree().get_nodes_in_group("blink"):
			(n as Node3D).visible = _blink_on


## Start-of-chapter: title over black, then fade in.
func open_chapter(title: String, subtitle: String) -> void:
	lock(true)
	await wait(0.6)
	await hud.chapter_card(title, subtitle)
	await hud.fade(0.0, 2.5).finished
	lock(false)


func lock(locked: bool) -> void:
	player.input_locked = locked
	hud.set_crosshair_visible(not locked)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Plays [[speaker, text], ...]. Speaker "" is narration.
## The player can keep walking around while people talk.
func say(lines: Array) -> void:
	busy = true
	for l: Array in lines:
		var text: String = l[1]
		hud.show_line(l[0], text)
		await wait(1.8 + text.length() * 0.045)
	hud.clear_line()
	busy = false


func objective(text: String) -> void:
	hud.set_objective(text)


## Tween a hinged door (an Interactable whose origin is the hinge).
func swing_door(door: Node3D, degrees: float, time: float = 1.2) -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(door, "rotation:y", deg_to_rad(degrees), time)
	await t.finished


func go_to_chapter(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
