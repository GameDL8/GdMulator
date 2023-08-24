class_name NesSoftwareScreenTexture extends ImageTexture

const PALETTE: PackedColorArray = [
	NesPPU.COLOR_TABLE[0x01],
	NesPPU.COLOR_TABLE[0x23],
	NesPPU.COLOR_TABLE[0x27],
	NesPPU.COLOR_TABLE[0x30],
]

var ppu: NesPPU
var displayed_image: int = 0
var swapchain: Array[Image] = [
	Image.create(256, 240, false, Image.FORMAT_RGBA8),
	Image.create(256, 240, false, Image.FORMAT_RGBA8),
	Image.create(256, 240, false, Image.FORMAT_RGBA8)
]
var edited_image: Image = null
var _render_mutex := Mutex.new()

func setup(p_memory: NesMemory) -> void:
	ppu = p_memory.ppu
	p_memory.advance_frame.connect(_on_nes_advance_frame)
	edited_image = swapchain[displayed_image]
	render()

func _on_nes_advance_frame():
	render()

func render():
	_update_screen()
	_render_mutex.lock()
	edited_image = swapchain[(displayed_image + 2) % 3]
	displayed_image = (displayed_image + 1) % 3
	set_image.call_deferred(swapchain[displayed_image])
	_render_mutex.unlock()

func _update_screen():
	var bank: int = ppu.register_ctrl.background_bank.value
	bank *= 0x1000
	
	_render_mutex.lock()
	for i in range(0x03C0):
		var tile_id: int = ppu.vram[i]
		var tile_x: int = i % 32
		var tile_y: int = i / 32
		var tile: PackedByteArray = ppu.chr_rom.slice(
			bank + tile_id * 16, bank + (tile_id+1) * 16)
		for y in range(8):
			var upper: int = tile[y]
			var lower: int = tile[y+8]
			
			for x in range(7, -1, -1):
				var value = ((1 & upper) << 1) | (1 & lower)
				upper = upper >> 1
				lower = lower >> 1
				var color = PALETTE[value]
				edited_image.set_pixel(tile_x*8 + x, tile_y*8 + y, color)
	_render_mutex.unlock()
