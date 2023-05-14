extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x08_php_push_procesor()


func test_0x08_php_push_procesor():
	var cpu = NesCPU.new()
	cpu.load_and_run([
		0xa9, 0b00000000, 
		0x38,             # P == 0b00000011
		0x08,
		0xa9, 0b10000000,
		0x78,             # P == 0b10000101
		0x08,
		0x00])
	assert(cpu.stack_pop_8() == 0b10000101)
	assert(cpu.stack_pop_8() == 0b00000011)
	print("test_0x08_php_push_procesor PASSED!")
