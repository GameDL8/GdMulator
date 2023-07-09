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
		# SBC
		OpCode.new(0xEB, &"SBC", 2, 2, substract_with_carry_to_register, register_a.name, AddressingMode.Immediate),
		# DCP
		OpCode.new(0xC7, &"DCP", 2, 5, increase_then_compare_register.bind(AddressingMode.ZeroPage, -1, register_a), StringName(), AddressingMode.ZeroPage),
		OpCode.new(0xD7, &"DCP", 2, 6, increase_then_compare_register.bind(AddressingMode.ZeroPage_X, -1, register_a), StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0xCF, &"DCP", 3, 6, increase_then_compare_register.bind(AddressingMode.Absolute, -1, register_a), StringName(), AddressingMode.Absolute),
		OpCode.new(0xDF, &"DCP", 3, 7, increase_then_compare_register.bind(AddressingMode.Absolute_X, -1, register_a), StringName(), AddressingMode.Absolute_X),
		OpCode.new(0xDB, &"DCP", 3, 7, increase_then_compare_register.bind(AddressingMode.Absolute_Y, -1, register_a), StringName(), AddressingMode.Absolute_Y),
		OpCode.new(0xC3, &"DCP", 2, 8, increase_then_compare_register.bind(AddressingMode.Indirect_X, -1, register_a), StringName(), AddressingMode.Indirect_X),
		OpCode.new(0xD3, &"DCP", 2, 8, increase_then_compare_register.bind(AddressingMode.Indirect_Y, -1, register_a), StringName(), AddressingMode.Indirect_Y),
		# ISB
		OpCode.new(0xE7, &"ISB", 2, 5, increase_memory_decrease_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0xF7, &"ISB", 2, 6, increase_memory_decrease_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0xEF, &"ISB", 3, 6, increase_memory_decrease_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0xFF, &"ISB", 3, 7, increase_memory_decrease_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0xFB, &"ISB", 3, 7, increase_memory_decrease_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0xE3, &"ISB", 2, 8, increase_memory_decrease_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0xF3, &"ISB", 2, 8, increase_memory_decrease_register, register_a.name, AddressingMode.Indirect_Y),
		# SLO
		OpCode.new(0x07, &"SLO", 2, 5, shift_left_memory_then_logic_or_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x17, &"SLO", 2, 6, shift_left_memory_then_logic_or_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x0F, &"SLO", 3, 6, shift_left_memory_then_logic_or_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x1F, &"SLO", 3, 7, shift_left_memory_then_logic_or_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x1B, &"SLO", 3, 7, shift_left_memory_then_logic_or_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x03, &"SLO", 2, 8, shift_left_memory_then_logic_or_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x13, &"SLO", 2, 8, shift_left_memory_then_logic_or_register, register_a.name, AddressingMode.Indirect_Y),
		# RLA
		OpCode.new(0x27, &"RLA", 2, 5, rotate_left_memory_then_logic_and_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x37, &"RLA", 2, 6, rotate_left_memory_then_logic_and_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x2F, &"RLA", 3, 6, rotate_left_memory_then_logic_and_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x3F, &"RLA", 3, 7, rotate_left_memory_then_logic_and_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x3B, &"RLA", 3, 7, rotate_left_memory_then_logic_and_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x23, &"RLA", 2, 8, rotate_left_memory_then_logic_and_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x33, &"RLA", 2, 8, rotate_left_memory_then_logic_and_register, register_a.name, AddressingMode.Indirect_Y),
		
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

func increase_then_compare_register(p_addressing_mode: AddressingMode, p_by_amount: int, p_register: Register8bits):
	increment_memory(p_addressing_mode, p_by_amount)
	compare_register(p_register, p_addressing_mode)

func increase_memory_decrease_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	increment_memory(p_addressing_mode, 1)
	substract_with_carry_to_register(p_register, p_addressing_mode)

func shift_left_memory_then_logic_or_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	arithmetic_shift_left_memory(p_addressing_mode)
	inclusive_or_with_register(p_register, p_addressing_mode)

func rotate_left_memory_then_logic_and_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	rotate_left_memory(p_addressing_mode)
	bitwise_and_with_register(p_register, p_addressing_mode)
