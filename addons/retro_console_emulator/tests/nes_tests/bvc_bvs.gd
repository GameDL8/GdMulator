extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0x50_bvc_relative_branch_if_overflow_clear()
	test_0x70_bvs_relative_branch_if_overflow_set()

func test_0x50_bvc_relative_branch_if_overflow_clear():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x02, 0b11111111)
	cpu.load_and_run([
		0xa9, 0x10,       # LDA $0x10
		0x24, 0x02      , # BIT $0x02 ; V is set
		0x50, 0x02,       # BVC #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0x05)
	cpu.memory.mem_write(0x02, 0b10000000)
	cpu.load_and_run([
		0xa9, 0x10,       # LDA $0x10
		0x24, 0x02,       # BIT $0x02 ; V is clear
		0x50, 0x02,       # BVC #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0x10)
	print("test_0x50_bvc_relative_branch_if_overflow_clear PASSED!")

func test_0x70_bvs_relative_branch_if_overflow_set():
	var cpu = CPU6502.new()
	cpu.memory.mem_write(0x02, 0b11111111)
	cpu.load_and_run([
		0xa9, 0x10,       # LDA $0x10
		0x24, 0x02      , # BIT $0x02 ; V is set
		0x70, 0x02,       # BVS #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0x10)
	cpu.memory.mem_write(0x02, 0b10000000)
	cpu.load_and_run([
		0xa9, 0x10,       # LDA $0x10
		0x24, 0x02,       # BIT $0x02 ; V is clear
		0x70, 0x02,       # BVS #$0x02
		0xa9, 0x05,       # LDA #$0x05
		0xaa,             # TAX
		0x00])
	assert(cpu.register_x.value == 0x05)
	print("test_0x70_bvs_relative_branch_if_overflow_set PASSED!")

