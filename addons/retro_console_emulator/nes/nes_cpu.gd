class_name NesCPU extends CPU

# chip name is 2A03, based on 6502

enum AddressingMode {
	Immediate,
	ZeroPage,
	ZeroPage_X,
	ZeroPage_Y,
	Absolute,
	Absolute_X,
	Absolute_Y,
	Indirect_X,
	Indirect_Y,
	NoneAddressing
}

var register_a := Register8bits.new()
var register_x := Register8bits.new()
var register_y := Register8bits.new()
var flags := NesRegisterFlags.new()

func _init() -> void:
	registers[&"A"] = register_a
	registers[&"X"] = register_x
	registers[&"Y"] = register_y
	registers[&"P"] = flags
	memory = Memory.new(0xFFFF)

func reset():
	register_a.value = 0
	register_x.value = 0
	register_y.value = 0
	flags.value = 0
	
	program_counter.value = memory.mem_read_16(0xFFFC)

func load(p_program: PackedByteArray):
	for i in p_program.size():
		memory.mem_write(0x8000 + i, p_program[i])
	memory.mem_write_16(0xFFFC, 0x8000)

## VIRTUAL: This method runs the program loaded into the CPU's memory.
func run():
	assert(memory != null, "Memory not initialized")
	
	while true:
		var opcode = memory.mem_read(program_counter.value)
		program_counter.value += 1
		
		match opcode:
			0xA9:
				var param: int = memory.mem_read(program_counter.value)
				program_counter.value += 1
				load_register8(register_a, param)
			0xAA: # TAX
				transfer_register_from_to(register_a, register_x)
			0xA8: #TAY
				transfer_register_from_to(register_a, register_y)
			0xE8: #INX
				increment_register(register_x)
			0xC8: #INY
				increment_register(register_y)
			0x00: # BRK
				break
			_:
				# TODO
				pass


func get_operand_address(p_mode: int) -> int:
	assert(p_mode in AddressingMode.values(), "Unknown address mode")
	match p_mode as AddressingMode:
		AddressingMode.Immediate:
			#LDA  #$0x10
			#0xA9 0x10
			return program_counter.value
		AddressingMode.ZeroPage:
			#LDA  $0x10
			#0xA5 0x10
			return memory.mem_read(program_counter.value)
		AddressingMode.Absolute:
			#LDA  $0x1090
			#0xAD 0x90 0x10 ; bytes are inverted because of little endianess
			return memory.mem_read_16(program_counter.value)
		AddressingMode.ZeroPage_X:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_x.value) % 0xFF
			return addr
		AddressingMode.ZeroPage_Y:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_y.value) % 0xFF
			return addr
		AddressingMode.Absolute_X:
			var base: int = memory.mem_read_u16(self.program_counter)
			var addr: int = (base + register_x.value) % 0xFFFF
			return addr
		AddressingMode.Absolute_Y:
			var base: int = memory.mem_read_u16(self.program_counter)
			var addr: int = (base + register_y.value) % 0xFFFF
			return addr
		AddressingMode.Indirect_X:
			var base = memory.mem_read(self.program_counter.value)
			var ptr: int = (base + self.register_x.value) % 0xFF
			var ptr1 = (ptr + 1) % 0xFF
			var lo = memory.mem_read(ptr)
			var hi = memory.mem_read(ptr1)
			return (hi << 8) | (lo)
		AddressingMode.Indirect_Y:
			var base: int = memory.mem_read(self.program_counter.value);
			var lo: int = memory.mem_read(base);
			var hi: int = memory.mem_read((base + 1) % 0xFF);
			var deref_base: int = (hi << 8) | (lo);
			var deref: int = (deref_base + self.register_y.value) % 0xFFFF
			return deref
		_:
			assert(false, "Adressing mode not supported!")
			return 0x00

#LDA
func load_register8(p_register: Register8bits, p_value: int):
	p_register.value = p_value
	update_z_n_flags(p_value)

#TAX
func transfer_register_from_to(p_from: Register8bits, p_to: Register8bits):
	p_to.value = p_from.value
	update_z_n_flags(p_from.value)

#INC
func increment_register(p_register: Register8bits):
	var val: int = p_register.value + 1
	p_register.value = val & 0b11111111
	update_z_n_flags(p_register.value)

func update_z_n_flags(p_value: int):
	flags.Z.value = (p_value == 0)
	flags.N.value = (p_value & 0b10000000)


class NesRegisterFlags extends CPU.RegisterFlags:
	var C = BitFlag.new(self, 0)
	var Z = BitFlag.new(self, 1)
	var I = BitFlag.new(self, 2)
	var D = BitFlag.new(self, 3)
	var B = BitFlag.new(self, 4)
	var V = BitFlag.new(self, 6)
	var N = BitFlag.new(self, 7)
