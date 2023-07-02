extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x48_pha_push_accumulator()


func test_0x48_pha_push_accumulator():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x05, 0x48, 0xa9, 0x75, 0x48, 0x00])
	var _pushed_procesor_flags: int = cpu.stack_pop_8()
	var _pushed_program_counter: int = cpu.stack_pop_16()
	assert(cpu.stack_pop_8() == 0x75)
	assert(cpu.stack_pop_8() == 0x05)
	print("test_0x48_pha_push_accumulator PASSED!")
