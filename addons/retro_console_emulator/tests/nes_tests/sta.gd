extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x85_sta_zeropage_store_data()
	test_0x8d_sta_absolute_store_data()
	test_0x95_sta_zeropage_x_store_data()
	test_0x9d_sta_absolute_x_store_data()
	test_0x99_sta_absolute_y_store_data()
	test_0x81_sta_indirect_x_store_data()
	test_0x91_sta_indirect_y_store_data()


func test_0x85_sta_zeropage_store_data():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x05, 0x85, 0x10, 0x00])
	assert(cpu.memory.mem_read(0x10) == 0x05)
	print("test_0x85_sta_zeropage_store_data PASSED!")


func test_0x8d_sta_absolute_store_data():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x05, 0x8d, 0x12, 0x10, 0x00])
	assert(cpu.memory.mem_read(0x1012) == 0x05)
	print("test_0x8d_sta_absolute_store_data PASSED!")


func test_0x95_sta_zeropage_x_store_data():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x05, 0xaa, 0x95, 0x12, 0x00])
	assert(cpu.memory.mem_read(0x17) == 0x05)
	print("test_0x95_sta_zeropage_x_store_data PASSED!")


func test_0x9d_sta_absolute_x_store_data():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x05, 0xaa, 0x9d, 0x12, 0x10, 0x00])
	assert(cpu.memory.mem_read(0x1017) == 0x05)
	print("test_0x9d_sta_absolute_x_store_data PASSED!")


func test_0x99_sta_absolute_y_store_data():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x05, 0xa8, 0x99, 0x12, 0x10, 0x00])
	assert(cpu.memory.mem_read(0x1017) == 0x05)
	print("test_0x99_sta_absolute_y_store_data PASSED!")


func test_0x81_sta_indirect_x_store_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x10, 0x03)
	cpu.memory.mem_write(0x11, 0x40)
	cpu.load_and_run([0xa9, 0x05, 0xaa, 0x81, 0x0B, 0x00])
	assert(cpu.memory.mem_read(0x4003) == 0x05)
	print("test_0x81_sta_indirect_x_store_data PASSED!")


func test_0x91_sta_indirect_y_store_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x10, 0x03)
	cpu.memory.mem_write(0x11, 0x40)
	cpu.load_and_run([0xa9, 0x05, 0xa8, 0x91, 0x10, 0x00])
	assert(cpu.memory.mem_read(0x4008) == 0x05)
	print("test_0x91_sta_indirect_y_store_data PASSED!")

