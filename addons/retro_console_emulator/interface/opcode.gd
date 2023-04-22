class_name OpCode extends RefCounted

var code: int = 0x00
var mnemonic: StringName
var size: int = 1
var cycles: int = 1
var callback := Callable()

func _init(p_code: int, p_mnemonic: StringName, p_size: int,
		p_cycles: int, p_callback: Callable):
	code = p_code
	mnemonic = p_mnemonic
	size = p_size
	cycles = p_cycles
	callback = p_callback
