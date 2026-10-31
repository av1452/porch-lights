extends CanvasLayer
## Esc during a chapter: Resume, Settings, Photo Album, Main Menu, Quit.
## Owned by the Game autoload, so it works in every chapter.

var _root: Control


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open() -> void:
	visible = true
	_show_main()


func _clear() -> void:
	if _root:
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)


func _show_main() -> void:
	_clear()
	var p := UI.panel(Vector2(200, 0))
	var box := VBoxContainer.new()
	p.add_child(box)
	box.add_child(UI.label("Paused", 16, UI.GOLD))
	var resume := UI.button("Resume", Game.resume)
	box.add_child(resume)
	box.add_child(UI.button("Settings", func() -> void:
		_clear()
		_root.add_child(UI.centered(UI.settings_panel(_show_main)))))
	box.add_child(UI.button("Photo Album", func() -> void:
		_clear()
		_root.add_child(UI.centered(UI.album(_show_main)))))
	box.add_child(UI.button("Main Menu", Game.to_menu))
	box.add_child(UI.button("Quit", func() -> void: get_tree().quit()))
	_root.add_child(UI.centered(p))
	resume.grab_focus()
