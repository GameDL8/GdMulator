extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xc0_cpy_immediate_compare_register_y()
	test_0xc4_cpy_zeropage_compare_register_y()
	test_0xcc_cpy_absolute_compare_register_y()


func test_0xc0_cpy_immediate_compare_register_y():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x03, 0xa8, 0xc0, 0x02, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xa8, 0xc0, 0x03, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xa8, 0xc0, 0x04, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0xc0_cpy_immediate_compare_register_y PASSED!")


func test_0xc4_cpy_zeropage_compare_register_y():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x01, 0x03)
	cpu.load_and_run([0xa9, 0x02, 0xa8, 0xc4, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xa8, 0xc4, 0x01, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xc4, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xc4_cpy_zeropage_compare_register_y PASSED!")


func test_0xcc_cpy_absolute_compare_register_y():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4005, 0x03)
	cpu.load_and_run([0xa9, 0x02, 0xa8, 0xcc, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xa8, 0xcc, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xcc, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xcc_cpy_absolute_compare_register_y PASSED!")

