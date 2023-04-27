extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x90_bcc_relative_branch_if_carry_clear()
	test_0xB0_bcs_relative_branch_if_carry_set()


func test_0x90_bcc_relative_branch_if_carry_clear():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x03, 0x90, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x03)

func test_0xB0_bcs_relative_branch_if_carry_set():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0b10000001, 0x0a, 0xb0, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0b00000010)
