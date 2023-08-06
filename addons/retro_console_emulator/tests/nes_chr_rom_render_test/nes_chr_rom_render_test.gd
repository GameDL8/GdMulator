extends Node


class TestNesChrRomRender extends NesCPU:
	func _init() -> void:
		super()
		var test_rom = NesRom.load_from_file("res://addons/retro_console_emulator/tests/nes_chr_rom_render_test/Alter_Ego.nes")
		assert(test_rom, "Instantiation failed")
		var error: NesRom.LoadingError = test_rom.get_loading_error()
		assert(error == NesRom.LoadingError.OK, "Failed to load file with error %s" % test_rom.get_loading_error_str())
		memory.rom = test_rom


var cpu:TestNesChrRomRender = null
@onready var screen: TextureRect = $Screen


func _ready():
	cpu = TestNesChrRomRender.new()
	var frame = show_tileset()
	screen.texture = ImageTexture.create_from_image(frame)


func show_tileset() -> Image:
	var nes_memory: NesMemory = cpu.memory as NesMemory
	var chr_rom: PackedByteArray = nes_memory.ppu.chr_rom
	var frame: Image = Image.create(256, 240, false, Image.FORMAT_RGBA8)
	var coord := Vector2i.ZERO
	for bank_id in range(2):
		var bank: int = bank_id * 0x1000
		for tile_id in range(256):
			var tile: PackedByteArray = chr_rom.slice(bank + tile_id * 16, bank + (tile_id + 1) * 16)
			var palette: PackedColorArray = [
				NesPPU.COLOR_TABLE[0x01],
				NesPPU.COLOR_TABLE[0x23],
				NesPPU.COLOR_TABLE[0x27],
				NesPPU.COLOR_TABLE[0x30],
			]
			for y in range(8):
				var upper: int = tile[y]
				var lower: int = tile[y+8]
				
				for x in range(7, -1, -1):
					var value = ((1 & upper) << 1) | (1 & lower)
					upper = upper >> 1
					lower = lower >> 1
					var color = palette[value]
					frame.set_pixel(coord.x + x, coord.y + y, color)
			coord.x += 8
			if coord.x >= 256:
				coord.x = 0
				coord.y += 8
				if coord.y >= 240:
					push_warning("Did not fit all tiles in the screen, last was tile %d of bank %d" % [tile_id, bank_id])
					return frame
	return frame
