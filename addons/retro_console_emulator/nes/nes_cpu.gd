class_name NesCPU extends CPU6502


func _init() -> void:
	super()
	
	#register instructions
	var instructions: Array[OpCode] = [
		# DOP: Double NOP
		OpCode.new(0x04, &"NOP", 2, 3, double_no_operation, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x44, &"NOP", 2, 3, double_no_operation, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x64, &"NOP", 2, 3, double_no_operation, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x14, &"NOP", 2, 4, double_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x34, &"NOP", 2, 4, double_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x54, &"NOP", 2, 4, double_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x74, &"NOP", 2, 4, double_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0xD4, &"NOP", 2, 4, double_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0xF4, &"NOP", 2, 4, double_no_operation, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x80, &"NOP", 2, 2, double_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x82, &"NOP", 2, 2, double_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0x89, &"NOP", 2, 2, double_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0xC2, &"NOP", 2, 2, double_no_operation, StringName(), AddressingMode.Immediate),
		OpCode.new(0xE2, &"NOP", 2, 2, double_no_operation, StringName(), AddressingMode.Immediate),
		# TOP: Triple NOP
		OpCode.new(0x0C, &"TOP", 3, 4, triple_no_operation, StringName(), AddressingMode.Absolute),
		OpCode.new(0x1C, &"TOP", 3, 4, triple_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0x3C, &"TOP", 3, 4, triple_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0x5C, &"TOP", 3, 4, triple_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0x7C, &"TOP", 3, 4, triple_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0xDC, &"TOP", 3, 4, triple_no_operation, StringName(), AddressingMode.Absolute_X),
		OpCode.new(0xFC, &"TOP", 3, 4, triple_no_operation, StringName(), AddressingMode.Absolute_X),
		
	]
	
	for instruction in instructions:
		instruction.set_meta(&"is_ilegal", true)
		instructionset[instruction.code] = instruction
		var bind_args: Array
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

func double_no_operation(_ignored_addresing_mode: AddressingMode):
	pass

func triple_no_operation(_ignored_addresing_mode: AddressingMode):
	pass
