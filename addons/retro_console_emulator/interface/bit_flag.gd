class_name BitFlag extends RefCounted

var value: bool:
	set = set_bit,
	get = get_bit
var name := StringName()

var _register: RegisterFlags
var _bit_border: int

func _init(p_register: RegisterFlags, p_name: StringName, p_bit_order: int):
	assert(p_name != StringName())
	name = p_name
	_register = p_register
	_bit_border = p_bit_order

func set_bit(p_value: bool):
	if p_value:
		_register.value |= (1 << _bit_border)
	else:
		# ~(0b00100000) == (0b11011111)
		_register.value &= ~(1 << _bit_border)
func get_bit() -> bool:
	return _register.value & (1 << _bit_border)
