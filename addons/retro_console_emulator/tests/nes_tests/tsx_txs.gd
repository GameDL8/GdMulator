extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xba_tsx_immediate_transfer_stack_pointer_to_x()
	test_0x9a_txs_immediate_transfer_x_to_stack_pointer()


func test_0xba_tsx_immediate_transfer_stack_pointer_to_x():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x05, 0x48, 0xba, 0x00])
	assert(cpu.register_x.value == cpu.stack_pointer)
	assert(cpu.stack_pop_8() == 0x05)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0b10010000, 0x48, 0xba, 0x00])
	assert(cpu.register_x.value == cpu.stack_pointer)
	assert(cpu.stack_pop_8() == 0b10010000)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa2, 0x33, 0xa9, 0x00, 0x48, 0xba, 0x00])
	assert(cpu.register_x.value == cpu.stack_pointer)
	assert(cpu.stack_pop_8() == 0x00)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	print("test_0xba_tsx_immediate_transfer_stack_pointer_to_x PASSED!")


func test_0x9a_txs_immediate_transfer_x_to_stack_pointer():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa2, 0x05, 0x9a, 0x00])
	assert(cpu.register_x.value == cpu.stack_pointer)
	assert(cpu.stack_pointer == 0x05)
	cpu.load_and_run([0xa2, 0b10010000, 0x9a, 0x00])
	assert(cpu.register_x.value == cpu.stack_pointer)
	assert(cpu.stack_pointer == 0b10010000)
	cpu.load_and_run([0xa2, 0x00, 0x9a, 0x00])
	assert(cpu.register_x.value == cpu.stack_pointer)
	assert(cpu.stack_pointer == 0x00)
	print("test_0x9a_txs_immediate_transfer_x_to_stack_pointer PASSED!")
