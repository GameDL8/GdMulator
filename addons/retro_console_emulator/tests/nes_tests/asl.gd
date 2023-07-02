extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x0a_asl_accumulator_arithmetic_shift_left()
	test_0x06_asl_zeropage_arithmetic_shift_left()
	test_0x16_asl_zeropage_x_arithmetic_shift_left()
	test_0x0e_asl_absolute_arithmetic_shift_left()
	test_0x1e_asl_absolute_x_arithmetic_shift_left()


func test_0x0a_asl_accumulator_arithmetic_shift_left():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0b10000000, 0x0a, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0b01000000, 0x0a, 0x00])
	assert(cpu.register_a.value == 0b10000000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0x0a_asl_accumulator_arithmetic_shift_left passed!")


func test_0x06_asl_zeropage_arithmetic_shift_left():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x00, 0b10000000)
	cpu.memory.mem_write(0x01, 0b01000000)
	cpu.load_and_run([0x06, 0x00, 0x00])
	assert(cpu.memory.mem_read(0x00)  == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0x06, 0x01, 0x00])
	assert(cpu.memory.mem_read(0x01) == 0b10000000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0x06_asl_zeropage_arithmetic_shift_left PASSED!")


func test_0x16_asl_zeropage_x_arithmetic_shift_left():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x05, 0b10000000)
	cpu.memory.mem_write(0x06, 0b01000000)
	cpu.load_and_run([0xa9, 0x05, 0xaa, 0x16, 0x00, 0x00])
	assert(cpu.memory.mem_read(0x05)  == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x05, 0xaa, 0x16, 0x01, 0x00])
	assert(cpu.memory.mem_read(0x06) == 0b10000000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0x16_asl_zeropage_x_arithmetic_shift_left PASSED!")


func test_0x0e_asl_absolute_arithmetic_shift_left():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4005, 0b10000000)
	cpu.memory.mem_write(0x4006, 0b01000000)
	cpu.load_and_run([0x0e, 0x05, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4005)  == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0x0e, 0x06, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4006) == 0b10000000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0x0e_asl_absolute_arithmetic_shift_left passed!")


func test_0x1e_asl_absolute_x_arithmetic_shift_left():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4005, 0b10000000)
	cpu.memory.mem_write(0x4006, 0b01000000)
	cpu.load_and_run([0xa9, 0x05, 0xaa, 0x1e, 0x00, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4005)  == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x05, 0xaa, 0x1e, 0x01, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4006) == 0b10000000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0x1e_asl_absolute_x_arithmetic_shift_left passed!")
