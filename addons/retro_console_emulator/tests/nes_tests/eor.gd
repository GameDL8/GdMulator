extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x49_eor_immediate_exclusive_or_with_register_a()
	test_0x45_eor_zeropage_exclusive_or_with_register_a()
	test_0x55_eor_zeropage_x_exclusive_or_with_register_a()
	test_0x4d_eor_absolute_exclusive_or_with_register_a()
	test_0x5d_eor_absolute_x_exclusive_or_with_register_a()
	test_0x59_eor_absolute_y_exclusive_or_with_register_a()
	test_0x41_eor_indirect_x_exclusive_or_with_register_a()
	test_0x51_eor_indirect_y_exclusive_or_with_register_a()


func test_0x49_eor_immediate_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0b10001001, 0x49, 0b00000101, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x49_eor_immediate_exclusive_or_with_register_a PASSED!")


func test_0x45_eor_zeropage_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03, 0b00000101)
	cpu.load_and_run([0xa9, 0b10001001, 0x45, 0x03, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x45_eor_zeropage_exclusive_or_with_register_a PASSED!")


func test_0x55_eor_zeropage_x_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03+3, 0b00000101)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xa9, 0b10001001, 0x55, 0x03, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x55_eor_zeropage_x_exclusive_or_with_register_a PASSED!")


func test_0x4d_eor_absolute_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003, 0b00000101)
	cpu.load_and_run([0xa9, 0b10001001, 0x4d, 0x03, 0x40, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x4d_eor_absolute_exclusive_or_with_register_a PASSED!")


func test_0x5d_eor_absolute_x_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003+3, 0b00000101)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xa9, 0b10001001, 0x5d, 0x03, 0x40, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x5d_eor_absolute_x_exclusive_or_with_register_a PASSED!")


func test_0x59_eor_absolute_y_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003+3, 0b00000101)
	cpu.load_and_run([0xa9, 0x03, 0xa8, 0xa9, 0b10001001, 0x59, 0x03, 0x40, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x59_eor_absolute_y_exclusive_or_with_register_a PASSED!")


func test_0x41_eor_indirect_x_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03+3, 0x05)
	cpu.memory.mem_write(0x04+3, 0x40)
	cpu.memory.mem_write(0x4005, 0b00000101)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xa9, 0b10001001, 0x41, 0x03, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x41_eor_indirect_x_exclusive_or_with_register_a PASSED!")


func test_0x51_eor_indirect_y_exclusive_or_with_register_a():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03, 0x05)
	cpu.memory.mem_write(0x04, 0x40)
	cpu.memory.mem_write(0x4005+3, 0b00000101)
	cpu.load_and_run([0xa9, 0x03, 0xa8, 0xa9, 0b10001001, 0x51, 0x03, 0x00])
	assert(cpu.register_a.value == 0b10001100)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x51_eor_indirect_y_exclusive_or_with_register_a PASSED!")


