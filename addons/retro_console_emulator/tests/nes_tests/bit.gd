extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	push_warning("Uncomment code when BIT OpCode is implemented")
#	test_0x24_bit_zeropage_bit_test()
#	test_0x2c_bit_absolute_bit_test()


func test_0x24_bit_zeropage_bit_test():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x05, 0b10000110)
	cpu.load_and_run([0xa9, 0b11000111, 0x24, 0x05, 0x00])
	assert(cpu.flags.Z == false)
	assert(cpu.flags.M == true)
	assert(cpu.flags.V == true)
	cpu.load_and_run([0xa9, 0b10000110, 0x24, 0x05, 0x00])
	assert(cpu.flags.Z == true)
	assert(cpu.flags.M == true)
	assert(cpu.flags.V == false)
	print("test_0x24_bit_zeropage_bit_test PASSED!")


func test_0x2c_bit_absolute_bit_test():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x4005, 0b10000110)
	cpu.load_and_run([0xa9, 0b11000111, 0x2c, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z == false)
	assert(cpu.flags.M == true)
	assert(cpu.flags.V == true)
	cpu.load_and_run([0xa9, 0b10000110, 0x2c, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z == true)
	assert(cpu.flags.M == true)
	assert(cpu.flags.V == false)
	print("test_0x2c_bit_absolute_bit_test PASSED!")

