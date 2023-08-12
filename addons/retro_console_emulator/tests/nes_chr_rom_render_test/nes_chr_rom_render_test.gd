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
var screen_texture: NesSoftwareScreenTexture = null
@onready var screen: TextureRect = $Screen

var thread := Thread.new()
func _ready():
	cpu = TestNesChrRomRender.new()
	screen_texture = NesSoftwareScreenTexture.new()
	screen_texture.setup(cpu.memory)
	screen.texture = screen_texture
	cpu.reset()
	cpu.run()
