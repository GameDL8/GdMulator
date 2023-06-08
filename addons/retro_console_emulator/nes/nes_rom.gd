class_name NesRom extends RefCounted


enum Mirroring {
	VERTICAL,
	HORIZONTAL,
	FOUR_SCREEN
}


enum LoadingError {
	OK = 0,
	FILE_CORRUPT,
	UNSUPPORTED_VERSION
}


const _NES_TAG: PackedByteArray = [0x4E, 0x45, 0x53, 0x1A]
const PRG_ROM_COUNT_IDX: int = 0x04
const CHR_ROM_COUNT_IDX: int = 0x05
const CONTROL_BYTE_1_IDX: int = 0x06
const CONTROL_BYTE_2_IDX: int = 0x07
const PRG_ROM_PAGE_SIZE: int = 1024 * 16 # 16kB
const CHR_ROM_PAGE_SIZE: int = 1024 * 8 # 8kB

var prg_rom: PackedByteArray
var chr_rom: PackedByteArray
var mapper: int
var screen_mirroring: Mirroring


var _loading_error: LoadingError = LoadingError.OK


func _init(p_raw: PackedByteArray) -> void:
	if p_raw.slice(0, 4) != _NES_TAG:
		_loading_error = LoadingError.FILE_CORRUPT
		push_error("File is not in iNES file format")
		return
	
	# TODO: check p_raw_data.size() >= ¿minsize?
	
	mapper = (p_raw[CONTROL_BYTE_2_IDX] & 0b11110000) \
						| (p_raw[CONTROL_BYTE_1_IDX] >> 4)
	
	var ines_version: int = (p_raw[CONTROL_BYTE_2_IDX] >> 2) & 0b11
	if ines_version != 0:
		_loading_error = LoadingError.UNSUPPORTED_VERSION
		push_error("Unsupported iNES version %d" % ines_version)
		return
	
	var is_four_screen: bool = (p_raw[CONTROL_BYTE_1_IDX] & 0b1000) != 0
	var is_vertical_mirroring: bool = (p_raw[CONTROL_BYTE_1_IDX] & 0b1) != 0
	match [is_four_screen, is_vertical_mirroring]:
		[true, _]:
			screen_mirroring = Mirroring.FOUR_SCREEN
		[false, true]:
			screen_mirroring = Mirroring.VERTICAL
		[false, false]:
			screen_mirroring = Mirroring.HORIZONTAL
	
	var prg_rom_size: int = p_raw[PRG_ROM_COUNT_IDX] * PRG_ROM_PAGE_SIZE
	var chr_rom_size: int = p_raw[CHR_ROM_COUNT_IDX] * CHR_ROM_PAGE_SIZE
	
	var has_tainer: bool = p_raw[CONTROL_BYTE_1_IDX] & 0b100 != 0
	
	var prg_rom_start = 16 + (512 if has_tainer else 0)
	var chr_rom_start = prg_rom_start + prg_rom_size
	
	prg_rom = p_raw.slice(prg_rom_start, prg_rom_start + prg_rom_size)
	chr_rom = p_raw.slice(chr_rom_start, chr_rom_start + chr_rom_size)

static func load_from_file(p_path: String) -> NesRom:
	if !FileAccess.file_exists(p_path):
		push_error("Cannot load NesRom from unexisting file: %s" % p_path)
		return null
	var raw_file: PackedByteArray = FileAccess.get_file_as_bytes(p_path)
	var rom = NesRom.new(raw_file)
	return rom


func get_loading_error() -> int:
	return _loading_error


func get_loading_error_str() -> String:
	return LoadingError.find_key(_loading_error)

