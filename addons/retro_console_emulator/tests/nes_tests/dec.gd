extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xc6_dec_zeropage_decrease_memory_value()
	test_0xd6_dec_zeropage_x_decrease_memory_value()
	test_0xce_dec_absolute_decrease_memory_value()
	test_0xde_dec_absolute_x_decrease_memory_value()


func test_0xc6_dec_zeropage_decrease_memory_value():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x03, 0xA0)
	cpu.memory.mem_write(0x04, 0x00)
	cpu.memory.mem_write(0x05, 0x02)
	cpu.memory.mem_write(0x06, 0b10000000)
	cpu.load_and_run([0xc6, 0x03, 0x00])
	assert(cpu.memory.mem_read(0x03) == 0x9F)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xc6, 0x04, 0x00])
	assert(cpu.memory.mem_read(0x04) == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xc6, 0x05, 0xc6, 0x05, 0x00])
	assert(cpu.memory.mem_read(0x05) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xc6, 0x06, 0x00])
	assert(cpu.memory.mem_read(0x06) ==  0b01111111)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	print("test_0xc6_dec_zeropage_decrease_memory_value PASSED!")


func test_0xd6_dec_zeropage_x_decrease_memory_value():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x03+3, 0xA0)
	cpu.memory.mem_write(0x04+3, 0x00)
	cpu.memory.mem_write(0x05+3, 0x02)
	cpu.memory.mem_write(0x06+3, 0b10000000)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xd6, 0x03, 0x00])
	assert(cpu.memory.mem_read(0x03+3) == 0x9F)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xd6, 0x04, 0x00])
	assert(cpu.memory.mem_read(0x04+3) == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xd6, 0x05, 0xd6, 0x05, 0x00])
	assert(cpu.memory.mem_read(0x05+3) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xd6, 0x06, 0x00])
	assert(cpu.memory.mem_read(0x06+3) ==  0b01111111)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	print("test_0xd6_dec_zeropage_x_decrease_memory_value PASSED!")


func test_0xce_dec_absolute_decrease_memory_value():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x4003, 0xA0)
	cpu.memory.mem_write(0x4004, 0x00)
	cpu.memory.mem_write(0x4005, 0x02)
	cpu.memory.mem_write(0x4006, 0b10000000)
	cpu.load_and_run([0xce, 0x03, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4003) == 0x9F)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xce, 0x04, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4004) == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xce, 0x05, 0x40, 0xce, 0x05, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4005) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xce, 0x06, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4006) ==  0b01111111)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	print("test_0xce_dec_absolute_decrease_memory_value PASSED!")


func test_0xde_dec_absolute_x_decrease_memory_value():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x4003+3, 0xA0)
	cpu.memory.mem_write(0x4004+3, 0x00)
	cpu.memory.mem_write(0x4005+3, 0x02)
	cpu.memory.mem_write(0x4006+3, 0b10000000)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xde, 0x03, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4003+3) == 0x9F)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xde, 0x04, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4004+3) == 0xFF)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xde, 0x05, 0x40, 0xde, 0x05, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4005+3) == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xde, 0x06, 0x40, 0x00])
	assert(cpu.memory.mem_read(0x4006+3) ==  0b01111111)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	print("test_0xde_dec_absolute_x_decrease_memory_value PASSED!")
