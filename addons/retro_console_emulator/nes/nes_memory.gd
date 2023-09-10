class_name NesMemory extends Memory

signal nmi_interrupt_triggered()
signal irq_interrupt_triggered()
signal advance_frame()

const MEMORY_SIZE: int = 2048
const RAM: int = 0x0000
const RAM_MIRRORS_END = 0x1FFF
const PPU_REGISTERS: int = 0x2000
const PPU_REGISTERS_MIRRORS_END: int = 0x3FFF
const ROM_MEMORY_STARTS: int = 0x8000
const ROM_MEMORY_ENDS: int = 0xFFFF
const VIRTUAL_SIZE: int = 0xFFFF

var rom: NesRom = null:
	set = _set_rom
var ppu: NesPPU = null:
	set = _set_ppu
var player1_joypad: NesJoypad = null
var player2_joypad: NesJoypad = null

func _init():
	super(MEMORY_SIZE)
	ppu = NesPPU.new(rom)
	player1_joypad = NesJoypad.new(&"_1")
	player2_joypad = NesJoypad.new(&"_2")

func reset():
	super()
	rom = null


func soft_reset():
	super.reset()


func tick(p_cycles: int):
	super(p_cycles)
	ppu.tick(p_cycles * 3)


func peek_memory(addr:int) -> int:
	if addr >= RAM and addr <= RAM_MIRRORS_END:
		var mirror_down_addr: int = addr & 0b00000111_11111111
		return _memory[mirror_down_addr]
	elif addr >= PPU_REGISTERS and addr <= PPU_REGISTERS_MIRRORS_END:
		assert(ppu != null, "Cannot access ppu memory when it is null")
		match addr:
			0x2000:
				return ppu.register_ctrl.value
			0x2001:
				return ppu.register_mask.value
			0x2002:
				return ppu.register_stat.value
			0x2003:
				return ppu.register_oam_addr
			0x2004:
				return ppu.register_oam_data
			0x2005:
				return ppu.scroll_offset.x if ppu.next_scroll_is_x else ppu.scroll_offset.y
			0x2006:
				return ppu.register_addr.get_address()
			0x2007:
				return ppu.peek_data()
			_:
				assert(addr >= 0x2008, "Unexpected memory address: %04x" % addr)
				var mirror_down_addr: int = addr & 0b00100000_00000111
				return peek_memory(mirror_down_addr)
	elif addr == 0x4014:
		# peeking in a write only memory
		return 0
	elif addr >= ROM_MEMORY_STARTS and addr <= ROM_MEMORY_ENDS:
		var prog_rom_byte = _read_prog_rom(addr)
		return prog_rom_byte
	elif addr in [0x4016, 0x4017]:
		var joypay: NesJoypad = player1_joypad if addr == 0x4016 else player2_joypad
		return joypay.peek()
	else:
		push_warning("Ignoring mem access at ", addr)
		return 0

