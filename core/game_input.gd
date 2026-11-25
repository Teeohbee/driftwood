extends Node

## Registers Driftwood's input actions in code, so they are readable here
## instead of buried in project.godot.
##
## A = interact / confirm, B = cancel, Start = pause / title.

const KEYS_FOR_ACTION := {
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"action_a": [KEY_Z, KEY_SPACE, KEY_J],
	"action_b": [KEY_X, KEY_K],
	"start": [KEY_ENTER, KEY_ESCAPE],
}

const BUTTONS_FOR_ACTION := {
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"action_a": [JOY_BUTTON_A],
	"action_b": [JOY_BUTTON_B],
	"start": [JOY_BUTTON_START],
}

const STICK_FOR_ACTION := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}


func _ready() -> void:
	for action_name in KEYS_FOR_ACTION:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.3)
		for keycode in KEYS_FOR_ACTION[action_name]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action_name, key_event)
		for button in BUTTONS_FOR_ACTION.get(action_name, []):
			var button_event := InputEventJoypadButton.new()
			button_event.button_index = button
			InputMap.action_add_event(action_name, button_event)
		if STICK_FOR_ACTION.has(action_name):
			var stick_event := InputEventJoypadMotion.new()
			stick_event.axis = STICK_FOR_ACTION[action_name][0]
			stick_event.axis_value = STICK_FOR_ACTION[action_name][1]
			InputMap.action_add_event(action_name, stick_event)
