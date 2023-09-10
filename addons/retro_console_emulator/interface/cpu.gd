class_name CPU extends RefCounted

var program_counter := Register16bits.new(&"PC")
var memory: Variant = null

var registers: Dictionary = {
	program_counter.name : program_counter
}

var instructionset: Dictionary = {
	0x00: OpCode.new(0x00, &"BRK", 1, 1, quit)
}

var is_running: bool = false

func load_and_run(p_program: PackedByteArray):
	self.load_program(p_program)
	self.reset()
	self.run()

## VIRTUAL: This method emulates a soft reset interrupt.
func reset():
	is_running = false
	assert(true, "This method should be implemented in inherited class")

## VIRTUAL: This method loads the program in the bus memory.
func load_program(_p_program: PackedByteArray):
	assert(true, "This method should be implemented in inherited class")

## VIRTUAL: This method runs the program loaded into the CPU's memory.
func run():
	is_running = true
	assert(memory != null, "Memory not initialized")
	assert(true, "This method should be implemented in inherited class")

func get_operand_address(_p_mode: int) -> int:
	assert(true, "This method should be implemented in inherited class")
	return 0x00

func quit():
	is_running = false


func _about_to_execute_instruction():
	# VIRTUAL, implement in each cpu as needed
	pass


