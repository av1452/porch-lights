class_name Trigger
extends Area3D
## Invisible zone that fires when the player walks into it.
## Use for overheard conversations, thoughts, and story beats.

signal player_entered

@export var active := true
@export var one_shot := true
## Optional thought shown automatically when triggered.
@export_multiline var memory_text := ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not active or not body is Player:
		return
	if one_shot:
		active = false
	if memory_text != "":
		get_tree().call_group("hud", "show_memory", memory_text, 5.0)
	player_entered.emit()
