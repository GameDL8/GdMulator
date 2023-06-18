extends Node

const _UNIT_TEST_PATH: String = "res://addons/retro_console_emulator/tests/nes_rom_test/"
const _UNIT_TEST_FILE_NAME: String = "nestest"
const _UNIT_TEST_EXTENSION: String = "nes"
const _UNIT_TEST_LOG_EXTENSION: String = "log"

const _UNIT_TEST_ROM_FILE = _UNIT_TEST_PATH + _UNIT_TEST_FILE_NAME + "." + _UNIT_TEST_EXTENSION
const _UNIT_TEST_LOG_FILE = _UNIT_TEST_PATH + _UNIT_TEST_FILE_NAME + "." + _UNIT_TEST_LOG_EXTENSION

class UnitTestNesCpu extends NesCPU:
	
	signal instruction_traced(p_trace: String)
	
	func _init() -> void:
		super()
		var unit_test_rom = NesRom.load_from_file(_UNIT_TEST_ROM_FILE)
		assert(unit_test_rom, "Instantiation failed")
		var error: NesRom.LoadingError = unit_test_rom.get_loading_error()
		assert(error == NesRom.LoadingError.OK, "Failed to load file with error %s" % unit_test_rom.get_loading_error_str())
		memory = NesMemory.new()
		memory.rom = unit_test_rom

	var _counter: int = 0
	func _about_to_execute_instruction():
		_counter += 1
		if _counter % 180 == 0:
			await Engine.get_main_loop().create_timer(1).timeout
		instruction_traced.emit(_trace())


	func _trace() -> String:
		var out: String
		# Program Counter
		out += "%4x  " % program_counter.value
		var opcode: int = memory.mem_read(program_counter.value)
		var instruction: OpCode = instructionset.get(opcode, null)
		assert(instruction)
		out += "%02x " % instruction.code
		out += _dump_instruction_arg(instruction, 1) + " "
		out += _dump_instruction_arg(instruction, 2) + " "
		out += _dump_disassemble(instruction)
		out += _dump_registers()
		return out.to_upper()

	func _dump_instruction_arg(instruction: OpCode, arg_idx: int) -> String:
		if instruction.size > arg_idx:
			return "%02x" % memory.mem_read(program_counter.value + arg_idx)
		return "  "
	
	func _dump_disassemble(instruction: OpCode) -> String:
		var out: String = " %s " % instruction.mnemonic
		program_counter.value += 1
		var addr: int = 0
		var value: int = 0
		if instruction.addresing_mode != -1:
			addr = get_operand_address(instruction.addresing_mode)
			value = memory.mem_read(addr)
		else:
			if instruction.mnemonic.begins_with("B"):
				# branch instructions
				addr = program_counter.value
				var jump: int = memory.mem_read(addr)
				if jump & 0b10000000:
					jump = -(((~jump) & 0b01111111)+1)
				jump += 1
				addr = program_counter.value + jump
				out += "$%04x" % addr
		program_counter.value -= 1
		match instruction.addresing_mode:
			AddressingMode.Immediate:
				out += "#$"
				out += _dump_instruction_arg(instruction, 1)
			AddressingMode.ZeroPage:
				out += "$"
				out += _dump_instruction_arg(instruction, 1)
				out += " = %02x" % value
			AddressingMode.ZeroPage_X:
				out += "$"
				out += _dump_instruction_arg(instruction, 1)
				out += ",X @ %02x = %02x" % [addr, value]
			AddressingMode.ZeroPage_Y:
				out += "$"
				out += _dump_instruction_arg(instruction, 1)
				out += ",Y @ %02x = %02x" % [addr, value]
			AddressingMode.Absolute:
				out += "$"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
			AddressingMode.Absolute_X:
				out += "$"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
				out += ",X @ %02x = %02x" % [addr, value]
			AddressingMode.Absolute_Y:
				out += "$"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
				out += ",Y @ %02x = %02x" % [addr, value]
			AddressingMode.Indirect:
				out += "($"
				out += _dump_instruction_arg(instruction, 2)
				out += _dump_instruction_arg(instruction, 1)
				out += ") @ %02x = %02x" % [addr, value]
			AddressingMode.Indirect_X:
				out += "($"
				out += _dump_instruction_arg(instruction, 1)
				out += ",X) @ %02x = %02x" % [addr, value]
			AddressingMode.Indirect_Y:
				out += "($"
				out += _dump_instruction_arg(instruction, 1)
				out += "),Y @ %02x = %02x" % [addr, value]
			_:
				pass
		while out.length() < 33:
			out += " "
		return out

	const _registers = [&"A", &"X", &"Y", &"P", ]
	func _dump_registers() -> String:
		var out := String()
		for register_id in _registers:
			var register = registers.get(register_id, null)
			assert(register)
			out += "%s:%02x " % [register_id, register.value]
		out += "SP:%02x " % stack_pointer
		return out

var cpu := UnitTestNesCpu.new()
var log_file := FileAccess.open(_UNIT_TEST_LOG_FILE, FileAccess.READ)
var line: int = 0
func _ready():
	assert(log_file != null)
	cpu.reset()
	cpu.program_counter.value = 0xC000
	cpu.instruction_traced.connect(_on_cpu_instruction_traced)
	cpu.run()
	
func _on_cpu_instruction_traced(p_trace: String):
	line += 1
	var compare_with: String = log_file.get_line()
	var lenght = p_trace.length()
	var trim = compare_with.substr(0, lenght)
	if p_trace != trim:
		printerr("Trace missmatch on line %d:\n\tlog: %s\n\tcpu: %s" % [line, compare_with, p_trace])
	else:
		print("Trace match on line %d:\n\tlog: %s\n\tcpu: %s" % [line, compare_with, p_trace])
