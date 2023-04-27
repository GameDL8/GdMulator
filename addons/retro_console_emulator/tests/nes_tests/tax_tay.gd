extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xaa_tax_move_a_to_x()
	test_0xa8_tax_move_a_to_y()


func test_0xaa_tax_move_a_to_x():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 10, 0xaa, 0x00])
	assert(cpu.register_x.value == 10)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0b10000001, 0xaa, 0x00])
	assert(cpu.register_x.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0, 0xaa, 0x00])
	assert(cpu.register_x.value == 0)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xaa_tax_move_a_to_x PASSED!")


func test_0xa8_tax_move_a_to_y():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 10, 0xa8, 0x00])
	assert(cpu.register_y.value == 10)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0b10000001, 0xa8, 0x00])
	assert(cpu.register_y.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0, 0xa8, 0x00])
	assert(cpu.register_y.value == 0)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xa8_tax_move_a_to_y PASSED!")

