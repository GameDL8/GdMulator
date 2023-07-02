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
		instruction_traced.emit(_trace())


	func _trace() -> String:
		var out: String
		# Program Counter
		out += "%04x  " % program_counter.value
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
		var out: String = "*" if instruction.has_meta(&"is_ilegal") else " "
		out += "%s " % instruction.mnemonic
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
			if instruction.mnemonic in [&"LSR", &"ASL", &"ROL", &"ROR"] \
					and instruction.register != StringName():
				out += "%s" % instruction.register
		program_counter.value -= 1
		if instruction.size > 1:
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
					if (instruction.mnemonic.substr(0, 2) in ["LD", "ST", "CP"]
							or instruction.mnemonic in [&"BIT", &"ORA", &"AND", &"EOR", &"ADC",
							&"CMP", &"SBC", &"LSR", &"ASL", &"ROR", &"ROL", &"INC", &"DEC"]
							or instruction.has_meta(&"is_ilegal")):
						out += " = %02x" % value
				AddressingMode.Absolute_X:
					out += "$"
					out += _dump_instruction_arg(instruction, 2)
					out += _dump_instruction_arg(instruction, 1)
					out += ",X @ %04x = %02x" % [addr, value]
				AddressingMode.Absolute_Y:
					out += "$"
					out += _dump_instruction_arg(instruction, 2)
					out += _dump_instruction_arg(instruction, 1)
					out += ",Y @ %04x = %02x" % [addr, value]
				AddressingMode.Indirect:
					var addr_addr: int = memory.mem_read_16(program_counter.value + 1)
					addr = memory.mem_read_16(addr_addr)
					# 6502 bug mode with with page boundary:
					# if address $3000 contains $40, $30FF contains $80, and $3100 contains $50,
					# the result of JMP ($30FF) will be a transfer of control to $4080 rather than $5080 as you intended
					# i.e. the 6502 took the low byte of the address from $30FF and the high byte from $3000
					if addr_addr & 0x00FF == 0x00FF:
						var lo: int = memory.mem_read(addr_addr)
						var hi: int = memory.mem_read(addr_addr & 0xFF00)
						addr = hi << 8 | lo 
					out += "($"
					out += _dump_instruction_arg(instruction, 2)
					out += _dump_instruction_arg(instruction, 1)
	#				out += ") @ %02x = %02x" % [addr, value]
					out += ") = %04x" % [addr]
				AddressingMode.Indirect_X:
					var addr_plus_x: = memory.mem_read(program_counter.value + 1)
					addr_plus_x += register_x.value
					if addr_plus_x > 0xFF:
						addr_plus_x -= 0x0100
					out += "($"
					out += _dump_instruction_arg(instruction, 1)
					out += ",X) @ %02x = %04x = %02x" % [addr_plus_x, addr, value]
				AddressingMode.Indirect_Y:
					var base: = memory.mem_read(program_counter.value + 1)
					var lo: int = memory.mem_read(base);
					base += 1
					if base > 0xFF:
						base -= 0x0100
					var hi: int = memory.mem_read(base);
					var deref_base: int = (hi << 8) | (lo)
					out += "($"
					out += _dump_instruction_arg(instruction, 1)
					out += "),Y = %04x @ %04x = %02x" % [deref_base, addr, value]
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
	cpu.instruction_traced.connect(_on_cpu_instruction_traced)
	cpu.run()


var trace_history: Array[Trace] = []
var missmatch_count: = 0
var last_printed: int = -5
func _on_cpu_instruction_traced(p_trace: String):
	line += 1
	var log_line: String = log_file.get_line()
	var trace := Trace.new(line, log_line, p_trace)
	
	if !trace.matches:
		trace_history[-4].print()
		trace_history[-3].print()
		trace_history[-2].print()
		trace_history[-1].print()
		trace.print()
		missmatch_count += 1
		last_printed = line
	elif (line - last_printed) < 3:
		trace.print()
	trace_history.push_back(trace)
	if missmatch_count >= 5:
		breakpoint

class Trace:
	var line: int
	var log_line: String
	var trace_line: String
	var remainder: String
	var matches: bool = true
	var did_print: bool = false
	func _init(p_line: int, p_log_line: String, p_trace_line: String) -> void:
		line = p_line
		log_line = p_log_line
		trace_line = p_trace_line
		var lenght = p_trace_line.length()
		var trim = log_line.substr(0, lenght)
		remainder = log_line.substr(lenght)
		matches = trace_line == trim
	
	
	func print():
		if did_print:
			return
		did_print = true
		if matches:
			print_rich(("%d: " % line) + trace_line + "[color=yellow]" + remainder + "[/color]\n")
		else:
			var out_trace: String = "%d: " % line
			var out_log: String = "%d: " % line
			for i in range(trace_line.length()):
				if trace_line.substr(i, 1) == log_line.substr(i, 1):
					out_log += log_line.substr(i, 1)
					out_trace += trace_line.substr(i, 1)
				else:
					out_log += "[color=red]" + log_line.substr(i, 1) + "[/color]"
					out_trace += "[color=green]" + trace_line.substr(i, 1) + "[/color]"
			print_rich(out_log + "[color=yellow]" + remainder + "[/color]")
			print_rich(out_trace + "\n")
