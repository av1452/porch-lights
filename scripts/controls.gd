class_name Controls
## Every input action, for keyboard + mouse and for a controller (Xbox layout;
## PlayStation and Switch pads map to the same buttons). Set up once by the
## Game autoload and by the player; safe to call again.
##
##   Move        WASD / arrows          left stick
##   Look        mouse                  right stick
##   Interact    E / left click         A (or X)
##   Run         Shift                  click left stick (or LB)
##   Crouch      C / Ctrl               B (or click right stick)
##   Pause       Esc                    Start (B also closes the menu)

const LOOK_DEADZONE := 0.15
const MOVE_DEADZONE := 0.2

const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_C, KEY_CTRL],
	"interact": [KEY_E],
	"pause": [KEY_ESCAPE],
}
const BUTTONS := {
	"sprint": [JOY_BUTTON_LEFT_STICK, JOY_BUTTON_LEFT_SHOULDER],
	"crouch": [JOY_BUTTON_B, JOY_BUTTON_RIGHT_STICK],
	"interact": [JOY_BUTTON_A, JOY_BUTTON_X],
	"pause": [JOY_BUTTON_START],
}
## action → [axis, direction]
const AXES := {
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"look_left": [JOY_AXIS_RIGHT_X, -1.0],
	"look_right": [JOY_AXIS_RIGHT_X, 1.0],
	"look_up": [JOY_AXIS_RIGHT_Y, -1.0],
	"look_down": [JOY_AXIS_RIGHT_Y, 1.0],
}


static func setup() -> void:
	if InputMap.has_action("pause"):
		return
	var actions: Array = KEYS.keys()
	for a in BUTTONS.keys() + AXES.keys():
		if not a in actions:
			actions.append(a)
	for action: String in actions:
		var dead := LOOK_DEADZONE if action.begins_with("look") else MOVE_DEADZONE
		if not InputMap.has_action(action):
			InputMap.add_action(action, dead)
		for key: Key in KEYS.get(action, []):
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for b: JoyButton in BUTTONS.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
		if AXES.has(action):
			var jm := InputEventJoypadMotion.new()
			jm.axis = AXES[action][0]
			jm.axis_value = AXES[action][1]
			InputMap.action_add_event(action, jm)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("interact", click)
	# Godot's menu actions come with the D-pad and stick, but not A and B.
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var mb := InputEventJoypadButton.new()
		mb.button_index = pair[1]
		InputMap.action_add_event(pair[0], mb)


## True if this event came from a controller (so menus can keep focus on screen).
static func is_pad(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion
