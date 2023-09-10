class_name NesJoypad extends RefCounted

enum JoypadButton {
	RIGHT      = 0b10000000,
	LEFT       = 0b01000000,
	DOWN       = 0b00100000,
	UP         = 0b00010000,
	START      = 0b00001000,
	SELECT     = 0b00000100,
	BUTTON_B   = 0b00000010,
	BUTTON_A   = 0b00000001,
}

const ACTION_LOOP: Array[StringName] = [
	&"nes_button_a",
	&"nes_button_b",
	&"nes_button_select",
	&"nes_button_start",
	&"nes_button_up",
	&"nes_button_down",
	&"nes_button_left",
	&"nes_button_right",
]

var action_sufix: StringName = StringName()
var strobe: bool = false
var button_index: int = 0
var button_status: int = 0b00000000


func _init(p_action_sufix: StringName) -> void:
	action_sufix = p_action_sufix


func write(p_data: int):
	strobe = (p_data & 1) == 1
	if strobe:
		button_index = 0

func peek() -> int:
	if button_index > 7:
		return 1
	var response: int = (button_status & (1 << button_index)) >> button_index
	return response

func read() -> int:
	if button_index > 7:
		return 1
	var response: int = (button_status & (1 << button_index)) >> button_index
	if !strobe && button_index <= 7:
		button_index += 1
	return response

func update_status():
	button_status = 0
	for idx in range(8):
		var action: StringName = ACTION_LOOP[idx] + action_sufix
		if !InputMap.has_action(action):
			continue
		var is_pressed: bool = Input.is_action_pressed(action, true)
		if is_pressed:
			var bit = 1 << idx
			button_status |= bit
