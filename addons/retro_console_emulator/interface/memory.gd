class_name Memory extends RefCounted

var _memory: PackedByteArray
var _observers: Array[MemoryObserver]

func _init(p_size: int):
	_memory.resize(p_size)
	reset()

func reset():
	_memory.fill(0)

func mem_read(addr: int) -> int:
	assert(addr >= 0 and addr < _memory.size())
	_emmit_observer(addr, _memory[addr], _memory[addr], MemoryObserver.ObserverFlags.READ_8)
	return _memory[addr]

func mem_write(addr: int, p_value: int):
	assert(addr >= 0 and addr < _memory.size())
	assert(p_value <= 0xFF)
	_emmit_observer(addr, _memory[addr], p_value, MemoryObserver.ObserverFlags.WRITE_8)
	_memory[addr] = p_value

func mem_read_16(addr: int) -> int:
	var lo: int = self.mem_read(addr)
	var hi: int = self.mem_read(addr + 1)
	var result: int = (hi << 8) | (lo)
	_emmit_observer(addr, result, result, MemoryObserver.ObserverFlags.READ_16)
	return result

func mem_write_16(addr: int, p_value: int):
	var old_lo: int = _memory[addr]
	var old_hi: int = _memory[addr + 1]
	var old_value: int = (old_hi << 8) | (old_lo)
	var hi: int = (p_value >> 8)
	var lo: int = (p_value & 0xff)
	self.mem_write(addr, lo)
	self.mem_write(addr + 1, hi)
	_emmit_observer(addr, old_value, p_value, MemoryObserver.ObserverFlags.WRITE_16)

func size() -> int:
	return _memory.size()

func slice(begin: int, end: int = -1):
	if end == -1:
		end = _memory.size() -1
	return _memory.slice(begin, end)


func create_memory_observer(
		p_range_from: int,
		p_range_to: int,
		p_flags: int = MemoryObserver.ObserverFlags.DEFAULT
	) -> MemoryObserver:
	var observer = MemoryObserver.new(self, p_range_from, p_range_to, p_flags)
	_observers.push_back(observer)
	return observer

func remove_observer(out_observer: MemoryObserver):
	_observers.erase(out_observer)

func _emmit_observer(p_address: int, p_value_old: int, p_value_new: int, p_operation: MemoryObserver.ObserverFlags):
	for observer in _observers:
		if p_address < observer.range_from || p_address > observer.range_to:
			continue
		if observer.flags & p_operation == 0:
			continue
		
		match p_operation:
			MemoryObserver.ObserverFlags.READ_8, MemoryObserver.ObserverFlags.READ_16:
				observer.memory_read.emit(p_address, p_value_old)
			MemoryObserver.ObserverFlags.WRITE_8, MemoryObserver.ObserverFlags.WRITE_16:
				observer.memory_write.emit(p_address, p_value_old, p_value_new)

