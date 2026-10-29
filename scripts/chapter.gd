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
	Game.chapter_started(scene_file_path)
	# Deferred, so it also covers everything the chapter builds in its _ready.
	Look.upgrade.call_deferred(self)


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
## Longer sequences set busy = true themselves so nothing interrupts them.
func say(lines: Array) -> void:
	var was_busy := busy
	busy = true
	for l: Array in lines:
		var text: String = l[1]
		hud.show_line(l[0], text)
		var voiced := Audio.speak(l[0], text)
		await wait(maxf(1.8 + text.length() * 0.045, voiced + 0.4))
	hud.clear_line()
	busy = was_busy


func objective(text: String) -> void:
	hud.set_objective(text)


## Tween a hinged door (an Interactable whose origin is the hinge).
func swing_door(door: Node3D, degrees: float, time: float = 1.2) -> void:
	Audio.play_sfx("door_open", door, -4.0)
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(door, "rotation:y", deg_to_rad(degrees), time)
	await t.finished


func go_to_chapter(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


## Simple background chatter: each use plays the next line from the list.
func add_chatter(who: Interactable, speaker: String, lines: Array) -> void:
	var state := {"i": 0}
	who.used.connect(func(_by: Node) -> void:
		# A chapter can mute someone while they're part of a scene.
		if busy or lines.is_empty() or who.has_meta("mute_chatter"):
			return
		var text: String = lines[state.i % lines.size()]
		state.i += 1
		say([[speaker, text]]))


## Detach a node from the scene but keep it around (for swapping room states).
func stash(node: Node) -> void:
	if node.is_inside_tree():
		node.get_parent().remove_child(node)


func unstash(node: Node, parent: Node) -> void:
	if not node.is_inside_tree():
		parent.add_child(node)


## Free anything stashed when the chapter ends, so nothing leaks.
func free_stashed(nodes: Array) -> void:
	for n: Node in nodes:
		if is_instance_valid(n) and n.get_parent() == null:
			n.free()
