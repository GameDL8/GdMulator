class_name NesCPU extends CPU6502


func _init() -> void:
	super()
	
	#register instructions
	var instructions: Array[OpCode] = [
		# NOP - DOP - TOP: Simple, double, and triple no operation
		OpCode.new(0x04, &"NOP", 2, 3,ilegal_no_operation, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x44, &"NOP", 2, 3,ilegal_no_operation, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x64, &"NOP", 2, 3,ilegal_no_operation, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x14, &"NOP", 2, 4,ilegal_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x34, &"NOP", 2, 4,ilegal_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x54, &"NOP", 2, 4,ilegal_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x74, &"NOP", 2, 4,ilegal_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0xD4, &"NOP", 2, 4,ilegal_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0xF4, &"NOP", 2, 4,ilegal_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x80, &"NOP", 2, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x82, &"NOP", 2, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x89, &"NOP", 2, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0xC2, &"NOP", 2, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0xE2, &"NOP", 2, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x0C, &"NOP", 3, 4,ilegal_no_operation, StringName(), AddressingMode.Absolute),
		OpCode.new(0x1C, &"NOP", 3, 4,ilegal_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0x3C, &"NOP", 3, 4,ilegal_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0x5C, &"NOP", 3, 4,ilegal_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0x7C, &"NOP", 3, 4,ilegal_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0xDC, &"NOP", 3, 4,ilegal_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0xFC, &"NOP", 3, 4,ilegal_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0x1A, &"NOP", 1, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x3A, &"NOP", 1, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x5A, &"NOP", 1, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x7A, &"NOP", 1, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0xDA, &"NOP", 1, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0xFA, &"NOP", 1, 2,ilegal_no_operation, StringName(), AddressingMode.Immediate),
		# Load multiple registers
		OpCode.new(0xA7, &"LAX", 2, 3,load_registers8.bind([register_a, register_x], AddressingMode.ZeroPage), StringName(), AddressingMode.ZeroPage),
		OpCode.new(0xB7, &"LAX", 2, 4,load_registers8.bind([register_a, register_x], AddressingMode.ZeroPage_Y), StringName(), AddressingMode.ZeroPage_Y),
		OpCode.new(0xAF, &"LAX", 3, 4,load_registers8.bind([register_a, register_x], AddressingMode.Absolute), StringName(), AddressingMode.Absolute),
		OpCode.new(0xBF, &"LAX", 3, 4,load_registers8.bind([register_a, register_x], AddressingMode.Absolute_Y), StringName(), AddressingMode.Absolute_Y),
		OpCode.new(0xA3, &"LAX", 2, 6,load_registers8.bind([register_a, register_x], AddressingMode.Indirect_X), StringName(), AddressingMode.Indirect_X),
		OpCode.new(0xB3, &"LAX", 2, 5,load_registers8.bind([register_a, register_x], AddressingMode.Indirect_Y), StringName(), AddressingMode.Indirect_Y),
		# AAX: And registers
		OpCode.new(0x87, &"SAX", 2, 3, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.ZeroPage), StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x97, &"SAX", 2, 4, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.ZeroPage_Y), StringName(), AddressingMode.ZeroPage_Y),
		OpCode.new(0x83, &"SAX", 2, 6, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.Indirect_X), StringName(), AddressingMode.Indirect_X),
		OpCode.new(0x8F, &"SAX", 3, 4, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.Absolute), StringName(), AddressingMode.Absolute),
		
	]
	
	for instruction in instructions:
		instruction.set_meta(&"is_ilegal", true)
		instructionset[instruction.code] = instruction
		var bind_args: Array
		if instruction.callback.get_bound_arguments_count() == 0:
			if instruction.addresing_mode != -1:
				instruction.callback = instruction.callback.bind(instruction.addresing_mode)
			if instruction.register != StringName():
				if registers.has(instruction.register):
					instruction.callback = instruction.callback.bind(registers[instruction.register])
				elif flags.bit_flags.has(instruction.register):
					instruction.callback = instruction.callback.bind(flags.bit_flags[instruction.register])
				else:
					assert(false, "Unknown register name '%s'" % instruction.register)

func reset():
	super()
	program_counter.value = 0xC000

func ilegal_no_operation(_ignore: AddressingMode):
	pass

func load_registers8(p_registers: Array, p_addressing_mode: AddressingMode):
	for register in p_registers:
		load_register8(register, p_addressing_mode)

func bitwise_and_two_registers(p_reg_1: Register8bits, p_reg_2: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var result: int = p_reg_1.value & p_reg_2.value
	memory.mem_write(addr, result)
