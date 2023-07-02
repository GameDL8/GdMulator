extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x4a_lsr_acumulator_logical_shift_right()
	test_0x46_lsr_zeropage_logical_shift_right()
	test_0x56_lsr_zeropage_x_logical_shift_right()
	test_0x4e_lsr_absolute_logical_shift_right()
	test_0x5e_lsr_absolute_x_logical_shift_right()


func test_0x4a_lsr_acumulator_logical_shift_right():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0b00000001, 0x4a, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0b10010000, 0x4a, 0x00])
	assert(cpu.register_a.value == 0b01001000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == false)
	print("test_0x4a_lsr_acumulator_logical_shift_right PASSED!")


func test_0x46_lsr_zeropage_logical_shift_right():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03, 0b00000001)
	cpu.memory.mem_write(0x04, 0b10010000)
	cpu.load_and_run([0x46, 0x03, 0x00])
	assert(cpu.memory.mem_read(0x03) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0x46, 0x04, 0x00])
	assert(cpu.memory.mem_read(0x04) == 0b01001000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == false)
	print("test_0x46_lsr_zeropage_logical_shift_right PASSED!")


func test_0x56_lsr_zeropage_x_logical_shift_right():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03+5, 0b00000001)
	cpu.memory.mem_write(0x04+5, 0b10010000)
	cpu.load_and_run([0xa2, 0x05, 0x56, 0x03, 0x00])
	assert(cpu.memory.mem_read(0x03+5) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa2, 0x05, 0x56, 0x04, 0x00])
	assert(cpu.memory.mem_read(0x04+5) == 0b01001000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == false)
	print("test_0x56_lsr_zeropage_x_logical_shift_right PASSED!")


func test_0x4e_lsr_absolute_logical_shift_right():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003, 0b00000001)
	cpu.memory.mem_write(0x4004, 0b10010000)
	cpu.load_and_run([0x4e, 0x03, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4003) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0x4e, 0x04, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4004) == 0b01001000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == false)
	print("test_0x4e_lsr_absolute_logical_shift_right PASSED!")


func test_0x5e_lsr_absolute_x_logical_shift_right():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003+5, 0b00000001)
	cpu.memory.mem_write(0x4004+5, 0b10010000)
	cpu.load_and_run([0xa2, 0x05, 0x5e, 0x03, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4003+5) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa2, 0x05, 0x5e, 0x04, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4004+5) == 0b01001000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == false)
	print("test_0x5e_lsr_absolute_x_logical_shift_right PASSED!")

