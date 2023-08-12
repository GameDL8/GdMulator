class_name NesPPU extends RefCounted

signal nmi_interrupt_triggered()
signal register_flags_changed(old_value: int, register: CPU.RegisterFlags)

const COLOR_TABLE : PackedColorArray = [
	Color8(0x80, 0x80, 0x80), Color8(0x00, 0x3D, 0xA6), Color8(0x00, 0x12, 0xB0), Color8(0x44, 0x00, 0x96), Color8(0xA1, 0x00, 0x5E),
	Color8(0xC7, 0x00, 0x28), Color8(0xBA, 0x06, 0x00), Color8(0x8C, 0x17, 0x00), Color8(0x5C, 0x2F, 0x00), Color8(0x10, 0x45, 0x00),
	Color8(0x05, 0x4A, 0x00), Color8(0x00, 0x47, 0x2E), Color8(0x00, 0x41, 0x66), Color8(0x00, 0x00, 0x00), Color8(0x05, 0x05, 0x05),
	Color8(0x05, 0x05, 0x05), Color8(0xC7, 0xC7, 0xC7), Color8(0x00, 0x77, 0xFF), Color8(0x21, 0x55, 0xFF), Color8(0x82, 0x37, 0xFA),
	Color8(0xEB, 0x2F, 0xB5), Color8(0xFF, 0x29, 0x50), Color8(0xFF, 0x22, 0x00), Color8(0xD6, 0x32, 0x00), Color8(0xC4, 0x62, 0x00),
	Color8(0x35, 0x80, 0x00), Color8(0x05, 0x8F, 0x00), Color8(0x00, 0x8A, 0x55), Color8(0x00, 0x99, 0xCC), Color8(0x21, 0x21, 0x21),
	Color8(0x09, 0x09, 0x09), Color8(0x09, 0x09, 0x09), Color8(0xFF, 0xFF, 0xFF), Color8(0x0F, 0xD7, 0xFF), Color8(0x69, 0xA2, 0xFF),
	Color8(0xD4, 0x80, 0xFF), Color8(0xFF, 0x45, 0xF3), Color8(0xFF, 0x61, 0x8B), Color8(0xFF, 0x88, 0x33), Color8(0xFF, 0x9C, 0x12),
	Color8(0xFA, 0xBC, 0x20), Color8(0x9F, 0xE3, 0x0E), Color8(0x2B, 0xF0, 0x35), Color8(0x0C, 0xF0, 0xA4), Color8(0x05, 0xFB, 0xFF),
	Color8(0x5E, 0x5E, 0x5E), Color8(0x0D, 0x0D, 0x0D), Color8(0x0D, 0x0D, 0x0D), Color8(0xFF, 0xFF, 0xFF), Color8(0xA6, 0xFC, 0xFF),
	Color8(0xB3, 0xEC, 0xFF), Color8(0xDA, 0xAB, 0xEB), Color8(0xFF, 0xA8, 0xF9), Color8(0xFF, 0xAB, 0xB3), Color8(0xFF, 0xD2, 0xB0),
	Color8(0xFF, 0xEF, 0xA6), Color8(0xFF, 0xF7, 0x9C), Color8(0xD7, 0xE8, 0x95), Color8(0xA6, 0xED, 0xAF), Color8(0xA2, 0xF2, 0xDA),
	Color8(0x99, 0xFF, 0xFC), Color8(0xDD, 0xDD, 0xDD), Color8(0x11, 0x11, 0x11), Color8(0x11, 0x11, 0x11)
]

var cycles: int = 0
var scanline: int = 0
var chr_rom: PackedByteArray
var palette_table: PackedByteArray # Size: 32     bytes
var vram: PackedByteArray          # Size: 2048 bytes
var oam_data: PackedByteArray      # Size: 256  bytes
var scroll_offset := Vector2i(0, 0)
var next_scroll_is_x: bool = true

var screen_mirroring: NesRom.Mirroring = NesRom.Mirroring.HORIZONTAL

# 0x2000
var register_ctrl := ControlRegister.new(&"Ctrl")
# 0x2001
var register_mask := MaskRegister.new(&"Msk")
# 0x2002
var register_stat := StatusRegister.new(&"St")
# 0x2003
var register_oam_addr: int:
	set = write_to_oam_addr
	# get = _write_only_from_bus
