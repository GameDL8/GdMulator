extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xc9_cmp_immediate_compare_register_a()
	test_0xc5_cmp_zeropage_compare_register_a()
	test_0xd5_cmp_zeropage_x_compare_register_a()
	test_0xcd_cmp_absolute_compare_register_a()
	test_0xdd_cmp_absolute_x_compare_register_a()
	test_0xd9_cmp_absolute_y_compare_register_a()
	test_0xc1_cmp_indirect_x_compare_register_a()
	test_0xd1_cmp_indirect_y_compare_register_a()


func test_0xc9_cmp_immediate_compare_register_a():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x03, 0xc9, 0x02, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xc9, 0x03, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xc9, 0x04, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0xc9_cmp_immediate_compare_register_a PASSED!")


func test_0xc5_cmp_zeropage_compare_register_a():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x01, 0x03)
	cpu.load_and_run([0xa9, 0x02, 0xc5, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xc5, 0x01, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xc5, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xc5_cmp_zeropage_compare_register_a PASSED!")


func test_0xd5_cmp_zeropage_x_compare_register_a():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x05, 0x03)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x02, 0xd5, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x03, 0xd5, 0x01, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x04, 0xd5, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xd5_cmp_zeropage_x_compare_register_a PASSED!")


func test_0xcd_cmp_absolute_compare_register_a():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x4005, 0x03)
	cpu.load_and_run([0xa9, 0x02, 0xcd, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xcd, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xcd, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xcd_cmp_absolute_compare_register_a PASSED!")


func test_0xdd_cmp_absolute_x_compare_register_a():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x4005, 0x03)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x02, 0xdd, 0x01, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x03, 0xdd, 0x01, 0x40, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x04, 0xdd, 0x01, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xdd_cmp_absolute_x_compare_register_a PASSED!")


func test_0xd9_cmp_absolute_y_compare_register_a():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x4005, 0x03)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xa9, 0x02, 0xd9, 0x01, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xa9, 0x03, 0xd9, 0x01, 0x40, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xa9, 0x04, 0xd9, 0x01, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xd9_cmp_absolute_y_compare_register_a PASSED!")


func test_0xc1_cmp_indirect_x_compare_register_a():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x05, 0x03)
	cpu.memory.mem_write(0x06, 0x40)
	cpu.memory.mem_write(0x4003, 0x03)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x02, 0xc1, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x03, 0xc1, 0x01, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xa9, 0x04, 0xc1, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xc1_cmp_indirect_x_compare_register_a PASSED!")


func test_0xd1_cmp_indirect_y_compare_register_a():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x01, 0x03)
	cpu.memory.mem_write(0x02, 0x40)
	cpu.memory.mem_write(0x4007, 0x03)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xa9, 0x02, 0xd1, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xa9, 0x03, 0xd1, 0x01, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xa8, 0xa9, 0x04, 0xd1, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xd1_cmp_indirect_y_compare_register_a PASSED!")


