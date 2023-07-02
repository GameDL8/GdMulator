class_name NesCPU extends CPU6502


func _init() -> void:
	super()
	
	#register instructions
	var instructions: Array[OpCode] = [
		OpCode.new(0x04, &"NOP", 2, 3, store_from_register, register_y.name, AddressingMode.ZeroPage),
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
