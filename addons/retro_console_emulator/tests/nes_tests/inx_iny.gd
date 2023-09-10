extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xe8_inx_increase_register_x()
	test_0xc8_iny_increase_register_y()
	
	
func test_0xe8_inx_increase_register_x():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x0A, 0xaa, 0xe8, 0x00])
	assert(cpu.register_x.value == 0x0B)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0xFF, 0xaa, 0xe8, 0x00])
	assert(cpu.register_x.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0xFE, 0xaa, 0xe8, 0x00])
	assert(cpu.register_x.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0xe8_inx_increase_register_x PASSED!")


func test_0xc8_iny_increase_register_y():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x0A, 0xa8, 0xc8, 0x00])
	assert(cpu.register_y.value == 0x0B)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0xFF, 0xa8, 0xc8, 0x00])
	assert(cpu.register_y.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0xFE, 0xa8, 0xc8, 0x00])
	assert(cpu.register_y.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0xc8_iny_increase_register_y PASSED!")

