class_name NesCPU extends CPU6502

var _sleeping: bool = false
const PAL_SLEEP_TIME: float = 1.0/50.0
const NTSC_SLEEP_TIME: float = 1.0/60.0

func _init() -> void:
	super()
	memory = NesMemory.new()
	memory.nmi_interrupt_triggered.connect(_on_interrupt_triggered.bind(0xFFFA, false))
	memory.irq_interrupt_triggered.connect(_on_interrupt_triggered.bind(0xFFFE, false))
	memory.advance_frame.connect(_on_memory_advance_frame)
	
	#register instructions
	var instructions: Array[OpCode] = [
		# BRK on NES system forces an interrupt
		OpCode.new(0x00, &"BRK", 1, 1, nes_break),
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
		# SRE
		OpCode.new(0x47, &"SRE", 2, 5, shift_right_memory_then_exclusive_or_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x57, &"SRE", 2, 6, shift_right_memory_then_exclusive_or_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x4F, &"SRE", 3, 6, shift_right_memory_then_exclusive_or_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x5F, &"SRE", 3, 7, shift_right_memory_then_exclusive_or_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x5B, &"SRE", 3, 7, shift_right_memory_then_exclusive_or_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x43, &"SRE", 2, 8, shift_right_memory_then_exclusive_or_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x53, &"SRE", 2, 8, shift_right_memory_then_exclusive_or_register, register_a.name, AddressingMode.Indirect_Y),
		# RRA
		OpCode.new(0x67, &"RRA", 2, 5, rotate_right_memory_then_add_to_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x77, &"RRA", 2, 6, rotate_right_memory_then_add_to_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x6F, &"RRA", 3, 6, rotate_right_memory_then_add_to_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x7F, &"RRA", 3, 7, rotate_right_memory_then_add_to_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x7B, &"RRA", 3, 7, rotate_right_memory_then_add_to_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x63, &"RRA", 2, 8, rotate_right_memory_then_add_to_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x73, &"RRA", 2, 8, rotate_right_memory_then_add_to_register, register_a.name, AddressingMode.Indirect_Y),
		# ANC
		OpCode.new(0x0B, &"ANC", 2, 2, bitwise_and_with_register_with_carry, register_a.name, AddressingMode.Immediate),
		OpCode.new(0x2B, &"ANC", 2, 2, bitwise_and_with_register_with_carry, register_a.name, AddressingMode.Immediate),
		# ARR
		OpCode.new(0x6B, &"ARR", 2, 2, bitwise_and_then_rotate_register_with_cv_flags, register_a.name, AddressingMode.Immediate),
		# ASR
		OpCode.new(0x4B, &"ASR", 2, 2, bitwise_and_then_shift_register, register_a.name, AddressingMode.Immediate),
		# ATX
		OpCode.new(0xAB, &"LXA", 2, 2, bitwise_and_with_register_then_transfer_to_register.bind(register_a, register_x), StringName(), AddressingMode.Immediate),
		# KIL
		OpCode.new(0x02, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x12, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x22, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x32, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x42, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x52, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x62, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x72, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0x92, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0xB2, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0xD2, &"KIL", 1, 0, no_operation, StringName(), -1),
		OpCode.new(0xF2, &"KIL", 1, 0, no_operation, StringName(), -1),
		# LAS
		OpCode.new(0xBB, &"LAS", 3, 4, bitwise_and_memory_with_stack_then_load_registers.bind([register_a, register_x]), StringName(), AddressingMode.Absolute_Y),
		# AXS
		OpCode.new(0xCB, &"AXS", 2, 2, bitwise_and_registers_then_substract.bind(register_a, register_x), StringName(), AddressingMode.Immediate),
		# SHX
		OpCode.new(0x9E, &"AXS", 3, 5, bitwise_and_high_addr_byte_with_register, register_x.name, AddressingMode.Absolute_Y),
		# SYA
		OpCode.new(0x9E, &"SYA", 3, 5, bitwise_and_high_addr_byte_with_register, register_y.name, AddressingMode.Absolute_X),
		# TAS
		OpCode.new(0x9B, &"TAS", 3, 5, bitwise_and_two_register_to_stack_then_and_with_high_byte_to_memory.bind(register_x, register_a), StringName(), AddressingMode.Absolute_X),
	]
	
	for instruction in instructions:
		instruction.set_meta(&"is_ilegal", true)
		instructionset[instruction.code] = instruction
		var bind_args: Array = []
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


