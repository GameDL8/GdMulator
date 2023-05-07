extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x__CLASS__immediate_()
	test_0x__CLASS__zeropage_()
	test_0x__CLASS__zeropage_x_()
	test_0x__CLASS__absolute_()
	test_0x__CLASS__absolute_x_()
	test_0x__CLASS__absolute_y_()
	test_0x__CLASS__indirect_x_()
	test_0x__CLASS__indirect_y_()


func test_0x__CLASS__immediate_():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x03, 0x09)
	cpu.memory.mem_write(0x4003+3, 0x09)
	cpu.load_and_run([0xa9, 0x05, 0x00])
	assert(cpu.register_a.value == 0x05)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	assert(cpu.flags.V.value == false)
	assert(cpu.flags.C.value == false)
	print("test_0x__CLASS__immediate_ PASSED!")


func test_0x__CLASS__zeropage_():
	pass


func test_0x__CLASS__zeropage_x_():
	pass


func test_0x__CLASS__absolute_():
	pass


func test_0x__CLASS__absolute_x_():
	pass


func test_0x__CLASS__absolute_y_():
	pass


func test_0x__CLASS__indirect_x_():
	pass


func test_0x__CLASS__indirect_y_():
	pass

