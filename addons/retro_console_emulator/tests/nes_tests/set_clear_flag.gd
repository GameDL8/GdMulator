extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x38_0xF8_0x78_set_flag()
	test_0x18_0xD8_0x58_0xB8_clear_flag()


func test_0x38_0xF8_0x78_set_flag():
	var cpu = CPU6502.new()
	cpu.load_and_run([0x38, 0xF8, 0x78, 0x00])
	assert(cpu.flags.C.value == true)
	assert(cpu.flags.D.value == true)
	assert(cpu.flags.I.value == true)
	print("test_0x38_0xF8_0x78_set_flag PASSED!")


func test_0x18_0xD8_0x58_0xB8_clear_flag():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x05, 0b11000110)
	cpu.load_and_run([0x24, 0x05, 0x38, 0xF8, 0x78, 0x18, 0xD8, 0x58, 0xB8, 0x00])
	assert(cpu.flags.C.value == false)
	assert(cpu.flags.D.value == false)
	assert(cpu.flags.I.value == false)
	assert(cpu.flags.V.value == false)
	print("test_0x18_0xD8_0x58_0xB8_clear_flag PASSED!")

