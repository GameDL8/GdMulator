class_name NesSoftwareScreenTexture extends ImageTexture

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
	if !ppu.screen_changed:
		return
	_update_background()
	_update_sprites()
	_render_mutex.lock()
	edited_image = swapchain[(displayed_image + 2) % 3]
	displayed_image = (displayed_image + 1) % 3
	_set_image.call_deferred(displayed_image)
	_render_mutex.unlock()

func _set_image(image_idx: int):
	set_image(swapchain[image_idx])

func _update_background():
	var bank: int = ppu.register_ctrl.background_bank.value
	bank *= 0x1000
	
	_render_mutex.lock()
	for i in range(0x03C0):
		var tile_id: int = ppu.vram[i]
		var tile_x: int = i % 32
		var tile_y: int = i / 32
		var tile: PackedByteArray = ppu.chr_rom.slice(
			bank + tile_id * 16, bank + (tile_id+1) * 16)
		var palette: PackedByteArray = _bg_pallette(tile_x, tile_y)
		var color: Color = Color.BLACK
		for y in range(8):
			var upper: int = tile[y]
			var lower: int = tile[y+8]
			for x in range(7, -1, -1):
				var value = ((1 & lower) << 1) | (1 & upper)
				upper = upper >> 1
				lower = lower >> 1
				match value:
					0:
						color = NesPPU.COLOR_TABLE[ppu.palette_table[0]]
					1, 2, 3:
						color = NesPPU.COLOR_TABLE[palette[value]]
					_:
						assert(false, "can't happen")
				edited_image.set_pixel(tile_x*8 + x, tile_y*8 + y, color)
	_render_mutex.unlock()

func _update_sprites():
	var data: PackedByteArray = ppu.oam_data
	var indexes: PackedInt32Array = range(0, data.size(), 4)
	indexes.reverse()
	for i in indexes:
		var tile_id: int = data[i+1]
		var tile_x: int = data[i+3]
		var tile_y: int = data[i]
		
		if tile_id != 0:
			pass
		var tile_flags: int = data[i+2]
		var flip_v: bool = (tile_flags >> 7 & 1 == 1)
		var flip_h: bool = (tile_flags >> 6 & 1 == 1)
		var pallete_idx: int = tile_flags & 0b11
		var palette: PackedByteArray = _sprite_palette(pallete_idx)
		
		var bank: int = ppu.register_ctrl.sprite_bank.value
		bank *= 0x1000
		
		var tile: PackedByteArray = ppu.chr_rom.slice(
			bank + tile_id * 16, bank + (tile_id+1) * 16)
		
		var color: Color = Color.BLACK
		for y in range(8):
			var upper: int = tile[y]
			var lower: int = tile[y+8]
			for x in range(7, -1, -1):
				var value = ((1 & lower) << 1) | (1 & upper)
				upper = upper >> 1
				lower = lower >> 1
				match value:
					0:
						# transparent pixel, dont render
						continue
					1, 2, 3:
						color = NesPPU.COLOR_TABLE[palette[value]]
					_:
						assert(false, "can't happen")
				var pixel_x = tile_x
				var pixel_y = tile_y
				match [flip_h, flip_v]:
					[false, false]:
						pixel_x += x
						pixel_y += y
					[true, false]:
						pixel_x += 7 - x
						pixel_y += y
					[false, true]:
						pixel_x += x
						pixel_y += 7 - y
					[true, true]:
						pixel_x += 7 - x
						pixel_y += 7 - y
				if pixel_x < 256 and pixel_y < 240:
					edited_image.set_pixel(pixel_x, pixel_y, color)

func _bg_pallette(tile_column: int, tile_row: int) -> PackedByteArray:
	var attr_table_idx: int = tile_row / 4 * 8 +  tile_column / 4
	var attr_byte: int = ppu.vram[0x3c0 + attr_table_idx]  # note: still using hardcoded first nametable
	
	var pallet_idx:int = 0
	match [(tile_column %4) / 2, (tile_row % 4) / 2]:
		[0,0]:
			pallet_idx = attr_byte & 0b11
		[1,0]:
			pallet_idx = (attr_byte >> 2) & 0b11
		[0,1]:
			pallet_idx = (attr_byte >> 4) & 0b11
		[1,1]:
			pallet_idx = (attr_byte >> 6) & 0b11
		_:
			assert(false, "should not happen")

	var pallete_start: int = pallet_idx * 4
	return [ppu.palette_table[0], ppu.palette_table[pallete_start+1], ppu.palette_table[pallete_start+2], ppu.palette_table[pallete_start+3]]


func _sprite_palette(pallete_idx: int) -> PackedByteArray:
	var start: int = 0x11 + (pallete_idx * 4)
	return [
		0,
		ppu.palette_table[start],
		ppu.palette_table[start+1],
		ppu.palette_table[start+2]
	]
