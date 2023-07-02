extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xe0_cpx_immediate_compare_register_x()
	test_0xe4_cpx_zeropage_compare_register_x()
	test_0xec_cpx_absolute_compare_register_x()


func test_0xe0_cpx_immediate_compare_register_x():
	var cpu = CPU6502.new()
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xe0, 0x02, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xe0, 0x03, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xe0, 0x04, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	print("test_0xe0_cpx_immediate_compare_register_x PASSED!")


func test_0xe4_cpx_zeropage_compare_register_x():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x01, 0x03)
	cpu.load_and_run([0xa9, 0x02, 0xaa, 0xe4, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xe4, 0x01, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xe4, 0x01, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xe4_cpx_zeropage_compare_register_x PASSED!")


func test_0xec_cpx_absolute_compare_register_x():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x4005, 0x03)
	cpu.load_and_run([0xa9, 0x02, 0xaa, 0xec, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	assert(cpu.flags.C.value == false)
	cpu.load_and_run([0xa9, 0x03, 0xaa, 0xec, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	cpu.load_and_run([0xa9, 0x04, 0xaa, 0xec, 0x05, 0x40, 0x00])
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.C.value == true)
	print("test_0xec_cpx_absolute_compare_register_x PASSED!")

