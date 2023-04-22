extends Node

func _ready() -> void:
	test_lda_load_data()
	test_sta_store_data()
	test_0xaa_tax_move_a_to_x()
	test_0xa8_tax_move_a_to_y()
	test_inx_overflow()
	test_5_ops_working_together()


func test_lda_load_data():
	test_0xa9_lda_immediate_load_data()
	test_0xa5_lda_zeropage_load_data()
	test_0xad_lda_absolute_load_data()
	test_0xb5_lda_zeropage_x_load_data()
	test_0xbd_lda_absolute_x_load_data()
	test_0xb9_lda_absolute_y_load_data()
	test_0xa1_lda_indirect_x_load_data()
	test_0xb1_lda_indirect_y_load_data()

func test_sta_store_data():
	test_0x85_sta_zeropage_store_data()
	test_0x8d_sta_absolute_store_data()
	test_0x95_sta_zeropage_x_store_data()
	test_0x9d_sta_absolute_x_store_data()
	test_0x99_sta_absolute_y_store_data()
	test_0x81_sta_indirect_x_store_data()
	test_0x91_sta_indirect_y_store_data()

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

func test_0xa5_lda_zeropage_load_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x10, 0x15)
	cpu.memory.mem_write(0x11, 0b10000001)
	cpu.memory.mem_write(0x12, 0x00)
	cpu.load_and_run([0xa5, 0x10, 0x00])
	assert(cpu.register_a.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa5, 0x11, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa5, 0x12, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xa5_lda_zeropage_load_data PASSED!")


func test_0xad_lda_absolute_load_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x0110, 0x15)
	cpu.memory.mem_write(0x0111, 0b10000001)
	cpu.memory.mem_write(0x0112, 0x00)
	cpu.load_and_run([0xad, 0x10, 0x01, 0x00])
	assert(cpu.register_a.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xad, 0x11, 0x01, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xad, 0x12, 0x01, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xad_lda_absolute_load_data PASSED!")


func test_0xb5_lda_zeropage_x_load_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x10, 0x15)
	cpu.memory.mem_write(0x11, 0b10000001)
	cpu.memory.mem_write(0x12, 0x00)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xb5, 0x00, 0x00])
	assert(cpu.register_a.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xb5, 0x01, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xb5, 0x02, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xb5_lda_zeropage_x_load_data PASSED!")


func test_0xbd_lda_absolute_x_load_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x0110, 0x15)
	cpu.memory.mem_write(0x0111, 0b10000001)
	cpu.memory.mem_write(0x0112, 0x00)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xbd, 0x00, 0x01, 0x00])
	assert(cpu.register_a.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xbd, 0x01, 0x01, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xbd, 0x02, 0x01, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xbd_lda_absolute_x_load_data PASSED!")


func test_0xb9_lda_absolute_y_load_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x0110, 0x15)
	cpu.memory.mem_write(0x0111, 0b10000001)
	cpu.memory.mem_write(0x0112, 0x00)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb9, 0x00, 0x01, 0x00])
	assert(cpu.register_a.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb9, 0x01, 0x01, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb9, 0x02, 0x01, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xb9_lda_absolute_y_load_data PASSED!")


func test_0xa1_lda_indirect_x_load_data():
	var cpu = NesCPU.new()
	
	cpu.memory.mem_write(0x10, 0x10)
	cpu.memory.mem_write(0x11, 0x01)
	cpu.memory.mem_write(0x12, 0x11)
	cpu.memory.mem_write(0x13, 0x01)
	cpu.memory.mem_write(0x14, 0x12)
	cpu.memory.mem_write(0x15, 0x01)
	
	cpu.memory.mem_write(0x0110, 0x15)
	cpu.memory.mem_write(0x0111, 0b10000001)
	cpu.memory.mem_write(0x0112, 0x00)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xa1, 0x00, 0x00])
	assert(cpu.register_a.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xa1, 0x02, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x10, 0xaa, 0xa1, 0x04, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xa1_lda_indirect_x_load_data PASSED!")
	pass


func test_0xb1_lda_indirect_y_load_data():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x00, 0x00)
	cpu.memory.mem_write(0x01, 0x01)
	cpu.memory.mem_write(0x02, 0x01)
	cpu.memory.mem_write(0x03, 0x01)
	cpu.memory.mem_write(0x04, 0x02)
	cpu.memory.mem_write(0x05, 0x01)

	cpu.memory.mem_write(0x0110, 0x15)
	cpu.memory.mem_write(0x0111, 0b10000001)
	cpu.memory.mem_write(0x0112, 0x00)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb1, 0x00, 0x00])
	assert(cpu.register_a.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb1, 0x02, 0x00])
	assert(cpu.register_a.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb1, 0x04, 0x00])
	assert(cpu.register_a.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xb1_lda_indirect_y_load_data PASSED!")
	pass

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


func test_0xa8_tax_move_a_to_y():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa9, 10, 0xa8, 0x00])
	assert(cpu.register_y.value == 10)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0b10000001, 0xa8, 0x00])
	assert(cpu.register_y.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0, 0xa8, 0x00])
	assert(cpu.register_y.value == 0)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xa8_tax_move_a_to_y PASSED!")


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
