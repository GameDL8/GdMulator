extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x09_ora_immediate_logical_inclusive_or()
	test_0x05_ora_zeropage_logical_inclusive_or()
	test_0x15_ora_zeropage_x_logical_inclusive_or()
	test_0x0d_ora_absolute_logical_inclusive_or()
	test_0x1d_ora_absolute_x_logical_inclusive_or()
	test_0x19_ora_absolute_y_logical_inclusive_or()
	test_0x01_ora_indirect_x_logical_inclusive_or()
	test_0x11_ora_indirect_y_logical_inclusive_or()


func test_0x09_ora_immediate_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0b11011001, 0x09, 0b00100110, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0b00000000, 0x09, 0b00000000, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x09_ora_immediate_logical_inclusive_or PASSED!")


func test_0x05_ora_zeropage_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03, 0b00100110)
	cpu.memory.mem_write(0x04, 0b00000000)
	cpu.load_and_run([0xa9, 0b11011001, 0x05, 0x03, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0b00000000, 0x05, 0x04, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x05_ora_zeropage_logical_inclusive_or PASSED!")



func test_0x15_ora_zeropage_x_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03+5, 0b00100110)
	cpu.memory.mem_write(0x04+5, 0b00000000)
	cpu.load_and_run([0xa2, 0x05, 0xa9, 0b11011001, 0x15, 0x03, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa2, 0x05, 0xa9, 0b00000000, 0x15, 0x04, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x15_ora_zeropage_x_logical_inclusive_or PASSED!")


func test_0x0d_ora_absolute_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003, 0b00100110)
	cpu.memory.mem_write(0x4004, 0b00000000)
	cpu.load_and_run([0xa9, 0b11011001, 0x0d, 0x03, 0x40, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0b00000000, 0x0d, 0x04, 0x40, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x0d_ora_absolute_logical_inclusive_or PASSED!")


func test_0x1d_ora_absolute_x_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003+0xf1, 0b00100110)
	cpu.memory.mem_write(0x4004+0xf1, 0b00000000)
	cpu.load_and_run([0xa2, 0xf1, 0xa9, 0b11011001, 0x1d, 0x03, 0x40, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa2, 0xf1, 0xa9, 0b00000000, 0x1d, 0x04, 0x40, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x1d_ora_absolute_x_logical_inclusive_or PASSED!")


func test_0x19_ora_absolute_y_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4003+0xea, 0b00100110)
	cpu.memory.mem_write(0x4004+0xea, 0b00000000)
	cpu.load_and_run([0xa0, 0xea, 0xa9, 0b11011001, 0x19, 0x03, 0x40, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa0, 0xea, 0xa9, 0b00000000, 0x19, 0x04, 0x40, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x19_ora_absolute_y_logical_inclusive_or PASSED!")


func test_0x01_ora_indirect_x_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03+5, 0x03)
	cpu.memory.mem_write(0x04+5, 0x40)
	cpu.memory.mem_write(0x05+5, 0x04)
	cpu.memory.mem_write(0x06+5, 0x40)
	cpu.memory.mem_write(0x4003, 0b00100110)
	cpu.memory.mem_write(0x4004, 0b00000000)
	cpu.load_and_run([0xa2, 0x05, 0xa9, 0b11011001, 0x01, 0x03, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa2, 0x05, 0xa9, 0b00000000, 0x01, 0x05, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x01_ora_indirect_x_logical_inclusive_or PASSED!")


func test_0x11_ora_indirect_y_logical_inclusive_or():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x03, 0x03)
	cpu.memory.mem_write(0x04, 0x40)
	cpu.memory.mem_write(0x05, 0x04)
	cpu.memory.mem_write(0x06, 0x40)
	cpu.memory.mem_write(0x4003+5, 0b00100110)
	cpu.memory.mem_write(0x4004+5, 0b00000000)
	cpu.load_and_run([0xa0, 0x05, 0xa9, 0b11011001, 0x11, 0x03, 0x00])
	assert(cpu.register_a.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa0, 0x05, 0xa9, 0b00000000, 0x11, 0x05, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x11_ora_indirect_y_logical_inclusive_or PASSED!")