# 0x2004
var register_oam_data: int:
	set = write_to_oam_data,
	get = read_oam_data
# 0x2005
var register_scroll: int:
	set = write_to_scroll
	# get = _write_only_from_bus
# 0x2006
var register_addr := AddrRegister.new()
# 0x2007
var ppu_data: int:
	set = write_to_data,
	get = read_data

var _internal_data_buf: int

func _init(nes_rom: NesRom) -> void:
	if nes_rom != null:
		chr_rom = nes_rom.chr_rom
	palette_table.resize(0x100)
	palette_table.fill(0)
	vram.resize(2048)
	vram.fill(0)
	oam_data.resize(256)
	oam_data.fill(0)
	register_ctrl.flags_changed.connect(_on_register_flags_changed.bind(register_ctrl))
	register_mask.flags_changed.connect(_on_register_flags_changed.bind(register_mask))
	register_stat.flags_changed.connect(_on_register_flags_changed.bind(register_stat))

func _on_register_flags_changed(old_value: int, _new_value: int, p_register: CPU.RegisterFlags):
	register_flags_changed.emit(old_value, p_register)

func tick(p_cycles: int) -> bool:
	cycles += p_cycles
	if cycles >= 341:
		cycles -= 341
		scanline += 1
		
		if scanline == 241:
			register_stat.in_vblank.value = true
			register_stat.sprite_0_hit.value = false
			if register_ctrl.gen_vblank_nmi.value == true:
				nmi_interrupt_triggered.emit()
		
		if scanline >= 262:
			scanline = 0
			register_stat.sprite_0_hit.value = false
			register_stat.in_vblank.value = false
			return true
	return false

func write_to_ppu_addr(value: int) -> void:
	register_addr.update(value)

func write_to_ctrl(value: int) -> void:
	var in_vblank = register_stat.in_vblank.value
	var was_nmi_enabled: bool = register_ctrl.gen_vblank_nmi.value
	register_ctrl.update(value)
	var is_nmi_enabled: bool = register_ctrl.gen_vblank_nmi.value
	
	if in_vblank and !was_nmi_enabled and is_nmi_enabled:
		nmi_interrupt_triggered.emit()

func write_to_mask(value: int) -> void:
	register_mask.update(value)

func write_to_oam_addr(value: int) -> void:
	register_oam_addr = value

func read_oam_addr() -> int:
	return register_oam_addr

func write_to_oam_data(value: int) -> void:
	oam_data[register_oam_addr] = value
	increment_oam_addr()

func read_status() -> int:
	var snapshot: int = register_stat.value
	register_stat.in_vblank.value = false
	register_addr.reset_latch()
	next_scroll_is_x = true
	return snapshot

func read_oam_data() -> int:
	return oam_data[register_oam_addr]

func write_to_scroll(value:int) -> void:
	assert(value & 0xFFFFFF00 == 0, "Expected an 8bits number")
	if next_scroll_is_x:
		scroll_offset.x = value
	else:
		scroll_offset.y = value
	next_scroll_is_x = !next_scroll_is_x

func write_to_data(value: int) -> void:
	var addr: int = register_addr.get_address()
	increment_vram_addr()
	
	if addr >= 0 and addr <= 0x1fff:
		print_verbose("Cannot write to read only address %04x" % addr)
	elif addr >= 0x2000 and addr <= 0x2fff:
		vram[mirror_vram_addr(addr)] = value
	elif addr >= 0x3000 and addr <= 0x3eff:
		print_verbose("addr space 0x3000..0x3eff is not expected to be used, requested = %04x" % addr)
		pass
	elif addr in [0x3f10, 0x3f14, 0x3f18, 0x3f1c]:
		var addr_mirror = addr - 0x10;
		var palette_idx: int = addr_mirror - 0x3f00
		palette_table[palette_idx] = value
	elif addr >= 0x3f00 and addr <= 0x3fff:
		var palette_idx: int = addr - 0x3f00
		palette_table[palette_idx] = value
	else:
		assert(false, "unexpected access to mirrored space %04x" % addr)

