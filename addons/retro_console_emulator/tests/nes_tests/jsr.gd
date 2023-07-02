extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x20_jsr_absolute_jump_to_subroutine()


func test_0x20_jsr_absolute_jump_to_subroutine():
	var cpu = CPU6502.new()
	cpu.load_and_run([
		0x20, 0x0a, 0x80, # JSR #$0x800A
		0xa9, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00,
		0xa9, 0x05,
		0x00
	])
	assert(cpu.register_a.value == 0x05)
	var _pushed_procesor_flags: int = cpu.stack_pop_8()
	var _pushed_program_counter: int = cpu.stack_pop_16()
	assert(cpu.stack_pop_16() == 0x8002)
	print("test_0x20_jsr_absolute_jump_to_subroutine PASSED!")
