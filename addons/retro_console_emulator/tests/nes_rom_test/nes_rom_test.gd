extends Control


class NesSnakeCpu extends NesCPU:
	var last_button_pressed: int
	
	const INPUT_MAP: Dictionary = { #[StringName, int]
		&"ui_up": 0x77,
		&"ui_down": 0x73,
		&"ui_left": 0x61,
		&"ui_right": 0x64,
	}
	var _nop_count: int = 0
	const NOP_PER_FRAME: int = 80
	
	func _init() -> void:
		super()
		var snake_rom = NesRom.load_from_file("res://addons/retro_console_emulator/tests/nes_rom_test/snake.nes")
		assert(snake_rom, "Instantiation failed")
		var error: NesRom.LoadingError = snake_rom.get_loading_error()
		assert(error == NesRom.LoadingError.OK, "Failed to load file with error %s" % snake_rom.get_loading_error_str())
		memory = NesMemory.new()
		memory.rom = snake_rom
		instructionset[0xEA] = OpCode.new(0xEA, &"NOP", 1, 2, await_frame)
	
	func await_frame():
		_nop_count += 1
		if _nop_count >= NOP_PER_FRAME:
			_nop_count = 0
			await Engine.get_main_loop().physics_frame
	

	func _about_to_execute_instruction():
		memory.mem_write(0xFE, randi_range(0x00, 0xFF))
		memory.mem_write(0xFF, last_button_pressed)

	
	
	func byte_to_color(p_byte: int) -> Color:
		if p_byte == 0:
			return Color.BLACK
		match (p_byte % 15):
			0:
				return Color.VIOLET
			1:
				return Color.WHITE
			2, 9:
				return Color.GRAY
			3, 10:
				return Color.RED
			4, 11:
				return Color.GREEN
			5, 12:
				return Color.BLUE
			6, 13:
				return Color.DARK_MAGENTA
			7, 14:
				return Color.YELLOW
			_:
				return Color.CYAN


var cpu := NesSnakeCpu.new()
var screen_observer = cpu.memory.create_memory_observer(0x0200, 0x05FF, MemoryObserver.ObserverFlags.WRITE_8)


func _input(event: InputEvent) -> void:
	for action in cpu.INPUT_MAP.keys():
		if event.is_action(action):
			if event.is_pressed():
				cpu.last_button_pressed = cpu.INPUT_MAP[action]
			get_viewport().set_input_as_handled()


func _ready():
	_refresh_screen()
	screen_observer.memory_write.connect(_on_screen_observer_memory_write)
	cpu.reset()
	cpu.run()


func _refresh_screen():
	var screen_frame: PackedByteArray = cpu.memory.slice(0x0200, 0x0600)
	for i in range(screen_frame.size()):
		_update_screen_pixel(i, cpu.byte_to_color(screen_frame[i]))


func _on_screen_observer_memory_write(p_address: int, _p_old_value: int, p_new_value: int):
	_update_screen_pixel(p_address - 0x0200, cpu.byte_to_color(p_new_value))


func _update_screen_pixel(p_pixel_index: int, p_color: Color):
	var pixel_texture: TextureRect = get_child(p_pixel_index) as TextureRect
	pixel_texture.self_modulate = p_color