func read_data() -> int:
	var addr = register_addr.get_address()
	increment_vram_addr()
	
	if addr >= 0 and addr <= 0x1fff:
		var result = _internal_data_buf
		_internal_data_buf = chr_rom[addr]
		return result
	elif addr >= 0x2000 and addr <= 0x2fff:
		var result = _internal_data_buf
		_internal_data_buf = vram[mirror_vram_addr(addr)]
		return result
	elif addr >= 0x3000 and addr <= 0x3eff:
		print_verbose("addr space 0x3000..0x3eff is not expected to be used, requested = %d" % addr)
		pass
	# Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C
	elif addr in [0x3f10, 0x3f14, 0x3f18, 0x3f1c]:
		var addr_mirror = addr - 0x10;
		return palette_table[(addr_mirror - 0x3f00)]
	elif addr >= 0x3f00 and addr <= 0x3fff:
		return palette_table[addr - 0x3f00]
	else:
		assert(false, "unexpected access to mirrored space %d" % addr)
	return 0

func memcopy_ram_to_oam(p_ram_slice: PackedByteArray) -> void:
	assert(p_ram_slice.size() == 0xFF)
	for byte in p_ram_slice:
		oam_data[register_oam_addr] = byte
		increment_oam_addr()

func increment_oam_addr() -> void:
	register_oam_addr += 1
	if register_oam_addr > 0xFF:
		register_oam_addr = 0

func increment_vram_addr() -> void:
	register_addr.increment(register_ctrl.get_vram_addr_increment())

func mirror_vram_addr(in_addr: int):
	assert(in_addr & 0xFFFF0000 == 0, "Expected a 16bits number")
	var mirrored_vram = in_addr & 0b10111111111111 # mirror down 0x3000-0x3eff to 0x2000 - 0x2eff
	var vram_index = mirrored_vram - 0x2000 # to vram vector
	var name_table = vram_index / 0x400 # to the name table index
	match [screen_mirroring, name_table]:
		[NesRom.Mirroring.VERTICAL, 2], [NesRom.Mirroring.VERTICAL, 3]:
			return vram_index - 0x800
		[NesRom.Mirroring.HORIZONTAL, 2]:
			return vram_index - 0x400
		[NesRom.Mirroring.HORIZONTAL, 1]:
			return vram_index - 0x400
		[NesRom.Mirroring.HORIZONTAL, 3]:
			return vram_index - 0x800
		_:
			return vram_index

class AddrRegister:
	var value: PackedByteArray = [0, 0]
	var hi_ptr: bool = true

	func set_address(data: int) -> void:
		assert(data & 0xFFFF0000 == 0, "Expected a 16bits number")
		value[0] = (data >> 8)
		value[1] = (data & 0xFF)

	func update(data: int) -> void:
		assert(data & 0xFFFFFF00 == 0, "Expected an 8bits number")
		if hi_ptr:
			value[0] = data
		else:
			value[1] = data

		if get_address() > 0x3fff: # mirror down addr above 0x3fff
			set_address(get_address() & 0b11111111111111)
		hi_ptr = !hi_ptr

	func increment(inc: int) -> void:
		var lo = value[1]
		value[1] += inc
		if value[1] > 0xFF:
			value[1] -= 0x100
		if lo > value[1]:
			value[0] += 1
			if value[0] > 0xFF:
				value[0] -= 0x100
		if get_address() > 0x3fff:
			set_address(get_address() & 0b11111111111111)  # mirror down addr above 0x3fff

	func reset_latch() -> void:
		hi_ptr = true

	func get_address() -> int:
		return (value[0] << 8) | (value[1])


