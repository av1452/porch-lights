class_name Interactable
extends StaticBody3D
## Anything the player can look at and use.
## Give it a voiced line id from data/lines.json (or plain text in the
## Inspector). Connect to `used` for special behavior
## (starting a dream, advancing the chapter, playing a sound, etc).

signal used(by: Node)

@export var prompt := "Look"
## Line id in data/lines.json spoken the first time you use this.
@export var line_id := ""
## Line ids for later uses, cycled in order. Falls back to line_id.
@export var repeat_line_ids: PackedStringArray = []
## Sound from audio/sfx played on use.
@export var use_sfx := ""
## Unvoiced fallback thought, used when line_id is empty.
@export_multiline var memory_text := ""
## Optional different unvoiced thought on later uses. Falls back to memory_text.
@export_multiline var repeat_text := ""
@export var memory_duration := 5.0
@export var enabled := true
@export var one_shot := false
## When false, `used` fires but no line plays (the chapter script speaks).
@export var speak := true

var times_used := 0


func interact(by: Node) -> void:
	if not enabled:
		return
	var first := times_used == 0
	times_used += 1
	if one_shot:
		enabled = false
	if use_sfx != "":
		Audio.play_sfx(use_sfx, self, 0.0, 0.05)
	if speak:
		_speak(first)
	used.emit(by)


func _speak(first: bool) -> void:
	var id := line_id
	if not first and not repeat_line_ids.is_empty():
		id = repeat_line_ids[(times_used - 2) % repeat_line_ids.size()]
	if id != "":
		Audio.say(id)
		return
	var text := memory_text
	if not first and repeat_text != "":
		text = repeat_text
	if text != "":
		get_tree().call_group("hud", "show_memory", text, memory_duration)