func mem_read(addr: int) -> int:
	if addr >= RAM and addr <= RAM_MIRRORS_END:
		var mirror_down_addr = addr & 0b00000111_11111111
		_emmit_observer(addr, _memory[mirror_down_addr], _memory[mirror_down_addr], MemoryObserver.ObserverFlags.READ_8)
		return _memory[mirror_down_addr]
	elif addr >= PPU_REGISTERS and addr <= PPU_REGISTERS_MIRRORS_END:
		assert(ppu != null, "Cannot access ppu memory when it is null")
		match addr:
			0x2000, 0x2001, 0x2003, 0x2005, 0x2006:
				assert(false, "Attempt to read from write-only PPU address %04x" % addr)
				return 0
			0x2002:
				var val = ppu.read_status()
				_emmit_observer(addr, val, val, MemoryObserver.ObserverFlags.READ_8)
				return val
			0x2004:
				var val = ppu.register_oam_data
				_emmit_observer(addr, val, val, MemoryObserver.ObserverFlags.READ_8)
				return val
			0x2007:
				var val = ppu.read_data()
				_emmit_observer(addr, val, val, MemoryObserver.ObserverFlags.READ_8)
				return val
			_:
				assert(addr >= 0x2008, "Unexpected memory address: %04x" % addr)
				var mirror_down_addr = addr & 0b00100000_00000111
				var val = mem_read(mirror_down_addr)
				_emmit_observer(addr, val, val, MemoryObserver.ObserverFlags.READ_8)
				return val
	elif addr == 0x4014:
		assert(false, "Attempt to read from write-only PPU address %04x" % addr)
		return 0
	elif addr >= ROM_MEMORY_STARTS and addr <= ROM_MEMORY_ENDS:
		var prog_rom_byte = _read_prog_rom(addr)
		_emmit_observer(addr, prog_rom_byte, prog_rom_byte, MemoryObserver.ObserverFlags.READ_8)
		return prog_rom_byte
	elif addr in [0x4016, 0x4017]:
		var joypad: NesJoypad = player1_joypad if addr == 0x4016 else player2_joypad
		var status = joypad.read()
		_emmit_observer(addr, status, status, MemoryObserver.ObserverFlags.READ_8)
		return status
	else:
		print_verbose("Ignoring mem access at ", addr)
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
		match addr:
			0x2002:
				assert(false, "Attempt to write from read-only PPU address %04x" % addr)
				return
			0x2000:
				_emmit_observer(addr, ppu.register_ctrl.value, p_value, MemoryObserver.ObserverFlags.WRITE_8)
				ppu.write_to_ctrl(p_value)
			0x2001:
				_emmit_observer(addr, ppu.register_mask.value, p_value, MemoryObserver.ObserverFlags.WRITE_8)
				ppu.write_to_mask(p_value)
			0x2003:
				_emmit_observer(addr, ppu.register_oam_addr, p_value, MemoryObserver.ObserverFlags.WRITE_8)
				ppu.write_to_oam_addr(p_value)
			0x2004:
				var old_value = ppu.register_oam_data
				_emmit_observer(addr, old_value, p_value, MemoryObserver.ObserverFlags.WRITE_8)
				ppu.register_oam_data = p_value
			0x2005:
				var old_scroll: Vector2i = ppu.scroll_offset
				var old_value = old_scroll.x if ppu.next_scroll_is_x else old_scroll.y
				_emmit_observer(addr, old_value, p_value, MemoryObserver.ObserverFlags.WRITE_8)
				ppu.register_scroll = p_value
			0x2006:
				var old_value = ppu.register_addr.value[1 if ppu.register_addr.hi_ptr else 0]
				_emmit_observer(addr, old_value, p_value, MemoryObserver.ObserverFlags.WRITE_8)
				ppu.write_to_ppu_addr(p_value)
			0x2007:
				var old_value = ppu._internal_data_buf
				_emmit_observer(addr, old_value, p_value, MemoryObserver.ObserverFlags.WRITE_8)
				ppu.ppu_data = p_value
			_:
				if addr in range(0x2008, PPU_REGISTERS_MIRRORS_END+1):
					var mirror_down_addr = addr & 0b00100000_00000111
					mem_write(mirror_down_addr, p_value)
					return
				assert(false, "Uncatched case for memory address: %04x" % addr)
		return
	elif addr == 0x4014:
		# RAM -> OAM Copy!
		_emmit_observer(addr, 0, p_value, MemoryObserver.ObserverFlags.WRITE_8)
		var mem: PackedByteArray = []
		mem.resize(256)
		var begin: int = (p_value << 8)
		for i in range(256):
			mem[i] = peek_memory(begin + i)
		ppu.memcopy_ram_to_oam(mem)
	elif addr >= ROM_MEMORY_STARTS and addr <= ROM_MEMORY_ENDS:
		print(false, "Attempt to write to Cartridge ROM space")
	elif addr in [0x4016, 0x4017]:
		var joypay: NesJoypad = player1_joypad if addr == 0x4016 else player2_joypad
		return joypay.write(p_value)
	else:
		print_verbose("Ignoring mem access at %02x" % addr)
		return


func size() -> int:
	return VIRTUAL_SIZE


func real_size() -> int:
	return MEMORY_SIZE


func slice(begin: int, end: int = -1):
	if begin >= RAM and begin <= RAM_MIRRORS_END:
		begin = begin & 0b00000111_11111111;
		if end == -1:
			end = RAM_MIRRORS_END
	elif begin >= PPU_REGISTERS and begin <= PPU_REGISTERS_MIRRORS_END:
		begin = begin & 0b00100000_00000111
		if end == -1:
			return ppu.vram
	if begin >= ROM_MEMORY_STARTS and begin <= ROM_MEMORY_ENDS:
		begin = begin - ROM_MEMORY_STARTS;
		if end == -1:
			return rom.prg_rom
	if end >= RAM and end <= RAM_MIRRORS_END:
		end = end & 0b00000111_11111111;
	elif end >= PPU_REGISTERS and end <= PPU_REGISTERS_MIRRORS_END:
		end = end & 0b00100000_00000111
		return ppu.vram.slice(begin-0x2000, end - 0x2000)
	if end >= RAM and end <= RAM_MIRRORS_END:
		end = end & 0b00000111_11111111;
	elif end >= PPU_REGISTERS and end <= PPU_REGISTERS_MIRRORS_END:
		end = end & 0b00100000_00000111
		return ppu.vram.slice(begin-0x2000, end - 0x2000)
	elif end >= ROM_MEMORY_STARTS and end <= ROM_MEMORY_ENDS:
		end = end - ROM_MEMORY_STARTS
		return rom.prg_rom.slice(begin-0x2000, end - 0x2000)
	if end == -1:
		end = _memory.size()
	return _memory.slice(begin, end)


func _set_rom(new_rom: NesRom) -> void:
	rom = new_rom
	_update_ppu_memory()


func _set_ppu(new_ppu: NesPPU) -> void:
	if ppu != null and ppu.nmi_interrupt_triggered.is_connected(_trigger_ppu_nmi_interrupt):
		ppu.nmi_interrupt_triggered.disconnect(_trigger_ppu_nmi_interrupt)
	ppu = new_ppu
	ppu.nmi_interrupt_triggered.connect(_trigger_ppu_nmi_interrupt)
	_update_ppu_memory()


func _update_ppu_memory() -> void:
	if ppu != null and rom != null:
		ppu.chr_rom = rom.chr_rom
		ppu.screen_mirroring = rom.screen_mirroring


func _trigger_ppu_nmi_interrupt():
	advance_frame.emit()
	player1_joypad.update_status()
	player2_joypad.update_status()
	nmi_interrupt_triggered.emit()
	

