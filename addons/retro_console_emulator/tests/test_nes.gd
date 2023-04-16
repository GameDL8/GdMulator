extends Node

func _ready() -> void:
	test_0xa9_lda_immediate_load_data()
	test_0xaa_tax_move_a_to_x()
	test_inx_overflow()
	test_5_ops_working_together()


func test_0xa9_lda_immediate_load_data():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0x05, 0x00])
	assert(cpu.register_a.value == 0x05)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0b10000001, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x00, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xa9_lda_immediate_load_data PASSED!")

func test_0xaa_tax_move_a_to_x():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 10, 0xaa, 0x00])
	assert(cpu.register_x.value == 10)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0b10000001, 0xaa, 0x00])
	assert(cpu.register_x.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0, 0xaa, 0x00])
	assert(cpu.register_x.value == 0)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xaa_tax_move_a_to_x PASSED!")
#LDA $ox10
#LDA #$0x10
#LDA $0x1040

func test_inx_overflow():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0xff, 0xAA, 0xA8, 0xe8, 0xe8, 0xc8,0xc8, 0xc8, 0x00])
	assert(cpu.register_x.value == 1)
	assert(cpu.register_y.value == 2)
	print("test_inx_overflow PASSED!")
	

func test_5_ops_working_together():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 0xc0, 0xaa, 0xe8, 0x00])
	assert(cpu.register_x.value == 0xc1)
	print("test_5_ops_working_together PASSED!")
