extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x30_bmi_relative_branch_id_minus()
	test_0x10_bpl_relative_branch_if_positive()


func test_0x30_bmi_relative_branch_id_minus():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x04, 0x30, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x05)
	cpu.load_and_run([0xa9, 0b10100000, 0x30, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0b10100000)
	print("test_0x30_bmi_relative_branch_id_minus PASSED!")


func test_0x10_bpl_relative_branch_if_positive():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x04, 0x10, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x04)
	cpu.load_and_run([0xa9, 0b10100000, 0x10, 0x02, 0xa9, 0x05, 0xaa, 0x00])
	assert(cpu.register_x.value == 0x05)
	print("test_0x10_bpl_relative_branch_if_positive PASSED!")
