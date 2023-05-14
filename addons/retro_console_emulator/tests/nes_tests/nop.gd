extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xea_nop_no_operation()


func test_0xea_nop_no_operation():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0b00000001, 0xea, 0xea, 0x4a, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xea_nop_no_operation PASSED!")
