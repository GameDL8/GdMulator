extends Node

const _UNIT_TEST_PATH: String = "res://addons/retro_console_emulator/tests/nes_rom_test/"
const _UNIT_TEST_FILE_NAME: String = "nestest"
const _UNIT_TEST_EXTENSION: String = "nes"
const _UNIT_TEST_LOG_EXTENSION: String = "log"

const _UNIT_TEST_ROM_FILE = _UNIT_TEST_PATH + _UNIT_TEST_FILE_NAME + "." + _UNIT_TEST_EXTENSION
const _UNIT_TEST_LOG_FILE = _UNIT_TEST_PATH + _UNIT_TEST_FILE_NAME + "." + _UNIT_TEST_LOG_EXTENSION

class UnitTestNesCpu extends NesCPU:
	func _init() -> void:
		super()
		var unit_test_rom = NesRom.load_from_file(_UNIT_TEST_ROM_FILE)
		assert(unit_test_rom, "Instantiation failed")
		var error: NesRom.LoadingError = unit_test_rom.get_loading_error()
		assert(error == NesRom.LoadingError.OK, "Failed to load file with error %s" % unit_test_rom.get_loading_error_str())
		memory = NesMemory.new()
		memory.rom = unit_test_rom


	func _about_to_execute_instruction():
		print(_trace())


	func _trace():
		var out: String
		# Program Counter
		out += "%4x  " % program_counter.value
		var opcode: int = memory.mem_read(program_counter.value)
		var instruction: OpCode = instructionset.get(opcode, null)
		assert(instruction)
		out += "%2x " % instruction.code
		out += _dump_instruction_arg(instruction, 1) + " "
		out += _dump_instruction_arg(instruction, 2) + " "
		out += _dump_disassemble(instruction)

	func _dump_instruction_arg(instruction: OpCode, arg_idx: int) -> String:
		if instruction.size > arg_idx:
			return "%2x" % memory.mem_read(program_counter.value + arg_idx)
		return "  "
	
	func _dump_disassemble(instruction: OpCode) -> String:
		var out: String = " %s " % instruction.mnemonic
		program_counter.value += 1
		var addr = get_operand_address(instruction.addresing_mode)
		var value = memory.mem_read(addr)
		program_counter.value -= 1
		match instruction.addresing_mode:
			AddressingMode.Immediate:
				out += "#$"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
			AddressingMode.ZeroPage:
				out += "$"
				out += _dump_instruction_arg(instruction, 1)
				out += " = %2x" % value
			AddressingMode.ZeroPage_X:
				out += "$"
				out += _dump_instruction_arg(instruction, 1)
				out += ",X @ %2x = %2x" % [addr, value]
			AddressingMode.ZeroPage_Y:
				out += "$"
				out += _dump_instruction_arg(instruction, 1)
				out += ",Y @ %2x = %2x" % [addr, value]
			AddressingMode.Absolute:
				out += "$"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
			AddressingMode.Absolute_X:
				out += "$"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
				out += ",X @ %2x = %2x" % [addr, value]
			AddressingMode.Absolute_Y:
				out += "$"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
				out += ",Y @ %2x = %2x" % [addr, value]
			AddressingMode.Indirect:
				out += "($"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
				out += ") @ %2x = %2x" % [addr, value]
			AddressingMode.Indirect_X:
				out += "($"
				out += _dump_instruction_arg(instruction, 1)
				out += ",X) @ %2x = %2x" % [addr, value]
			AddressingMode.Indirect_Y:
				out += "($"
				out += _dump_instruction_arg(instruction, 1)
				out += "),Y @ %2x = %2x" % [addr, value]
			_:
				pass
		while out.length() < 34:
			out += " "
		return out


var cpu := UnitTestNesCpu.new()
func _ready():
	cpu.reset()
	cpu.run()
	
