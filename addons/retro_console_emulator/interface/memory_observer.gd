class_name MemoryObserver extends RefCounted

signal memory_read(address: int, value: int)
signal memory_write(address: int, old_value: int, new_value: int)

enum ObserverFlags {
	READ_8       = 0x01 << 0,
	WRITE_8      = 0x01 << 1,
	READ_WRITE_8 = READ_8 | WRITE_8,
	READ_16      = 0x01 << 2,
	WRITE_16     = 0x01 << 3,
	READ_WRITE_16 = READ_16 | WRITE_16,
	DEFAULT = READ_WRITE_8
}

var memory: Memory = null
var range_from: int = 0x0000
var range_to: int = 0xFFFF
var flags: int = ObserverFlags.DEFAULT

func _init(out_memory: Memory, p_range_from: int, p_range_to: int, p_flags: int = ObserverFlags.DEFAULT) -> void:
	assert(out_memory != null)
	assert(p_range_from >= 0 and p_range_from < out_memory.size(), "range from is out of bounds")
	assert(p_range_to >= p_range_from and p_range_from < out_memory.size(), "range to is out of bounds")
	memory = out_memory
	range_from = p_range_from
	range_to = p_range_to
	flags = p_flags


