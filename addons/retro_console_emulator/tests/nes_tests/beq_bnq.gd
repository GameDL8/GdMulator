extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xf0_beq_relative_branch_if_zero_set()
	test_0xd0_bne_relative_branch_if_zero_clear()


func test_0xf0_beq_relative_branch_if_zero_set():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x03, 0xf0, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x05)
	cpu.load_and_run([0xa9, 0x00, 0xf0, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x00)
	print("test_0xf0_beq_relative_branch_if_zero_set PASSED!")


func test_0xd0_bne_relative_branch_if_zero_clear():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x03, 0xd0, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x03)
	cpu.load_and_run([0xa9, 0x00, 0xd0, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x05)
	print("test_0xd0_bne_relative_branch_if_zero_clear PASSED!")

