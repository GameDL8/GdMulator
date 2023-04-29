extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	push_warning("Uncomment code when BVC and BVS OpCodes are implemented")
#	test_0x50_bvc_relative_branch_if_overflow_clear()
#	test_0x70_bvs_relative_branch_if_overflow_set()

func test_0x50_bvc_relative_branch_if_overflow_clear():
	var cpu = NesCPU.new()
	cpu.load_and_run([
		0xa9, 0b11111111, # LDA 0b11111111
		0x24, 0b11000000, # BIT 0b11000000 ; V is set
		0x50, 0x02,       # BVC #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0x05)
	cpu.load_and_run([
		0xa9, 0b11111111, # LDA 0b11111111
		0x24, 0b10000000, # BIT 0b11000000 ; V is clear
		0x50, 0x02,       # BVC #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0b11111111)
	print("test_0x50_bvc_relative_branch_if_overflow_clear PASSED!")

func test_0x70_bvs_relative_branch_if_overflow_set():
	var cpu = NesCPU.new()
	cpu.load_and_run([
		0xa9, 0b11111111, # LDA 0b11111111
		0x24, 0b11000000, # BIT 0b11000000 ; V is set
		0x70, 0x02,       # BVS #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0b11111111)
	cpu.load_and_run([
		0xa9, 0b11111111, # LDA 0b11111111
		0x24, 0b10000000, # BIT 0b11000000 ; V is clear
		0x70, 0x02,       # BVS #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0x05)
	print("test_0x70_bvs_relative_branch_if_overflow_set PASSED!")

