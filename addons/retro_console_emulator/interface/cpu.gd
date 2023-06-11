class_name CPU extends RefCounted

var program_counter := Register16bits.new(&"PC")
var memory: Memory = null

var registers: Dictionary = {
	program_counter.name : program_counter
}

var instructionset: Dictionary = {
	0x00: OpCode.new(0x00, &"BRK", 1, 1, quit)
}

var is_running: bool = false

func load_and_run(p_program: PackedByteArray):
	self.load(p_program)
	self.reset()
	self.run()

func reset():
	is_running = false
	assert(true, "This method should be implemented in inherited class")

func load(p_program: PackedByteArray):
	assert(true, "This method should be implemented in inherited class")

## VIRTUAL: This method runs the program loaded into the CPU's memory.
func run():
	is_running = true
	assert(memory != null, "Memory not initialized")
	assert(true, "This method should be implemented in inherited class")

func get_operand_address(p_mode: int) -> int:
	assert(true, "This method should be implemented in inherited class")
	return 0x00

func quit():
	is_running = false


func _about_to_execute_instruction():
	# VIRTUAL, implement in each cpu as needed
	pass

#8 bit register
class Register8bits:
	var value: int
	var name := StringName()
	
	func _init(p_name: StringName):
		assert(p_name != StringName())
		name = p_name

#16 bit register
class Register16bits:
	var value: int
	var name := StringName()
	
	func _init(p_name: StringName):
		assert(p_name != StringName())
		name = p_name

#flags register
class RegisterFlags:
	var value: int
	var name := StringName()
	
	func _init(p_name: StringName):
		assert(p_name != StringName())
		name = p_name
	

class BitFlag:
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
