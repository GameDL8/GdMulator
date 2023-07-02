extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x68_pla_pull_accumulator()


func test_0x68_pla_pull_accumulator():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0xF5, 0x48, 0xa9, 0x75, 0x68, 0x00])
	assert(cpu.register_a.value == 0xF5)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.Z.value == false)
	print("test_0x68_pla_pull_accumulator PASSED!")
