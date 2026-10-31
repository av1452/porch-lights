extends SceneTree
# Controller support: feeds simulated stick and button events into the game
# and checks that Leo looks, walks, interacts and pauses. Run headless:
# godot --headless -s res://tests/playtest_controller.gd
var ch
func axis(a: JoyAxis, v: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = a
	ev.axis_value = v
	Input.parse_input_event(ev)
func press(b: JoyButton) -> void:
	for down in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.button_index = b
		ev.pressed = down
		Input.parse_input_event(ev)
		await process_frame
func _initialize():
	Engine.time_scale = 6.0
	ch = load("res://scenes/chapter_1_halloween.tscn").instantiate()
	root.add_child(ch)
	current_scene = ch # the pause menu only opens over the current chapter
	await create_timer(9.0).timeout
	Engine.time_scale = 1.0
	var p = ch.player
	print("locked=", p.input_locked)
	# Right stick: look right and up.
	var yaw0: float = p.rotation.y
	var pitch0: float = p.head.rotation.x
	axis(JOY_AXIS_RIGHT_X, 1.0); axis(JOY_AXIS_RIGHT_Y, -1.0)
	await create_timer(0.5).timeout
	axis(JOY_AXIS_RIGHT_X, 0.0); axis(JOY_AXIS_RIGHT_Y, 0.0)
	print("look: turned right=", p.rotation.y < yaw0 - 0.2, " looked up=", p.head.rotation.x > pitch0 + 0.1)
	# A tiny tilt stays inside the deadzone.
	var yaw1: float = p.rotation.y
	axis(JOY_AXIS_RIGHT_X, 0.1)
	await create_timer(0.3).timeout
	axis(JOY_AXIS_RIGHT_X, 0.0)
	print("deadzone ignores drift=", is_equal_approx(p.rotation.y, yaw1))
	# Left stick: walk forward.
	p.head.rotation.x = 0.0
	var pos0: Vector3 = p.global_position
	axis(JOY_AXIS_LEFT_Y, -1.0)
	await create_timer(0.6).timeout
	axis(JOY_AXIS_LEFT_Y, 0.0)
	print("walked=", p.global_position.distance_to(pos0) > 0.5)
	# A on the candy, the chapter's first step.
	var candy = ch.get_node("Story/Candy")
	p.teleport(candy.global_position + Vector3(0, 0.05, 0.9), 0.0)
	p.tween_look_at(candy.global_position + Vector3(0, 0.2, 0), 0.01)
	await create_timer(0.3).timeout
	var step0: int = ch.step
	await press(JOY_BUTTON_A)
	await create_timer(0.5).timeout
	print("A interacts: step ", step0, " -> ", ch.step)
	# Start pauses, B resumes.
	await press(JOY_BUTTON_START)
	print("start pauses=", paused)
	await press(JOY_BUTTON_B)
	print("B resumes=", not paused)
	# Start again, then A on the focused "Resume" button.
	await press(JOY_BUTTON_START)
	await process_frame
	var focused := root.gui_get_focus_owner()
	print("menu focus on: ", focused.text if focused is Button else focused)
	await press(JOY_BUTTON_A)
	await process_frame
	print("A chooses Resume=", not paused)
	# B in play is crouch, not pause.
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_B
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.3).timeout
	print("B crouches=", p.crouching, " not paused=", not paused)
	ev = ev.duplicate(); ev.pressed = false
	Input.parse_input_event(ev)
	quit()
