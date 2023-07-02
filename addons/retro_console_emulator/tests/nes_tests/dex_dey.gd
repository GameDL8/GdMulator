extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xca_dex_decrease_register_x()
	test_0x88_dex_decrease_register_y()
	
	
func test_0xca_dex_decrease_register_x():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x0A, 0xaa, 0xca, 0x00])
	assert(cpu.register_x.value == 0x09)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x01, 0xaa, 0xca, 0x00])
	assert(cpu.register_x.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x00, 0xaa, 0xca, 0x00])
	assert(cpu.register_x.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0xca_dex_decrease_register_x PASSED!")


func test_0x88_dex_decrease_register_y():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x0A, 0xa8, 0x88, 0x00])
	assert(cpu.register_y.value == 0x09)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x01, 0xa8, 0x88, 0x00])
	assert(cpu.register_y.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x00, 0xa8, 0x88, 0x00])
	assert(cpu.register_y.value == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0x88_dey_decrease_register_y PASSED!")