class ControlRegister extends CPU.RegisterFlags:
	# 7  bit  0
	# ---- ----
	# VPHB SINN
	# |||| ||||
	# |||| ||++- Base nametable address
	# |||| ||     (0 = $2000 1 = $2400 2 = $2800 3 = $2C00)
	# |||| |+--- VRAM address increment per CPU read/write of PPUDATA
	# |||| |      (0: add 1, going across 1: add 32, going down)
	# |||| +---- Sprite pattern table address for 8x8 sprites
	# ||||        (0: $0000 1: $1000 ignored in 8x16 mode)
	# |||+------ Background pattern table address (0: $0000 1: $1000)
	# ||+------- Sprite size (0: 8x8 pixels 1: 8x16 pixels)
	# |+-------- PPU master/slave select
	# |            (0: read backdrop from EXT pins 1: output color on EXT pins)
	# +--------- Generate an NMI at the start of the
	#              vertical blanking interval (0: off 1: on)
	var nametable_1            = CPU.BitFlag.new(self, &"N1", 0)
	var nametable_2            = CPU.BitFlag.new(self, &"N2", 1)
	var vram_add_increment     = CPU.BitFlag.new(self, &"I", 2)
	var sprite_bank            = CPU.BitFlag.new(self, &"S", 3)
	var background_bank        = CPU.BitFlag.new(self, &"B", 4)
	var sprite_size            = CPU.BitFlag.new(self, &"H", 5)
	var master_slave_select    = CPU.BitFlag.new(self, &"P", 6)
	var gen_vblank_nmi           = CPU.BitFlag.new(self, &"V", 7)
	var bit_flags: Dictionary = {
		nametable_1.name : nametable_1,
		nametable_2.name : nametable_2,
		vram_add_increment.name : vram_add_increment,
		sprite_bank.name : sprite_bank,
		background_bank.name : background_bank,
		sprite_size.name : sprite_size,
		master_slave_select.name : master_slave_select,
		gen_vblank_nmi.name : gen_vblank_nmi
	}
	
	func get_vram_addr_increment() -> int:
		if vram_add_increment.value:
			return 32
		return 1
	
	func update(data: int):
		assert(data & 0xFFFFFF00 == 0, "Expected an 8bits number")
		value = data


class MaskRegister extends CPU.RegisterFlags:
	# 7  bit  0
	# ---- ----
	# BGRs bMmG
	# |||| ||||
	# |||| |||+- Greyscale (0: normal color, 1: produce a greyscale display)
	# |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
	# |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
	# |||| +---- 1: Show background
	# |||+------ 1: Show sprites
	# ||+------- Emphasize red (green on PAL/Dendy)
	# |+-------- Emphasize green (red on PAL/Dendy)
	# +--------- Emphasize blue
	var grayscale           = CPU.BitFlag.new(self, &"G", 0)
	var left_margin_bg      = CPU.BitFlag.new(self, &"m", 1)
	var left_margin_sprites = CPU.BitFlag.new(self, &"M", 2)
	var show_background     = CPU.BitFlag.new(self, &"b", 3)
	var show_sprites        = CPU.BitFlag.new(self, &"s", 4)
	var emphatize_red       = CPU.BitFlag.new(self, &"R", 5)
	var emphatize_green     = CPU.BitFlag.new(self, &"G", 6)
	var emphatize_blue      = CPU.BitFlag.new(self, &"B", 7)

	func update(data: int):
		assert(data & 0xFFFFFF00 == 0, "Expected an 8bits number")
		value = data

class StatusRegister extends CPU.RegisterFlags:
	#7  bit  0
	#---- ----
	#VSO. ....
	#|||| ||||
	#|||+-++++- PPU open bus. Returns stale PPU bus contents.
	#||+------- Sprite overflow. The intent was for this flag to be set
	#||         whenever more than eight sprites appear on a scanline, but a
	#||         hardware bug causes the actual behavior to be more complicated
	#||         and generate false positives as well as false negatives; see
	#||         PPU sprite evaluation. This flag is set during sprite
	#||         evaluation and cleared at dot 1 (the second dot) of the
	#||         pre-render line.
	#|+-------- Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
	#|          a nonzero background pixel; cleared at dot 1 of the pre-render
	#|          line.  Used for raster timing.
	#+--------- Vertical blank has started (0: not in vblank; 1: in vblank).
	#           Set at dot 1 of line 241 (the line *after* the post-render
	#           line); cleared after reading $2002 and at dot 1 of the
	#           pre-render line.
	var sprite_overflow = CPU.BitFlag.new(self, &"O", 5)
	var sprite_0_hit    = CPU.BitFlag.new(self, &"S", 6)
	var in_vblank       = CPU.BitFlag.new(self, &"V", 7)

	func update(data: int):
		assert(data & 0xFFFFFF00 == 0, "Expected an 8bits number")
		value = data
