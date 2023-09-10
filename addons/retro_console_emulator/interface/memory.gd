class_name Memory extends RefCounted

var _memory: PackedByteArray
var cpu_cycles: int = 0


func _init(p_size: int):
	_memory.resize(p_size)
	reset()

func reset():
	_memory.fill(0)


# VIRTUAL
func soft_reset():
	pass


# VIRTUAL
func tick(p_cycles: int):
	cpu_cycles += p_cycles


func mem_read(addr: int) -> int:
	assert(addr >= 0 and addr < _memory.size())
	return _memory[addr]

func mem_write(addr: int, p_value: int):
	assert(addr >= 0 and addr < _memory.size())
	assert(p_value <= 0xFF)
	_memory[addr] = p_value

func mem_read_16(addr: int) -> int:
	var lo: int = self.mem_read(addr)
	var hi: int = self.mem_read(addr + 1)
	var result: int = (hi << 8) | (lo)
	return result

func mem_write_16(addr: int, p_value: int):
	var hi: int = (p_value >> 8)
	var lo: int = (p_value & 0xff)
	self.mem_write(addr, lo)
	self.mem_write(addr + 1, hi)

func size() -> int:
	return _memory.size()

func slice(begin: int, end: int = -1):
	if end == -1:
		end = _memory.size()
	return _memory.slice(begin, end)

