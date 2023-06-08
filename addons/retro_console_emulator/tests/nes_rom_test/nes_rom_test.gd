extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rom = NesRom.load_from_file("res://addons/retro_console_emulator/tests/nes_rom_test/snake.nes")
	assert(rom, "Instantiation failed")
	var error: NesRom.LoadingError = rom.get_loading_error()
	assert(error == NesRom.LoadingError.OK, "Failed to load file with error %s" % rom.get_loading_error_str())
