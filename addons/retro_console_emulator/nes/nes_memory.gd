class_name NesMemory extends Memory


const MEMORY_SIZE: int = 2048
const RAM: int = 0x0000
const RAM_MIRRORS_END = 0x1FFF
const PPU_REGISTERS: int = 0x2000
const PPU_REGISTERS_MIRRORS_END: int = 0x3FFF
const ROM_MEMORY_STARTS: int = 0x8000
const ROM_MEMORY_ENDS: int = 0xFFFF
const VIRTUAL_SIZE: int = 0xFFFF

var rom: NesRom = null

func _init():
	super(MEMORY_SIZE)


func reset():
	super()
	rom = null


func soft_reset():
	super.reset()


func mem_read(addr: int) -> int:
	if addr >= RAM and addr <= RAM_MIRRORS_END:
		var mirror_down_addr = addr & 0b00000111_11111111;
		_emmit_observer(addr, _memory[mirror_down_addr], _memory[mirror_down_addr], MemoryObserver.ObserverFlags.READ_8)
		return _memory[mirror_down_addr]
	elif addr >= PPU_REGISTERS and addr <= PPU_REGISTERS_MIRRORS_END:
		var _mirror_down_addr = addr & 0b00100000_00000111;
		push_warning("PPU is not supported yet")
		return 0
	if addr >= ROM_MEMORY_STARTS and addr <= ROM_MEMORY_ENDS:
		var prog_rom_byte = _read_prog_rom(addr)
		_emmit_observer(addr, prog_rom_byte, prog_rom_byte, MemoryObserver.ObserverFlags.READ_8)
		return prog_rom_byte
	else:
		push_warning("Ignoring mem access at ", addr)
		return 0

func _read_prog_rom(addr: int) -> int:
	addr -= ROM_MEMORY_STARTS
	assert(rom != null and rom._loading_error == NesRom.LoadingError.OK,
			"Invalid ROM file loaded")
	if rom.prg_rom.size() <= 0x4000 and addr >= 0x4000:
		addr = addr % 0x4000
	return rom.prg_rom[addr]

func mem_write(addr: int, p_value: int):
	if addr >= RAM and addr <= RAM_MIRRORS_END:
		var mirror_down_addr = addr & 0b00000111_11111111;
		_emmit_observer(addr, _memory[mirror_down_addr], p_value, MemoryObserver.ObserverFlags.WRITE_8)
		_memory[mirror_down_addr] = p_value
	elif addr >= PPU_REGISTERS and addr <= PPU_REGISTERS_MIRRORS_END:
		var _mirror_down_addr = addr & 0b00100000_00000111;
		push_warning("PPU is not supported yet")
		return
	elif addr >= ROM_MEMORY_STARTS and addr <= ROM_MEMORY_ENDS:
		push_warning("Attempt to write to Cartridge ROM space")
	else:
		push_warning("Ignoring mem access at ", addr)
		return


func size() -> int:
	return VIRTUAL_SIZE


func real_size() -> int:
	return MEMORY_SIZE


func slice(begin: int, end: int = -1):
	if end == -1:
		end = _memory.size()
	if begin >= RAM and begin <= RAM_MIRRORS_END:
		begin = begin & 0b00000111_11111111;
	elif begin >= PPU_REGISTERS and begin <= PPU_REGISTERS_MIRRORS_END:
		begin = begin & 0b00100000_00000111
	if end >= RAM and end <= RAM_MIRRORS_END:
		end = end & 0b00000111_11111111;
	elif end >= PPU_REGISTERS and end <= PPU_REGISTERS_MIRRORS_END:
		end = end & 0b00100000_00000111
	return _memory.slice(begin, end)
