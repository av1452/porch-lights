class_name Interactable
extends StaticBody3D
## Anything the player can look at and use.
## Fill in the text in the Inspector. Connect to `used` for special behavior
## (starting a dream, advancing the chapter, playing a sound, etc).

signal used(by: Node)

@export var prompt := "Look"
## The thought that appears the first time you use this.
@export_multiline var memory_text := ""
## Optional different thought on later uses. Falls back to memory_text.
@export_multiline var repeat_text := ""
## Sound from audio/sfx played on use.
@export var use_sfx := ""
@export var memory_duration := 5.0
@export var enabled := true
@export var one_shot := false

var times_used := 0


func interact(by: Node) -> void:
	if not enabled:
		return
	var text := memory_text
	if times_used > 0 and repeat_text != "":
		text = repeat_text
	times_used += 1
	if use_sfx != "":
		Audio.play_sfx(use_sfx, self, 0.0, 0.05)
	if one_shot:
		enabled = false
	if text != "":
		get_tree().call_group("hud", "show_memory", text, memory_duration)
	used.emit(by)