func _on_interrupt_triggered(p_interrupt_jump_addres: int, p_break_flag: bool):
	assert(p_interrupt_jump_addres in [0xFFFA, 0xFFFE])
	stack_push_16(program_counter.value)
	var aux_flag := NesRegisterFlags.new(&"P")
	aux_flag.value = flags.value
	aux_flag.B.value = p_break_flag
	aux_flag.B2.value = true

	stack_push_8(aux_flag.value)
	flags.I.value = true

	memory.tick(2)
	program_counter.value = memory.mem_read_16(p_interrupt_jump_addres)


func _on_memory_advance_frame():
	_sleeping = true

var instruction_count = 0
func _about_to_execute_instruction():
	await super()
	instruction_count += 1
	if _sleeping:
		await Engine.get_main_loop().create_timer(0.02).timeout
#		await Engine.get_main_loop().process_frame
		_sleeping = false

# BRK
func nes_break():
	_on_interrupt_triggered(0xFFFE, true)


func ilegal_no_operation(p_addressing_mode: AddressingMode):
	var _addr = get_operand_address(p_addressing_mode)
	return 1 if did_operand_address_cross_page() else 0

func load_registers8(p_registers: Array, p_addressing_mode: AddressingMode):
	for register in p_registers:
		load_register8(register, p_addressing_mode)
	return 1 if did_operand_address_cross_page() else 0

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

func shift_right_memory_then_exclusive_or_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	logical_shift_right_memory(p_addressing_mode)
	exclusive_or_with_register(p_register, p_addressing_mode)

func rotate_left_memory_then_logic_and_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	rotate_left_memory(p_addressing_mode)
	bitwise_and_with_register(p_register, p_addressing_mode)

func rotate_right_memory_then_add_to_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	rotate_right_memory(p_addressing_mode)
	add_with_carry_to_register(p_register, p_addressing_mode)

func bitwise_and_with_register_with_carry(p_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_register, p_addressing_mode)
	if flags.N.value:
		flags.C.value = true

func bitwise_and_then_rotate_register_with_cv_flags(p_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_register, p_addressing_mode)
	rotate_right_register(p_register)
	var five: bool = 0b00010000
	var six : bool = 0b00100000
	if five == six and six == true:
		flags.C.value = true
		flags.V.value = false
	if five == six and six == false:
		flags.C.value = false
		flags.V.value = false
	if five and !six:
		flags.C.value = false
		flags.V.value = true
	if !five and six:
		flags.C.value = true
		flags.V.value = true

func bitwise_and_then_shift_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_register, p_addressing_mode)
	logical_shift_right_register(p_register)

func bitwise_and_with_register_then_transfer_to_register(p_and_register: Register8bits, p_transfer_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_and_register, p_addressing_mode)
	transfer_register_from_to(p_and_register, p_transfer_register)

func bitwise_and_memory_with_stack_then_load_registers(p_registers: Array[Register8bits], p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value & stack_pointer
	stack_pointer = result
	for reg in p_registers:
		reg.value = result
	update_z_n_flags(result)

func bitwise_and_registers_then_substract(p_and_register: Register8bits, p_load_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var to_substract: int = memory.mem_read(addr)
	var and_result: int = p_and_register.value & p_load_register.value
	if to_substract <= and_result:
		flags.C.value = true
	update_z_n_flags(and_result)
	p_load_register.value = and_result

func bitwise_and_high_addr_byte_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var high_byte: int = (addr >> 8) + 1
	if high_byte > 0xFF:
		high_byte -= 0x100
	var and_result: int = p_register.value & high_byte
	memory.mem_write(addr, and_result)

func bitwise_and_two_register_to_stack_then_and_with_high_byte_to_memory(p_reg_1: Register8bits, p_reg_2: Register8bits, p_addressing_mode: AddressingMode):
	stack_pointer = p_reg_1.value & p_reg_2.value
	var addr: int = get_operand_address(p_addressing_mode)
	var high_byte: int = (addr >> 8) + 1
	if high_byte > 0xFF:
		high_byte -= 0x100
	var and_result: int = high_byte & stack_pointer
	memory.mem_write(addr, and_result)
