extends "res://addons/retro_console_emulator/tests/base_test.gd"

func test():
	test_0x8a_txa_move_x_to_a()
	test_0x98_tya_move_y_to_a()


func test_0x8a_txa_move_x_to_a():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa2, 10, 0x8a, 0x00])
	assert(cpu.register_a.value == 10)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa2, 0b10000001, 0x8a, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa2, 0, 0x8a, 0x00])
	assert(cpu.register_a.value == 0)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x8a_txa_move_x_to_a PASSED!")


func test_0x98_tya_move_y_to_a():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa0, 10, 0x98, 0x00])
	assert(cpu.register_a.value == 10)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa0, 0b10000001, 0x98, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa0, 0, 0x98, 0x00])
	assert(cpu.register_a.value == 0)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0x98_tya_move_y_to_a PASSED!")
