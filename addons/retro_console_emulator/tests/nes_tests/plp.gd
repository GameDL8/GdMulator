extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x28_plp_pull_procesor()


func test_0x28_plp_pull_procesor():
	var cpu = NesCPU.new()
	cpu.load_and_run([
		0xa9, 0b00000000, 
		0x38,             # P == 0b00000011
		0x08,
		0xa9, 0b10000000,
		0x78,             # P == 0b10000101
		0x28,
		0x00])
	assert(cpu.flags.value == 0b00000011)
	print("test_0x28_plp_pull_procesor PASSED!")
