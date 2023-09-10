extends Node

func _ready() -> void:
	for test_group in get_children():
		if &"test" in test_group:
			test_group.test()
	
	test_inx_overflow()
	test_5_ops_working_together()


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
