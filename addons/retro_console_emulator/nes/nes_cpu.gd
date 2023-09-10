class_name NesCPU extends RefCounted

const PAL_SLEEP_TIME: float = 1.0/50.0
const NTSC_SLEEP_TIME: float = 1.0/60.0
const STACK: int       = 0x0100
const STACK_RESET: int = 0xfd


enum AddressingMode {
	Immediate,
	ZeroPage,
	ZeroPage_X,
	ZeroPage_Y,
	Absolute,
	Absolute_X,
	Absolute_Y,
	Indirect,
	Indirect_X,
	Indirect_Y,
	NoneAddressing
}


var memory = NesMemory.new()
var program_counter := Register16bits.new(&"PC")
var register_a := Register8bits.new(&"A")
var register_x := Register8bits.new(&"X")
var register_y := Register8bits.new(&"Y")
var flags := NesRegisterFlags.new(&"P")
var stack_pointer: int = STACK_RESET
var registers: Dictionary = {
	program_counter.name : program_counter
}

var instructionset: Array[OpCode] = []

var is_running: bool = false


var _sleeping: bool = false
var _run_in_thread: bool = true
var _running_thread: Thread = null
var _running_mutex: Mutex = null
var _frame_start: float = 0


func _init(p_run_in_thread: bool = true) -> void:
	registers[register_a.name] = register_a
	registers[register_x.name] = register_x
	registers[register_y.name] = register_y
	registers[flags.name] = flags
	memory.nmi_interrupt_triggered.connect(_on_interrupt_triggered.bind(0xFFFA, false))
	memory.irq_interrupt_triggered.connect(_on_interrupt_triggered.bind(0xFFFE, false))
	memory.advance_frame.connect(_on_memory_advance_frame)
	_run_in_thread = p_run_in_thread
	
	#register instructions
	var instructions: Dictionary = {
		# BRK on NES system forces an interrupt
		0x00: OpCode.new(0x00, &"BRK", 1, 1, nes_break),
		# ADC - Add with Carry
		0x69: OpCode.new(0x69, &"ADC", 2, 2, add_with_carry_to_register.bind(register_a, AddressingMode.Immediate)),
		0x65: OpCode.new(0x65, &"ADC", 2, 3, add_with_carry_to_register.bind(register_a, AddressingMode.ZeroPage)),
		0x75: OpCode.new(0x75, &"ADC", 2, 4, add_with_carry_to_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x6D: OpCode.new(0x6D, &"ADC", 3, 4, add_with_carry_to_register.bind(register_a, AddressingMode.Absolute)),
		0x7D: OpCode.new(0x7D, &"ADC", 3, 4, add_with_carry_to_register.bind(register_a, AddressingMode.Absolute_X)),
		0x79: OpCode.new(0x79, &"ADC", 3, 4, add_with_carry_to_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x61: OpCode.new(0x61, &"ADC", 2, 6, add_with_carry_to_register.bind(register_a, AddressingMode.Indirect_X)),
		0x71: OpCode.new(0x71, &"ADC", 2, 5, add_with_carry_to_register.bind(register_a, AddressingMode.Indirect_Y)),
		# AND
		0x29: OpCode.new(0x29, &"AND", 2, 2, bitwise_and_with_register.bind(register_a, AddressingMode.Immediate)),
		0x25: OpCode.new(0x25, &"AND", 2, 3, bitwise_and_with_register.bind(register_a, AddressingMode.ZeroPage)),
		0x35: OpCode.new(0x35, &"AND", 2, 4, bitwise_and_with_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x2D: OpCode.new(0x2D, &"AND", 3, 4, bitwise_and_with_register.bind(register_a, AddressingMode.Absolute)),
		0x3D: OpCode.new(0x3D, &"AND", 3, 4, bitwise_and_with_register.bind(register_a, AddressingMode.Absolute_X)),
		0x39: OpCode.new(0x39, &"AND", 3, 4, bitwise_and_with_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x21: OpCode.new(0x21, &"AND", 2, 6, bitwise_and_with_register.bind(register_a, AddressingMode.Indirect_X)),
		0x31: OpCode.new(0x31, &"AND", 2, 5, bitwise_and_with_register.bind(register_a, AddressingMode.Indirect_Y)),
		# ASL
		0x0A: OpCode.new(0x0A, &"ASL", 1, 2, arithmetic_shift_left_register.bind(register_a)),
		0x06: OpCode.new(0x06, &"ASL", 2, 5, arithmetic_shift_left_memory.bind(AddressingMode.ZeroPage)),
		0x16: OpCode.new(0x16, &"ASL", 2, 6, arithmetic_shift_left_memory.bind(AddressingMode.ZeroPage_X)),
		0x0E: OpCode.new(0x0E, &"ASL", 3, 6, arithmetic_shift_left_memory.bind(AddressingMode.Absolute)),
		0x1E: OpCode.new(0x1E, &"ASL", 3, 7, arithmetic_shift_left_memory.bind(AddressingMode.Absolute_X)),
		# BCC - BCS
		0x90: OpCode.new(0x90, &"BCC", 2, 2, branch_if_flag_matches.bind(flags.C, false)),
		0xB0: OpCode.new(0xB0, &"BCS", 2, 2, branch_if_flag_matches.bind(flags.C, true)),
		# BEQ - BNE
		0xF0: OpCode.new(0xF0, &"BEQ", 2, 2, branch_if_flag_matches.bind(flags.Z, true)),
		0xD0: OpCode.new(0xD0, &"BNE", 2, 2, branch_if_flag_matches.bind(flags.Z, false)),
		# BIT
		0x24: OpCode.new(0x24, &"BIT", 2, 3, bit_test_register.bind(register_a, AddressingMode.ZeroPage)),
		0x2C: OpCode.new(0x2C, &"BIT", 3, 4, bit_test_register.bind(register_a, AddressingMode.Absolute)),
		# BMI - BPL
		0x30: OpCode.new(0x30, &"BMI", 2, 2, branch_if_flag_matches.bind(flags.N, true)),
		0x10: OpCode.new(0x10, &"BPL", 2, 2, branch_if_flag_matches.bind(flags.N, false)),
		# BVC - BVS
		0x50: OpCode.new(0x50, &"BVC", 2, 2, branch_if_flag_matches.bind(flags.V, false)),
		0x70: OpCode.new(0x70, &"BVS", 2, 2, branch_if_flag_matches.bind(flags.V, true)),
		# CLC - CLD - CLI - CLV
		0x18: OpCode.new(0x18, &"CLC", 1, 2, set_flag.bind(flags.C, false)),
		0xD8: OpCode.new(0xD8, &"CLD", 1, 2, set_flag.bind(flags.D, false)),
		0x58: OpCode.new(0x58, &"CLI", 1, 2, set_flag.bind(flags.I, false)),
		0xB8: OpCode.new(0xB8, &"CLV", 1, 2, set_flag.bind(flags.V, false)),
		# SEC - SED - SEI
		0x38: OpCode.new(0x38, &"SEC", 1, 2, set_flag.bind(flags.C, true)),
		0xF8: OpCode.new(0xF8, &"SED", 1, 2, set_flag.bind(flags.D, true)),
		0x78: OpCode.new(0x78, &"SEI", 1, 2, set_flag.bind(flags.I, true)),
		# CMP
		0xC9: OpCode.new(0xC9, &"CMP", 2, 2, compare_register.bind(register_a, AddressingMode.Immediate)),
		0xC5: OpCode.new(0xC5, &"CMP", 2, 3, compare_register.bind(register_a, AddressingMode.ZeroPage)),
		0xD5: OpCode.new(0xD5, &"CMP", 2, 4, compare_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0xCD: OpCode.new(0xCD, &"CMP", 3, 4, compare_register.bind(register_a, AddressingMode.Absolute)),
		0xDD: OpCode.new(0xDD, &"CMP", 3, 4, compare_register.bind(register_a, AddressingMode.Absolute_X)),
		0xD9: OpCode.new(0xD9, &"CMP", 3, 4, compare_register.bind(register_a, AddressingMode.Absolute_Y)),
		0xC1: OpCode.new(0xC1, &"CMP", 2, 6, compare_register.bind(register_a, AddressingMode.Indirect_X)),
		0xD1: OpCode.new(0xD1, &"CMP", 2, 5, compare_register.bind(register_a, AddressingMode.Indirect_Y)),
		# CPX
		0xE0: OpCode.new(0xE0, &"CPX", 2, 2, compare_register.bind(register_x, AddressingMode.Immediate)),
		0xE4: OpCode.new(0xE4, &"CPX", 2, 3, compare_register.bind(register_x, AddressingMode.ZeroPage)),
		0xEC: OpCode.new(0xEC, &"CPX", 3, 4, compare_register.bind(register_x, AddressingMode.Absolute)),
		# CPY
		0xC0: OpCode.new(0xC0, &"CPY", 2, 2, compare_register.bind(register_y, AddressingMode.Immediate)),
		0xC4: OpCode.new(0xC4, &"CPY", 2, 3, compare_register.bind(register_y, AddressingMode.ZeroPage)),
		0xCC: OpCode.new(0xCC, &"CPY", 3, 4, compare_register.bind(register_y, AddressingMode.Absolute)),
		# LDA
		0xA9: OpCode.new(0xA9, &"LDA", 2, 2, load_register8.bind(register_a, AddressingMode.Immediate)),
		0xA5: OpCode.new(0xA5, &"LDA", 2, 3, load_register8.bind(register_a, AddressingMode.ZeroPage)),
		0xAD: OpCode.new(0xAD, &"LDA", 3, 4, load_register8.bind(register_a, AddressingMode.Absolute)),
		0xB5: OpCode.new(0xB5, &"LDA", 2, 4, load_register8.bind(register_a, AddressingMode.ZeroPage_X)),
		0xBD: OpCode.new(0xBD, &"LDA", 3, 4, load_register8.bind(register_a, AddressingMode.Absolute_X)),
		0xB9: OpCode.new(0xB9, &"LDA", 3, 4, load_register8.bind(register_a, AddressingMode.Absolute_Y)),
		0xA1: OpCode.new(0xA1, &"LDA", 2, 6, load_register8.bind(register_a, AddressingMode.Indirect_X)),
		0xB1: OpCode.new(0xB1, &"LDA", 2, 5, load_register8.bind(register_a, AddressingMode.Indirect_Y)),
		# LDX
		0xA2: OpCode.new(0xA2, &"LDX", 2, 2, load_register8.bind(register_x, AddressingMode.Immediate)),
		0xA6: OpCode.new(0xA6, &"LDX", 2, 3, load_register8.bind(register_x, AddressingMode.ZeroPage)),
		0xB6: OpCode.new(0xB6, &"LDX", 2, 4, load_register8.bind(register_x, AddressingMode.ZeroPage_Y)),
		0xAE: OpCode.new(0xAE, &"LDX", 3, 4, load_register8.bind(register_x, AddressingMode.Absolute)),
		0xBE: OpCode.new(0xBE, &"LDX", 3, 4, load_register8.bind(register_x, AddressingMode.Absolute_Y)),
		# LDY
		0xA0: OpCode.new(0xA0, &"LDY", 2, 2, load_register8.bind(register_y, AddressingMode.Immediate)),
		0xA4: OpCode.new(0xA4, &"LDY", 2, 3, load_register8.bind(register_y, AddressingMode.ZeroPage)),
		0xB4: OpCode.new(0xB4, &"LDY", 2, 4, load_register8.bind(register_y, AddressingMode.ZeroPage_X)),
		0xAC: OpCode.new(0xAC, &"LDY", 3, 4, load_register8.bind(register_y, AddressingMode.Absolute)),
		0xBC: OpCode.new(0xBC, &"LDY", 3, 4, load_register8.bind(register_y, AddressingMode.Absolute_X)),
		# LSR
		0x4A: OpCode.new(0x4A, &"LSR", 1, 2, logical_shift_right_register.bind(register_a)),
		0x46: OpCode.new(0x46, &"LSR", 2, 5, logical_shift_right_memory.bind(AddressingMode.ZeroPage)),
		0x56: OpCode.new(0x56, &"LSR", 2, 6, logical_shift_right_memory.bind(AddressingMode.ZeroPage_X)),
		0x4E: OpCode.new(0x4E, &"LSR", 3, 6, logical_shift_right_memory.bind(AddressingMode.Absolute)),
		0x5E: OpCode.new(0x5E, &"LSR", 3, 7, logical_shift_right_memory.bind(AddressingMode.Absolute_X)),
		# NOP
		0xEA: OpCode.new(0xEA, &"NOP", 1, 2, no_operation),
		# ORA
		0x09: OpCode.new(0x09, &"ORA", 2, 2, inclusive_or_with_register.bind(register_a, AddressingMode.Immediate)),
		0x05: OpCode.new(0x05, &"ORA", 2, 3, inclusive_or_with_register.bind(register_a, AddressingMode.ZeroPage)),
		0x15: OpCode.new(0x15, &"ORA", 2, 4, inclusive_or_with_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x0D: OpCode.new(0x0D, &"ORA", 3, 4, inclusive_or_with_register.bind(register_a, AddressingMode.Absolute)),
		0x1D: OpCode.new(0x1D, &"ORA", 3, 4, inclusive_or_with_register.bind(register_a, AddressingMode.Absolute_X)),
		0x19: OpCode.new(0x19, &"ORA", 3, 4, inclusive_or_with_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x01: OpCode.new(0x01, &"ORA", 2, 6, inclusive_or_with_register.bind(register_a, AddressingMode.Indirect_X)),
		0x11: OpCode.new(0x11, &"ORA", 2, 5, inclusive_or_with_register.bind(register_a, AddressingMode.Indirect_Y)),
		# PHA
		0x48: OpCode.new(0x48, &"PHA", 1, 3, push_register_to_stack.bind(register_a)),
		# PHP
		0x08: OpCode.new(0x08, &"PHP", 1, 3, push_register_to_stack.bind(flags)),
		# PLA
		0x68: OpCode.new(0x68, &"PLA", 1, 4, pull_register_from_stack.bind(register_a)),
		# PLP
		0x28: OpCode.new(0x28, &"PLP", 1, 4, pull_register_from_stack.bind(flags)),
		# ROL
		0x2A: OpCode.new(0x2A, &"ROL", 1, 2, rotate_left_register.bind(register_a)),
		0x26: OpCode.new(0x26, &"ROL", 2, 5, rotate_left_memory.bind(AddressingMode.ZeroPage)),
		0x36: OpCode.new(0x36, &"ROL", 2, 6, rotate_left_memory.bind(AddressingMode.ZeroPage_X)),
		0x2E: OpCode.new(0x2E, &"ROL", 3, 6, rotate_left_memory.bind(AddressingMode.Absolute)),
		0x3E: OpCode.new(0x3E, &"ROL", 3, 7, rotate_left_memory.bind(AddressingMode.Absolute_X)),
		# ROR
		0x6A: OpCode.new(0x6A, &"ROR", 1, 2, rotate_right_register.bind(register_a)),
		0x66: OpCode.new(0x66, &"ROR", 2, 5, rotate_right_memory.bind(AddressingMode.ZeroPage)),
		0x76: OpCode.new(0x76, &"ROR", 2, 6, rotate_right_memory.bind(AddressingMode.ZeroPage_X)),
		0x6E: OpCode.new(0x6E, &"ROR", 3, 6, rotate_right_memory.bind(AddressingMode.Absolute)),
		0x7E: OpCode.new(0x7E, &"ROR", 3, 7, rotate_right_memory.bind(AddressingMode.Absolute_X)),
		# RTI
		0x40: OpCode.new(0x40, &"RTI", 1, 6, return_from_interrupt),
		# RTS
		0x60: OpCode.new(0x60, &"RTS", 1, 6, return_from_subroutine),
		# SBC
		0xE9: OpCode.new(0xE9, &"SBC", 2, 2, substract_with_carry_to_register.bind(register_a, AddressingMode.Immediate)),
		0xE5: OpCode.new(0xE5, &"SBC", 2, 3, substract_with_carry_to_register.bind(register_a, AddressingMode.ZeroPage)),
		0xF5: OpCode.new(0xF5, &"SBC", 2, 4, substract_with_carry_to_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0xED: OpCode.new(0xED, &"SBC", 3, 4, substract_with_carry_to_register.bind(register_a, AddressingMode.Absolute)),
		0xFD: OpCode.new(0xFD, &"SBC", 3, 4, substract_with_carry_to_register.bind(register_a, AddressingMode.Absolute_X)),
		0xF9: OpCode.new(0xF9, &"SBC", 3, 4, substract_with_carry_to_register.bind(register_a, AddressingMode.Absolute_Y)),
		0xE1: OpCode.new(0xE1, &"SBC", 2, 6, substract_with_carry_to_register.bind(register_a, AddressingMode.Indirect_X)),
		0xF1: OpCode.new(0xF1, &"SBC", 2, 5, substract_with_carry_to_register.bind(register_a, AddressingMode.Indirect_Y)),
		
		# STA
		0x85: OpCode.new(0x85, &"STA", 2, 3, store_from_register.bind(register_a, AddressingMode.ZeroPage)),
		0x8D: OpCode.new(0x8D, &"STA", 3, 4, store_from_register.bind(register_a, AddressingMode.Absolute)),
		0x95: OpCode.new(0x95, &"STA", 2, 4, store_from_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x9D: OpCode.new(0x9D, &"STA", 3, 5, store_from_register.bind(register_a, AddressingMode.Absolute_X)),
		0x99: OpCode.new(0x99, &"STA", 3, 5, store_from_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x81: OpCode.new(0x81, &"STA", 2, 6, store_from_register.bind(register_a, AddressingMode.Indirect_X)),
		0x91: OpCode.new(0x91, &"STA", 2, 6, store_from_register.bind(register_a, AddressingMode.Indirect_Y)),
		# STX
		0x86: OpCode.new(0x86, &"STX", 2, 3, store_from_register.bind(register_x, AddressingMode.ZeroPage)),
		0x8E: OpCode.new(0x8E, &"STX", 3, 4, store_from_register.bind(register_x, AddressingMode.Absolute)),
		0x96: OpCode.new(0x96, &"STX", 2, 4, store_from_register.bind(register_x, AddressingMode.ZeroPage_Y)),
		# STY
		0x84: OpCode.new(0x84, &"STY", 2, 3, store_from_register.bind(register_y, AddressingMode.ZeroPage)),
		0x8C: OpCode.new(0x8C, &"STY", 3, 4, store_from_register.bind(register_y, AddressingMode.Absolute)),
		0x94: OpCode.new(0x94, &"STY", 2, 4, store_from_register.bind(register_y, AddressingMode.ZeroPage_X)),
		# TAX
		0xAA: OpCode.new(0xAA, &"TAX", 1, 2, transfer_register_from_to.bind(register_a, register_x)),
		# TAY
		0xA8: OpCode.new(0xA8, &"TAY", 1, 2, transfer_register_from_to.bind(register_a, register_y)),
		# TSX
		0xBA: OpCode.new(0xBA, &"TSX", 1, 2, transfer_stack_pointer_to_register.bind(register_x)),
		# TXA
		0x8A: OpCode.new(0x8A, &"TXA", 1, 2, transfer_register_from_to.bind(register_x, register_a)),
		# TXS
		0x9A: OpCode.new(0x9A, &"TXS", 1, 2, transfer_register_to_stack_pointer.bind(register_x)),
		# TYA
		0x98: OpCode.new(0x98, &"TYA", 1, 2, transfer_register_from_to.bind(register_y, register_a)),
		# INC
		0xe6: OpCode.new(0xe6, &"INC", 2, 5, increment_memory.bind(AddressingMode.ZeroPage, 1)),
		0xf6: OpCode.new(0xf6, &"INC", 2, 6, increment_memory.bind(AddressingMode.ZeroPage_X, 1)),
		0xee: OpCode.new(0xee, &"INC", 3, 6, increment_memory.bind(AddressingMode.Absolute, 1)),
		0xfe: OpCode.new(0xfe, &"INC", 3, 7, increment_memory.bind(AddressingMode.Absolute_X, 1)),
		# DEC
		0xc6: OpCode.new(0xc6, &"DEC", 2, 5, increment_memory.bind(AddressingMode.ZeroPage, -1)),
		0xd6: OpCode.new(0xd6, &"DEC", 2, 6, increment_memory.bind(AddressingMode.ZeroPage_X, -1)),
		0xce: OpCode.new(0xce, &"DEC", 3, 6, increment_memory.bind(AddressingMode.Absolute, -1)),
		0xde: OpCode.new(0xde, &"DEC", 3, 7, increment_memory.bind(AddressingMode.Absolute_X, -1)),
		# INX
		0xE8: OpCode.new(0xE8, &"INX", 1, 2, increment_register.bind(register_x, 1)),
		# INY
		0xC8: OpCode.new(0xC8, &"INY", 1, 2, increment_register.bind(register_y, 1)),
		# JMP
		0x4C: OpCode.new(0x4C, &"JMP", 3, 3, jump.bind(AddressingMode.Absolute)),
		0x6C: OpCode.new(0x6C, &"JMP", 3, 5, jump.bind(AddressingMode.Indirect)),
		# JSR
		0x20: OpCode.new(0x20, &"JSR", 3, 6, jump_to_subrountine.bind(AddressingMode.Absolute)),
		# DEX
		0xCA: OpCode.new(0xCA, &"DEX", 1, 2, increment_register.bind(register_x, -1)),
		# DEY
		0x88: OpCode.new(0x88, &"DEY", 1, 2, increment_register.bind(register_y, -1)),
		# EOR
		0x49: OpCode.new(0x49, &"EOR", 2, 2, exclusive_or_with_register.bind(register_a, AddressingMode.Immediate)),
		0x45: OpCode.new(0x45, &"EOR", 2, 3, exclusive_or_with_register.bind(register_a, AddressingMode.ZeroPage)),
		0x55: OpCode.new(0x55, &"EOR", 2, 4, exclusive_or_with_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x4D: OpCode.new(0x4D, &"EOR", 3, 4, exclusive_or_with_register.bind(register_a, AddressingMode.Absolute)),
		0x5D: OpCode.new(0x5D, &"EOR", 3, 4, exclusive_or_with_register.bind(register_a, AddressingMode.Absolute_X)),
		0x59: OpCode.new(0x59, &"EOR", 3, 4, exclusive_or_with_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x41: OpCode.new(0x41, &"EOR", 2, 6, exclusive_or_with_register.bind(register_a, AddressingMode.Indirect_X)),
		0x51: OpCode.new(0x51, &"EOR", 2, 5, exclusive_or_with_register.bind(register_a, AddressingMode.Indirect_Y)),
		# NOP - DOP - TOP: Simple, double, and triple no operation
		0x04: OpCode.new(0x04, &"NOP", 2, 3, ilegal_no_operation.bind(AddressingMode.ZeroPage)),
		0x44: OpCode.new(0x44, &"NOP", 2, 3, ilegal_no_operation.bind(AddressingMode.ZeroPage)),
		0x64: OpCode.new(0x64, &"NOP", 2, 3, ilegal_no_operation.bind(AddressingMode.ZeroPage)),
		0x14: OpCode.new(0x14, &"NOP", 2, 4, ilegal_no_operation.bind(AddressingMode.ZeroPage_X)),
		0x34: OpCode.new(0x34, &"NOP", 2, 4, ilegal_no_operation.bind(AddressingMode.ZeroPage_X)),
		0x54: OpCode.new(0x54, &"NOP", 2, 4, ilegal_no_operation.bind(AddressingMode.ZeroPage_X)),
		0x74: OpCode.new(0x74, &"NOP", 2, 4, ilegal_no_operation.bind(AddressingMode.ZeroPage_X)),
		0xD4: OpCode.new(0xD4, &"NOP", 2, 4, ilegal_no_operation.bind(AddressingMode.ZeroPage_X)),
		0xF4: OpCode.new(0xF4, &"NOP", 2, 4, ilegal_no_operation.bind(AddressingMode.ZeroPage_X)),
		0x80: OpCode.new(0x80, &"NOP", 2, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0x82: OpCode.new(0x82, &"NOP", 2, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0x89: OpCode.new(0x89, &"NOP", 2, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0xC2: OpCode.new(0xC2, &"NOP", 2, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0xE2: OpCode.new(0xE2, &"NOP", 2, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0x0C: OpCode.new(0x0C, &"NOP", 3, 4, ilegal_no_operation.bind(AddressingMode.Absolute)),
		0x1C: OpCode.new(0x1C, &"NOP", 3, 4, ilegal_no_operation.bind(AddressingMode.Absolute_X)),
		0x3C: OpCode.new(0x3C, &"NOP", 3, 4, ilegal_no_operation.bind(AddressingMode.Absolute_X)),
		0x5C: OpCode.new(0x5C, &"NOP", 3, 4, ilegal_no_operation.bind(AddressingMode.Absolute_X)),
		0x7C: OpCode.new(0x7C, &"NOP", 3, 4, ilegal_no_operation.bind(AddressingMode.Absolute_X)),
		0xDC: OpCode.new(0xDC, &"NOP", 3, 4, ilegal_no_operation.bind(AddressingMode.Absolute_X)),
		0xFC: OpCode.new(0xFC, &"NOP", 3, 4, ilegal_no_operation.bind(AddressingMode.Absolute_X)),
		0x1A: OpCode.new(0x1A, &"NOP", 1, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0x3A: OpCode.new(0x3A, &"NOP", 1, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0x5A: OpCode.new(0x5A, &"NOP", 1, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0x7A: OpCode.new(0x7A, &"NOP", 1, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0xDA: OpCode.new(0xDA, &"NOP", 1, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		0xFA: OpCode.new(0xFA, &"NOP", 1, 2, ilegal_no_operation.bind(AddressingMode.Immediate)),
		# Load multiple registers
		0xA7: OpCode.new(0xA7, &"LAX", 2, 3, load_registers8.bind([register_a, register_x], AddressingMode.ZeroPage)),
		0xB7: OpCode.new(0xB7, &"LAX", 2, 4, load_registers8.bind([register_a, register_x], AddressingMode.ZeroPage_Y)),
		0xAF: OpCode.new(0xAF, &"LAX", 3, 4, load_registers8.bind([register_a, register_x], AddressingMode.Absolute)),
		0xBF: OpCode.new(0xBF, &"LAX", 3, 4, load_registers8.bind([register_a, register_x], AddressingMode.Absolute_Y)),
		0xA3: OpCode.new(0xA3, &"LAX", 2, 6, load_registers8.bind([register_a, register_x], AddressingMode.Indirect_X)),
		0xB3: OpCode.new(0xB3, &"LAX", 2, 5, load_registers8.bind([register_a, register_x], AddressingMode.Indirect_Y)),
		# AAX: And registers
		0x87: OpCode.new(0x87, &"SAX", 2, 3, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.ZeroPage)),
		0x97: OpCode.new(0x97, &"SAX", 2, 4, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.ZeroPage_Y)),
		0x83: OpCode.new(0x83, &"SAX", 2, 6, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.Indirect_X)),
		0x8F: OpCode.new(0x8F, &"SAX", 3, 4, bitwise_and_two_registers.bind(register_a, register_x, AddressingMode.Absolute)),
		# SBC
		0xEB: OpCode.new(0xEB, &"SBC", 2, 2, substract_with_carry_to_register.bind(register_a, AddressingMode.Immediate)),
		# DCP
		0xC7: OpCode.new(0xC7, &"DCP", 2, 5, increase_then_compare_register.bind(AddressingMode.ZeroPage, -1, register_a)),
		0xD7: OpCode.new(0xD7, &"DCP", 2, 6, increase_then_compare_register.bind(AddressingMode.ZeroPage_X, -1, register_a)),
		0xCF: OpCode.new(0xCF, &"DCP", 3, 6, increase_then_compare_register.bind(AddressingMode.Absolute, -1, register_a)),
		0xDF: OpCode.new(0xDF, &"DCP", 3, 7, increase_then_compare_register.bind(AddressingMode.Absolute_X, -1, register_a)),
		0xDB: OpCode.new(0xDB, &"DCP", 3, 7, increase_then_compare_register.bind(AddressingMode.Absolute_Y, -1, register_a)),
		0xC3: OpCode.new(0xC3, &"DCP", 2, 8, increase_then_compare_register.bind(AddressingMode.Indirect_X, -1, register_a)),
		0xD3: OpCode.new(0xD3, &"DCP", 2, 8, increase_then_compare_register.bind(AddressingMode.Indirect_Y, -1, register_a)),
		# ISB
		0xE7: OpCode.new(0xE7, &"ISB", 2, 5, increase_memory_decrease_register.bind(register_a, AddressingMode.ZeroPage)),
		0xF7: OpCode.new(0xF7, &"ISB", 2, 6, increase_memory_decrease_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0xEF: OpCode.new(0xEF, &"ISB", 3, 6, increase_memory_decrease_register.bind(register_a, AddressingMode.Absolute)),
		0xFF: OpCode.new(0xFF, &"ISB", 3, 7, increase_memory_decrease_register.bind(register_a, AddressingMode.Absolute_X)),
		0xFB: OpCode.new(0xFB, &"ISB", 3, 7, increase_memory_decrease_register.bind(register_a, AddressingMode.Absolute_Y)),
		0xE3: OpCode.new(0xE3, &"ISB", 2, 8, increase_memory_decrease_register.bind(register_a, AddressingMode.Indirect_X)),
		0xF3: OpCode.new(0xF3, &"ISB", 2, 8, increase_memory_decrease_register.bind(register_a, AddressingMode.Indirect_Y)),
		# SLO
		0x07: OpCode.new(0x07, &"SLO", 2, 5, shift_left_memory_then_logic_or_register.bind(register_a, AddressingMode.ZeroPage)),
		0x17: OpCode.new(0x17, &"SLO", 2, 6, shift_left_memory_then_logic_or_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x0F: OpCode.new(0x0F, &"SLO", 3, 6, shift_left_memory_then_logic_or_register.bind(register_a, AddressingMode.Absolute)),
		0x1F: OpCode.new(0x1F, &"SLO", 3, 7, shift_left_memory_then_logic_or_register.bind(register_a, AddressingMode.Absolute_X)),
		0x1B: OpCode.new(0x1B, &"SLO", 3, 7, shift_left_memory_then_logic_or_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x03: OpCode.new(0x03, &"SLO", 2, 8, shift_left_memory_then_logic_or_register.bind(register_a, AddressingMode.Indirect_X)),
		0x13: OpCode.new(0x13, &"SLO", 2, 8, shift_left_memory_then_logic_or_register.bind(register_a, AddressingMode.Indirect_Y)),
		# RLA
		0x27: OpCode.new(0x27, &"RLA", 2, 5, rotate_left_memory_then_logic_and_register.bind(register_a, AddressingMode.ZeroPage)),
		0x37: OpCode.new(0x37, &"RLA", 2, 6, rotate_left_memory_then_logic_and_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x2F: OpCode.new(0x2F, &"RLA", 3, 6, rotate_left_memory_then_logic_and_register.bind(register_a, AddressingMode.Absolute)),
		0x3F: OpCode.new(0x3F, &"RLA", 3, 7, rotate_left_memory_then_logic_and_register.bind(register_a, AddressingMode.Absolute_X)),
		0x3B: OpCode.new(0x3B, &"RLA", 3, 7, rotate_left_memory_then_logic_and_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x23: OpCode.new(0x23, &"RLA", 2, 8, rotate_left_memory_then_logic_and_register.bind(register_a, AddressingMode.Indirect_X)),
		0x33: OpCode.new(0x33, &"RLA", 2, 8, rotate_left_memory_then_logic_and_register.bind(register_a, AddressingMode.Indirect_Y)),
		# SRE
		0x47: OpCode.new(0x47, &"SRE", 2, 5, shift_right_memory_then_exclusive_or_register.bind(register_a, AddressingMode.ZeroPage)),
		0x57: OpCode.new(0x57, &"SRE", 2, 6, shift_right_memory_then_exclusive_or_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x4F: OpCode.new(0x4F, &"SRE", 3, 6, shift_right_memory_then_exclusive_or_register.bind(register_a, AddressingMode.Absolute)),
		0x5F: OpCode.new(0x5F, &"SRE", 3, 7, shift_right_memory_then_exclusive_or_register.bind(register_a, AddressingMode.Absolute_X)),
		0x5B: OpCode.new(0x5B, &"SRE", 3, 7, shift_right_memory_then_exclusive_or_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x43: OpCode.new(0x43, &"SRE", 2, 8, shift_right_memory_then_exclusive_or_register.bind(register_a, AddressingMode.Indirect_X)),
		0x53: OpCode.new(0x53, &"SRE", 2, 8, shift_right_memory_then_exclusive_or_register.bind(register_a, AddressingMode.Indirect_Y)),
		# RRA
		0x67: OpCode.new(0x67, &"RRA", 2, 5, rotate_right_memory_then_add_to_register.bind(register_a, AddressingMode.ZeroPage)),
		0x77: OpCode.new(0x77, &"RRA", 2, 6, rotate_right_memory_then_add_to_register.bind(register_a, AddressingMode.ZeroPage_X)),
		0x6F: OpCode.new(0x6F, &"RRA", 3, 6, rotate_right_memory_then_add_to_register.bind(register_a, AddressingMode.Absolute)),
		0x7F: OpCode.new(0x7F, &"RRA", 3, 7, rotate_right_memory_then_add_to_register.bind(register_a, AddressingMode.Absolute_X)),
		0x7B: OpCode.new(0x7B, &"RRA", 3, 7, rotate_right_memory_then_add_to_register.bind(register_a, AddressingMode.Absolute_Y)),
		0x63: OpCode.new(0x63, &"RRA", 2, 8, rotate_right_memory_then_add_to_register.bind(register_a, AddressingMode.Indirect_X)),
		0x73: OpCode.new(0x73, &"RRA", 2, 8, rotate_right_memory_then_add_to_register.bind(register_a, AddressingMode.Indirect_Y)),
		# ANC
		0x0B: OpCode.new(0x0B, &"ANC", 2, 2, bitwise_and_with_register_with_carry.bind(register_a, AddressingMode.Immediate)),
		0x2B: OpCode.new(0x2B, &"ANC", 2, 2, bitwise_and_with_register_with_carry.bind(register_a, AddressingMode.Immediate)),
		# ARR
		0x6B: OpCode.new(0x6B, &"ARR", 2, 2, bitwise_and_then_rotate_register_with_cv_flags.bind(register_a, AddressingMode.Immediate)),
		# ASR
		0x4B: OpCode.new(0x4B, &"ASR", 2, 2, bitwise_and_then_shift_register.bind(register_a, AddressingMode.Immediate)),
		# ATX
		0xAB: OpCode.new(0xAB, &"LXA", 2, 2, bitwise_and_with_register_then_transfer_to_register.bind(register_a, register_x, AddressingMode.Immediate)),
		# KIL
		0x02: OpCode.new(0x02, &"KIL", 1, 0, no_operation),
		0x12: OpCode.new(0x12, &"KIL", 1, 0, no_operation),
		0x22: OpCode.new(0x22, &"KIL", 1, 0, no_operation),
		0x32: OpCode.new(0x32, &"KIL", 1, 0, no_operation),
		0x42: OpCode.new(0x42, &"KIL", 1, 0, no_operation),
		0x52: OpCode.new(0x52, &"KIL", 1, 0, no_operation),
		0x62: OpCode.new(0x62, &"KIL", 1, 0, no_operation),
		0x72: OpCode.new(0x72, &"KIL", 1, 0, no_operation),
		0x92: OpCode.new(0x92, &"KIL", 1, 0, no_operation),
		0xB2: OpCode.new(0xB2, &"KIL", 1, 0, no_operation),
		0xD2: OpCode.new(0xD2, &"KIL", 1, 0, no_operation),
		0xF2: OpCode.new(0xF2, &"KIL", 1, 0, no_operation),
		# LAS
		0xBB: OpCode.new(0xBB, &"LAS", 3, 4, bitwise_and_memory_with_stack_then_load_registers.bind([register_a, register_x], AddressingMode.Absolute_Y)),
		# AXS
		0xCB: OpCode.new(0xCB, &"AXS", 2, 2, bitwise_and_registers_then_substract.bind(register_a, register_x, AddressingMode.Immediate)),
		# SHX
		0x9E: OpCode.new(0x9E, &"AXS", 3, 5, bitwise_and_high_addr_byte_with_register.bind(register_x, AddressingMode.Absolute_Y)),
		# SYA
		0x9C: OpCode.new(0x9C, &"SYA", 3, 5, bitwise_and_high_addr_byte_with_register.bind(register_y, AddressingMode.Absolute_X)),
		# TAS
		0x9B: OpCode.new(0x9B, &"TAS", 3, 5, bitwise_and_two_register_to_stack_then_and_with_high_byte_to_memory.bind(register_x, register_a, AddressingMode.Absolute_X)),
		# XAA
		0x8B: OpCode.new(0x8B, &"XXA", 3, 5, unstable_opcode),
		# AHX
		0x93: OpCode.new(0x93, &"AHX", 3, 5, bitwise_and_two_register_with_high_byte_to_memory.bind(register_x, register_a, AddressingMode.Indirect_Y)),
		0x9F: OpCode.new(0x9F, &"AHX", 3, 5, bitwise_and_two_register_with_high_byte_to_memory.bind(register_x, register_a, AddressingMode.Absolute_Y)),
		
	}
	
	instructionset.clear()
	for opcode in range(0xFF + 1):
		assert(instructions.has(opcode))
		assert(instructions[opcode].code == opcode)
		instructionset.push_back(instructions[opcode])


func reset():
	is_running = false
	register_a.value = 0
	register_x.value = 0
	register_y.value = 0
	flags.value = 0b100100
	stack_pointer = STACK_RESET
	program_counter.value = memory.mem_read_16(0xFFFC)


func load_program(p_program: PackedByteArray):
	for i in p_program.size():
		memory.mem_write(0x8000 + i, p_program[i])
	memory.mem_write_16(0xFFFC, 0x8000)


func run():
	_frame_start = Time.get_unix_time_from_system()
	if _run_in_thread:
		_running_thread = Thread.new()
		_running_mutex = Mutex.new()
		_running_thread.start(_run)
	else:
		_run()


func is_running_in_thread():
	return (_run_in_thread and _run_in_thread != null and _running_thread.is_alive())


func _run():
	assert(memory != null, "Memory not initialized")
	is_running = true
	while is_running:
		await _about_to_execute_instruction()
		var opcode: int = memory.mem_read(program_counter.value)
		program_counter.value += 1
		var current_pc = program_counter.value
		
		var instruction: OpCode = instructionset[opcode] as OpCode
		assert(instruction, "Unknown instruction with code %d" % opcode)
		assert(instruction.callback.is_valid(), "Invalid callable for opcode %d" % opcode)
		var extra_cycles: Variant = await instruction.callback.call()
		
		if current_pc == program_counter.value:
			# There was not a jump
			program_counter.value += (instruction.size - 1)
		
		var cycles = instruction.cycles
		if typeof(extra_cycles) == TYPE_INT:
			cycles += extra_cycles
		memory.tick(cycles)


func _on_interrupt_triggered(p_interrupt_jump_addres: int, p_break_flag: bool):
	assert(p_interrupt_jump_addres in [0xFFFA, 0xFFFE])
	stack_push_16(program_counter.value)
	var aux_flag := NesRegisterFlags.new(&"P")
	aux_flag.value = flags.value
	aux_flag.B.value = p_break_flag
	aux_flag.B2.value = true

	stack_push_8(aux_flag.value)
	flags.I.value = true

	memory.tick(2)
	program_counter.value = memory.mem_read_16(p_interrupt_jump_addres)


func _on_memory_advance_frame():
	_sleeping = true

var _did_operand_address_cross_page: bool = false
func did_operand_address_cross_page() -> bool:
	return _did_operand_address_cross_page
func get_operand_address(p_mode: int) -> int:
	assert(p_mode in AddressingMode.values(), "Unknown address mode")
	_did_operand_address_cross_page = false
	match p_mode as AddressingMode:
		AddressingMode.Immediate:
			#LDA  #$0x10
			#0xA9 0x10
			return program_counter.value
		AddressingMode.ZeroPage:
			#LDA  $0x10
			#0xA5 0x10
			return memory.mem_read(program_counter.value)
		AddressingMode.Absolute:
			#LDA  $0x1090
			#0xAD 0x90 0x10  bytes are inverted because of little endianess
			return memory.mem_read_16(program_counter.value)
		AddressingMode.ZeroPage_X:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_x.value)
			if addr > 0xFF:
				addr -= 0x0100
			return addr
		AddressingMode.ZeroPage_Y:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_y.value)
			if addr > 0xFF:
				addr -= 0x0100
			return addr
		AddressingMode.Absolute_X:
			var base: int = memory.mem_read_16(self.program_counter.value)
			var addr: int = (base + register_x.value)
			if addr > 0xFFFF:
				addr -= 0x10000
			_did_operand_address_cross_page = ((base & 0xFF00) != (addr & 0xFF00))
			return addr
		AddressingMode.Absolute_Y:
			var base: int = memory.mem_read_16(self.program_counter.value)
			var addr: int = (base + register_y.value)
			if addr > 0xFFFF:
				addr -= 0x10000
			_did_operand_address_cross_page = ((base & 0xFF00) != (addr & 0xFF00))
			return addr
		AddressingMode.Indirect:
			var addr_addr: int = memory.mem_read_16(program_counter.value)
			var addr: int = memory.mem_read_16(addr_addr)
			var addr1 = (addr + 1)
			if addr1 > 0xFF:
				addr1 -= 0x0100
			var lo = memory.mem_read(addr)
			var hi = memory.mem_read(addr1)
			return (hi << 8) | (lo)
		AddressingMode.Indirect_X:
			var base = memory.mem_read(self.program_counter.value)
			var ptr: int = (base + self.register_x.value)
			if ptr > 0xFF:
				ptr -= 0x0100
			var ptr1 = (ptr + 1)
			if ptr1 > 0xFF:
				ptr1 -= 0x0100
			var lo = memory.mem_read(ptr)
			var hi = memory.mem_read(ptr1)
			return (hi << 8) | (lo)
		AddressingMode.Indirect_Y:
			var base: int = memory.mem_read(self.program_counter.value)
			var lo: int = memory.mem_read(base)
			base += 1
			if base > 0xFF:
				base -= 0x0100
			var hi: int = memory.mem_read(base)
			var deref_base: int = (hi << 8) | (lo)
			var deref: int = (deref_base + self.register_y.value)
			if deref > 0xFFFF:
				deref -= 0x10000
			_did_operand_address_cross_page = ((deref_base & 0xFF00) != (deref & 0xFF00))
			return deref
		_:
			assert(false, "Adressing mode not supported!")
			return 0x00

var instruction_count = 0
func _about_to_execute_instruction():
	instruction_count += 1
	if _sleeping:
		if is_running_in_thread():
#			while Time.get_unix_time_from_system() < _frame_start + NTSC_SLEEP_TIME:
				pass
		else:
			await Engine.get_main_loop().create_timer(0.02).timeout
#			await Engine.get_main_loop().process_frame
		_sleeping = false
		_frame_start = Time.get_unix_time_from_system()

# BRK
func nes_break():
	_on_interrupt_triggered(0xFFFE, true)



# ADC - Add with Carry
func add_with_carry_to_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var previous: int = p_register.value
	var result: int = p_register.value + value
	if flags.C.value == true:
		result += 1
	p_register.value = result & 0xFF
	update_c_flag(result)
	update_v_flag(previous, value, result)
	update_z_n_flags(p_register.value)


#AND
func bitwise_and_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	p_register.value &= value
	update_z_n_flags(p_register.value)


#ASL
func arithmetic_shift_left_register(p_register: Register8bits):
	var value: int = p_register.value
	var shifted: int = value << 1
	var result: int = shifted & 0xFF
	p_register.value = result
	update_c_flag(shifted)
	update_z_n_flags(result)


func arithmetic_shift_left_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var shifted: int = value << 1
	var result: int = shifted & 0xFF
	memory.mem_write(addr, result)
	update_c_flag(shifted)
	update_z_n_flags(result)

#LSR
func logical_shift_right_register(p_register: Register8bits):
	var value: int = p_register.value
	flags.C.value = value & 0x01
	var shifted: int = value >> 1
	p_register.value = shifted
	update_z_n_flags(shifted)


func logical_shift_right_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	flags.C.value = value & 0x01
	var shifted: int = value >> 1
	memory.mem_write(addr, shifted)
	update_z_n_flags(shifted)


#NOP
func no_operation():
	pass


#ORA
func inclusive_or_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var or_result: int = p_register.value | value
	p_register.value = or_result
	update_z_n_flags(or_result)


#PHA - PHP
# p_register can be Register8bits or NesRegisterFlags
func push_register_to_stack(p_register: Variant):
	var unchanged_value: int = p_register.value
	if p_register is NesRegisterFlags:
		flags.B.value = true
		flags.B2.value = true
	stack_push_8(p_register.value)
	p_register.value = unchanged_value


#PLA - PLP
# p_register can be Register8bits or NesRegisterFlags
func pull_register_from_stack(p_register: Variant):
	p_register.value = stack_pop_8()
	if p_register == flags:
		flags.B.value = false
		flags.B2.value = true
	else:
		update_z_n_flags(p_register.value)


#ROL
func rotate_left_register(p_register: Register8bits):
	var old_value = p_register.value
	var value: int = old_value << 1
	value |= 0x01 if flags.C.value else 0x00
	flags.C.value = 0b10000000 & old_value
	value &= 0xFF
	p_register.value = value
	update_z_n_flags(value)


func rotate_left_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var old_value = memory.mem_read(addr)
	var value: int = old_value << 1
	value |= 0x01 if flags.C.value else 0x00
	flags.C.value = 0b10000000 & old_value
	value &= 0xFF
	memory.mem_write(addr, value)
	update_z_n_flags(value)


#ROR
func rotate_right_register(p_register: Register8bits):
	var value: int = p_register.value
	value |= 0b10000000 if flags.C.value else 0x00
	flags.C.value = true if value & 0x01 else false
	value = value >> 1
	p_register.value = value
	update_z_n_flags(value)


func rotate_right_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var old_carry: bool = flags.C.value
	flags.C.value = true if value & 0x01 else false
	value = value >> 1
	value |= 0b10000000 if old_carry else 0x00
	memory.mem_write(addr, value)
	flags.N.value = (value & 0b10000000)


#RTI
func return_from_interrupt():
	flags.value = stack_pop_8()
	flags.B.value = false
	flags.B2.value = true
	program_counter.value = stack_pop_16()
	is_running = true


#RTS
func return_from_subroutine():
	program_counter.value = stack_pop_16() + 1

#SBC
func substract_with_carry_to_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var previous = p_register.value
	var negative = ((~value) & 0xFF)
	var result: int = p_register.value + negative
	if flags.C.value == true:
		result += 1
	p_register.value = result & 0xFF
	update_c_flag(result)
	update_v_flag(previous, negative, result)
	update_z_n_flags(p_register.value)

#BCC - BCS
func branch_if_flag_matches(p_flag: BitFlag, p_is_set: bool):
	var extra_cycles: int = 0
	if p_flag.value == p_is_set:
		extra_cycles += 1
		var addr: int = program_counter.value
		var offset: int = memory.mem_read(addr)
		if offset & 0b10000000:
			offset = -(((~offset) & 0b01111111)+1)
		offset += 1
		var new_addr: int = program_counter.value + offset
		if (new_addr & 0xFF00) != ((addr + 1) & 0xFF00):
			extra_cycles += 1
		program_counter.value += offset
	return extra_cycles


#BIT
func bit_test_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value & p_register.value
	flags.Z.value = (result == 0)
	flags.N.value = value & (1 << 7)
	flags.V.value = value & (1 << 6)


#CLC - CLD - CLI - CLV
#SEC - SED - SEI - SEV
func set_flag(p_flag: BitFlag, p_is_set: bool):
	p_flag.value = p_is_set


#CMP - CPX - CPY
func compare_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = p_register.value - value
	if result < 0:
		result += 0xFF + 1
	set_flag(flags.C, value <= p_register.value)
	update_z_n_flags(result)


#LDA
func load_register8(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	p_register.value = value
	update_z_n_flags(value)
	return (1 if did_operand_address_cross_page() else 0)


#STA
func store_from_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr = self.get_operand_address(p_addressing_mode)
	memory.mem_write(addr, p_register.value)


#TAX
func transfer_register_from_to(p_from: Register8bits, p_to: Register8bits):
	p_to.value = p_from.value
	update_z_n_flags(p_from.value)


#TSX
func transfer_stack_pointer_to_register(p_register: Register8bits):
	p_register.value = stack_pointer
	update_z_n_flags(stack_pointer)


#TXS
func transfer_register_to_stack_pointer(p_register: Register8bits):
	stack_pointer = p_register.value


#INC
func increment_memory(p_addressing_mode: AddressingMode, p_by_amount: int):
	var addr = self.get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value + p_by_amount
	if result > 0xFF:
		result -= 0x0100
	elif result < 0x00:
		result += 0x0100
	memory.mem_write(addr, result)
	update_z_n_flags(result)

#INX - INY - DEX - DEY
func increment_register(p_register: Register8bits, p_by_amount: int):
	var val: int = p_register.value + p_by_amount
	if val > 0xFF:
		val -= 0x0100
	elif val < 0x00:
		val += 0x0100
	p_register.value = val
	update_z_n_flags(p_register.value)


#JMP
func jump(p_addressing_mode: AddressingMode):
	match p_addressing_mode:
		AddressingMode.Absolute:
			var addr: int = memory.mem_read_16(program_counter.value)
			program_counter.value = addr
		AddressingMode.Indirect:
			var addr_addr: int = memory.mem_read_16(program_counter.value)
			var addr: int = memory.mem_read_16(addr_addr)
			# 6502 bug mode with with page boundary:
			# if address $3000 contains $40, $30FF contains $80, and $3100 contains $50,
			# the result of JMP ($30FF) will be a transfer of control to $4080 rather than $5080 as you intended
			# i.e. the 6502 took the low byte of the address from $30FF and the high byte from $3000
			if addr_addr & 0x00FF == 0x00FF:
				var lo: int = memory.mem_read(addr_addr)
				var hi: int = memory.mem_read(addr_addr & 0xFF00)
				addr = hi << 8 | lo
			program_counter.value = addr
		_:
			assert(false, "Invalid addressing mode %d for Jump instruction" % p_addressing_mode)


#JSR
func jump_to_subrountine(p_addressing_mode: AddressingMode):
	assert(p_addressing_mode == AddressingMode.Absolute, "Invalid adressing mode %d for jump to subrutine instruction" % p_addressing_mode)
	stack_push_16(program_counter.value + 2 - 1)
	var addr: int = memory.mem_read_16(program_counter.value)
	program_counter.value = addr


#EOR
func exclusive_or_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr = self.get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value ^ p_register.value
	p_register.value = result
	update_z_n_flags(result)


func update_c_flag(p_value: int):
	var did_carry: bool = p_value & 0xFF00
	flags.C.value = did_carry


func update_v_flag(p_a: int, p_b: int, p_result: int):
	var sign_bit: int = 0b10000000
	if (p_a ^ p_result) & (p_b ^ p_result) & sign_bit != 0:
		flags.V.value = true
	else:
		flags.V.value = false


func update_z_n_flags(p_value: int):
	flags.Z.value = (p_value == 0)
	flags.N.value = (p_value & 0b10000000)



func ilegal_no_operation(p_addressing_mode: AddressingMode):
	var _addr = get_operand_address(p_addressing_mode)
	return 1 if did_operand_address_cross_page() else 0

func load_registers8(p_registers: Array, p_addressing_mode: AddressingMode):
	for register in p_registers:
		load_register8(register, p_addressing_mode)
	return 1 if did_operand_address_cross_page() else 0

func bitwise_and_two_registers(p_reg_1: Register8bits, p_reg_2: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var result: int = p_reg_1.value & p_reg_2.value
	memory.mem_write(addr, result)

func increase_then_compare_register(p_addressing_mode: AddressingMode, p_by_amount: int, p_register: Register8bits):
	increment_memory(p_addressing_mode, p_by_amount)
	compare_register(p_register, p_addressing_mode)

func increase_memory_decrease_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	increment_memory(p_addressing_mode, 1)
	substract_with_carry_to_register(p_register, p_addressing_mode)

func shift_left_memory_then_logic_or_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	arithmetic_shift_left_memory(p_addressing_mode)
	inclusive_or_with_register(p_register, p_addressing_mode)

func shift_right_memory_then_exclusive_or_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	logical_shift_right_memory(p_addressing_mode)
	exclusive_or_with_register(p_register, p_addressing_mode)

func rotate_left_memory_then_logic_and_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	rotate_left_memory(p_addressing_mode)
	bitwise_and_with_register(p_register, p_addressing_mode)

func rotate_right_memory_then_add_to_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	rotate_right_memory(p_addressing_mode)
	add_with_carry_to_register(p_register, p_addressing_mode)

func bitwise_and_with_register_with_carry(p_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_register, p_addressing_mode)
	if flags.N.value:
		flags.C.value = true

func bitwise_and_then_rotate_register_with_cv_flags(p_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_register, p_addressing_mode)
	rotate_right_register(p_register)
	var five: bool = 0b00010000
	var six : bool = 0b00100000
	if five == six and six == true:
		flags.C.value = true
		flags.V.value = false
	if five == six and six == false:
		flags.C.value = false
		flags.V.value = false
	if five and !six:
		flags.C.value = false
		flags.V.value = true
	if !five and six:
		flags.C.value = true
		flags.V.value = true

func bitwise_and_then_shift_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_register, p_addressing_mode)
	logical_shift_right_register(p_register)

func bitwise_and_with_register_then_transfer_to_register(p_and_register: Register8bits, p_transfer_register: Register8bits, p_addressing_mode: AddressingMode):
	bitwise_and_with_register(p_and_register, p_addressing_mode)
	transfer_register_from_to(p_and_register, p_transfer_register)

func bitwise_and_memory_with_stack_then_load_registers(p_registers: Array[Register8bits], p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value & stack_pointer
	stack_pointer = result
	for reg in p_registers:
		reg.value = result
	update_z_n_flags(result)

func bitwise_and_registers_then_substract(p_and_register: Register8bits, p_load_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var to_substract: int = memory.mem_read(addr)
	var and_result: int = p_and_register.value & p_load_register.value
	if to_substract <= and_result:
		flags.C.value = true
	update_z_n_flags(and_result)
	p_load_register.value = and_result

func bitwise_and_high_addr_byte_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var high_byte: int = (addr >> 8) + 1
	if high_byte > 0xFF:
		high_byte -= 0x100
	var and_result: int = p_register.value & high_byte
	memory.mem_write(addr, and_result)

func bitwise_and_two_register_to_stack_then_and_with_high_byte_to_memory(p_reg_1: Register8bits, p_reg_2: Register8bits, p_addressing_mode: AddressingMode):
	stack_pointer = p_reg_1.value & p_reg_2.value
	var addr: int = get_operand_address(p_addressing_mode)
	var high_byte: int = (addr >> 8) + 1
	if high_byte > 0xFF:
		high_byte -= 0x100
	var and_result: int = high_byte & stack_pointer
	memory.mem_write(addr, and_result)

func bitwise_and_two_register_with_high_byte_to_memory(p_reg_1: Register8bits, p_reg_2: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var high_byte: int = (addr >> 8) + 1
	if high_byte > 0xFF:
		high_byte -= 0x100
	var and_result: int = high_byte & p_reg_1.value & p_reg_2.value
	memory.mem_write(addr, and_result)

func unstable_opcode():
	assert(false, "Unstable operation, should never be used!")
	pass

func stack_push_8(p_8bit_address: int):
	memory.mem_write(_get_stack_address(), p_8bit_address)
	_on_stack_push()


func stack_pop_8() -> int:
	_on_stack_pop()
	var value: int = memory.mem_read(_get_stack_address())
	return value


func stack_push_16(p_16bit_address: int):
	var hi: int = p_16bit_address >> 8
	var lo: int = p_16bit_address & 0xFF
	stack_push_8(hi)
	stack_push_8(lo)


func stack_pop_16() -> int:
	var lo: int = stack_pop_8()
	var hi: int = stack_pop_8()
	return (hi << 8) | lo


func _get_stack_address() -> int:
	return STACK + stack_pointer


func _on_stack_push():
	stack_pointer -= 1
	if stack_pointer < 0:
		stack_pointer += 0x0100


func _on_stack_pop():
	stack_pointer += 1
	if stack_pointer > 0xFF:
		stack_pointer -= 0x0100



class NesRegisterFlags extends RegisterFlags:
	# # Status Register (P) http://wiki.nesdev.com/w/index.php/Status_flags
	#
	#  7 6 5 4 3 2 1 0
	#  N V _ B D I Z C
	#  | |   | | | | +--- Carry Flag
	#  | |   | | | +----- Zero Flag
	#  | |   | | +------- Interrupt Disable
	#  | |   | +--------- Decimal Mode (not used on NES)
	#  | |   +----------- Break Command
	#  | +--------------- Overflow Flag
	#  +----------------- Negative Flag
	var C = BitFlag.new(self, &"C", 0)
	var Z = BitFlag.new(self, &"Z", 1)
	var I = BitFlag.new(self, &"I", 2)
	var D = BitFlag.new(self, &"D", 3)
	var B = BitFlag.new(self, &"B", 4)
	var B2 = BitFlag.new(self, &"B2", 5)
	var V = BitFlag.new(self, &"V", 6)
	var N = BitFlag.new(self, &"N", 7)
	var bit_flags: Dictionary = {
		C.name : C,
		Z.name : Z,
		I.name : I,
		D.name : D,
		B.name : B,
		B2.name : B2,
		V.name : V,
		N.name : N
	}
