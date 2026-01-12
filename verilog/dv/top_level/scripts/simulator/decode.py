from typing import List, Tuple
import math

from common.defs import *
from common.bits import bits, signed, unsigned

class Instruction:
    class OpcodeError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    class MemoryAlignError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    class MemoryAddressError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    class CallStackError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    class Opcode:
        ADD     = 0x0
        ADDI    = 0x1
        SUB     = 0x2
        MUL     = 0x3
        MULI    = 0x4
        AND     = 0x5
        ANDI    = 0x6
        OR      = 0x7
        ORI     = 0x8
        XOR     = 0x9
        XORI    = 0xA
        SLL     = 0xB
        SRL     = 0xC
        SRA     = 0xD
        SLLV    = 0xE
        SRLV    = 0xF
        SRAV    = 0x10
        LUI     = 0x11
        LLI     = 0x12
        OUT     = 0x13
        MAC     = 0x14
        MACCL   = 0x15
        MACRD   = 0x16
        SPEQ    = 0x17
        SPLT    = 0x18
        SPLTU   = 0x19
        CLRP    = 0x1A
        SPR     = 0x1B
        SRP     = 0x1C
        SREQ    = 0x1D
        SRLT    = 0x1E
        SRLTU   = 0x1F
        LW      = 0x20
        LB      = 0x21
        SW      = 0x22
        SB      = 0x23
        JUMP    = 0x24
        JAL     = 0x25
        JRET    = 0x26
        HALT    = 0x27

        OPCODE_TO_STRING = {
            ADD:     "add",
            ADDI:    "addi",
            SUB:     "sub",
            MUL:     "mul",
            MULI:    "muli",
            AND:     "and",
            ANDI:    "andi",
            OR:      "or",
            ORI:     "ori",
            XOR:     "xor",
            XORI:    "xori",
            SLL:     "sll",
            SRL:     "srl",
            SRA:     "sra",
            SLLV:    "sllv",
            SRLV:    "srlv",
            SRAV:    "srav",
            LUI:     "lui",
            LLI:     "lli",
            OUT:     "out",
            MAC:     "mac",
            MACCL:   "maccl",
            MACRD:   "macrd",
            SPEQ:    "speq",
            SPLT:    "splt",
            SPLTU:   "spltu",
            CLRP:    "clrp",
            SPR:     "spr",
            SRP:     "srp",
            SREQ:    "sreq",
            SRLT:    "srlt",
            SRLTU:   "srltu",
            LW:      "lw",
            LB:      "lb",
            SW:      "sw",
            SB:      "sb",
            JUMP:    "jump",
            JAL:     "jal",
            JRET:    "jret",
            HALT:    "halt",
        }

        OPCODE_TO_TYPE = {
            ADD:    "R",
            ADDI:   "I",
            SUB:    "R",
            MUL:    "R",
            MULI:   "I",
            AND:    "R",
            ANDI:   "I",
            OR:     "R",
            ORI:    "I",
            XOR:    "R",
            XORI:   "I",
            SLL:    "S",
            SRL:    "S",
            SRA:    "S",
            SLLV:   "R",
            SRLV:   "R",
            SRAV:   "R",
            LUI:    "D",
            LLI:    "D",
            OUT:    "R",
            MAC:    "R",
            MACCL:  "R",
            MACRD:  "R",
            SPEQ:   "P",
            SPLT:   "P",
            SPLTU:  "P",
            CLRP:   "P",
            SPR:    "R",
            SRP:    "R",
            SREQ:   "R",
            SRLT:   "R",
            SRLTU:  "R",
            LW:     "M",
            LB:     "M",
            SW:     "M",
            SB:     "M",
            JUMP:   "J",
            JAL:    "J",
            JRET:   "R",
            HALT:   "R",
        }

        def __init__(self) -> None:
            pass

        @staticmethod
        def to_string(opcode: int) -> str:
            return Instruction.Opcode.OPCODE_TO_STRING[opcode]

        @staticmethod
        def to_type(opcode: int) -> str:
            return Instruction.Opcode.OPCODE_TO_TYPE[opcode]


    def __init__(self, inst_bytes: bytes) -> None:
        inst = int.from_bytes(inst_bytes, byteorder='big') # IMEM is a bitfield, it's effectively big-endian
        self.opcode = bits(inst, 31, 26)
        self.pred = bits(inst, 25, 23)
        self.rd = bits(inst, 22, 19)
        self.rs1 = bits(inst, 18, 13)
        self.rs2 = bits(inst, 12, 7)
        self.sign_ext_imm13 = signed(bits(inst, 12, 0), 13)
        self.zero_ext_imm13 = bits(inst, 12, 0)
        self.imm16 = signed(bits(inst, 15, 0), 16)
        self.pred_data = bits(inst, 22, 19)
        self.mem_offset = signed(bits(inst, 12, 0), 13)
        self.jump_offset = signed(bits(inst, 22, 0), 23)
        self.shift = bits(inst, 4, 0)

    """
    Execute the instruction.

    local_regs: The local register file, as a list of registers.
    global_regs: The global register file, as a list of registers.
    predicate: The predicate register, as a bitfield (in a reference to a one-element List)
    mac: MAC output regsiter (as a reference to a one-element List)
    outbox: Outbox to the rasterizer.
    memory: SRAM, in a bytearray.
    call_stack: The global call stack.
    max_call_stack_depth: Max global call stack depth.
    pc: Program counter

    Most parameters are pass-by-reference so the instruction can
    easily modify the calling core's state. Keep in mind: ints are
    immutable and cannot be modified inside a function call.

    Returns: Tuple of (should_continue, next_pc).
        should_continue: True if the program should keep running, False if halted
        next_pc: The PC that should be jumped to for the next instruction.
    """
    def run(self, local_regs: List[int], global_regs: List[int], predicate: List[int],\
            mac: List[int], outbox: List[int], memory: bytearray, call_stack: List[int],\
            max_call_stack_depth: int, pc: int) -> Tuple[bool, int]:
        regs = local_regs + global_regs
        new_pc = pc + 4

        regs = [signed(r, REGISTER_SIZE_BITS) for r in regs] # Make sure everything is sign extended

        if self.pred != predicate[0] and self.opcode not \
            in (self.Opcode.CLRP, self.Opcode.SPR, self.Opcode.JRET, self.Opcode.HALT):
            # Predicate doesn't match, skip
            return (True, new_pc)
        elif self.opcode == self.Opcode.ADD:
            regs[self.rd] = regs[self.rs1] + regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.ADDI:
            regs[self.rd] = regs[self.rs1] + self.sign_ext_imm13
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SUB:
            regs[self.rd] = regs[self.rs1] - regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.MUL:
            regs[self.rd] = (regs[self.rs1] * regs[self.rs2]) >> DECIMAL_POS
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.MULI:
            regs[self.rd] = (regs[self.rs1] * self.sign_ext_imm13) >> DECIMAL_POS
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.AND:
            regs[self.rd] = regs[self.rs1] & regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.ANDI:
            regs[self.rd] = regs[self.rs1] & self.zero_ext_imm13
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.OR:
            regs[self.rd] = regs[self.rs1] | regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.ORI:
            regs[self.rd] = regs[self.rs1] | self.zero_ext_imm13
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.XOR:
            regs[self.rd] = regs[self.rs1] ^ regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.XORI:
            regs[self.rd] = regs[self.rs1] ^ self.zero_ext_imm13
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SLL:
            regs[self.rd] = regs[self.rs1] << self.shift
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SRL:
            regs[self.rs1] &= 0xFFFFFFFF
            regs[self.rd] = regs[self.rs1] >> self.shift
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SRA:
            regs[self.rd] = regs[self.rs1] >> self.shift
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SLLV:
            regs[self.rd] = regs[self.rs1] << (regs[self.rs2] & 0b11111)
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SRLV:
            regs[self.rs1] &= 0xFFFFFFFF
            regs[self.rd] = regs[self.rs1] >> (regs[self.rs2] & 0b11111)
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SRAV:
            regs[self.rd] = regs[self.rs1] >> (regs[self.rs2] & 0b11111)
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.LUI:
            regs[self.rd] = self.imm16 << 16
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.LLI:
            regs[self.rd] = (regs[self.rd] & 0xFFFF0000) | (self.imm16 & 0x0000FFFF)
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.OUT:
            for i, r in enumerate(regs[1:9]): # r0 is $tid, trust me this is right
                outbox[i] = r & 0xFFFFFFFF
        elif self.opcode == self.Opcode.MAC:
            mult = (regs[self.rs1] * regs[self.rs2]) >> DECIMAL_POS
            mac[0] += mult & 0xFFFFFFFF
            mac[0] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.MACCL:
            mac[0] = 0
        elif self.opcode == self.Opcode.MACRD:
            regs[self.rd] = mac[0]
        elif self.opcode == self.Opcode.SPEQ:
            cond = bool(regs[self.rs1] == regs[self.rs2])
            predicate[0] &= ~self.pred_data
            if cond:
                predicate[0] |= self.pred_data
        elif self.opcode == self.Opcode.SPLT:
            cond = bool(regs[self.rs1] < regs[self.rs2])
            predicate[0] &= ~self.pred_data
            if cond:
                predicate[0] |= self.pred_data
        elif self.opcode == self.Opcode.SPLTU:
            cond = bool(unsigned(regs[self.rs1], REGISTER_SIZE_BITS) < unsigned(regs[self.rs2], REGISTER_SIZE_BITS))
            predicate[0] &= ~self.pred_data
            if cond:
                predicate[0] |= self.pred_data
        elif self.opcode == self.Opcode.CLRP:
            predicate[0] &= ~self.pred_data
        elif self.opcode == self.Opcode.SPR:
            regs[self.rd] = predicate[0]
        elif self.opcode == self.Opcode.SRP:
            predicate[0] = regs[self.rd] & 0b111;
        elif self.opcode == self.Opcode.SREQ:
            regs[self.rd] = bool(regs[self.rs1] == regs[self.rs2])
        elif self.opcode == self.Opcode.SRLT:
            regs[self.rd] = bool(regs[self.rs1] < regs[self.rs2])
        elif self.opcode == self.Opcode.SRLTU:
            regs[self.rd] = bool(unsigned(regs[self.rs1], REGISTER_SIZE_BITS) < unsigned(regs[self.rs2], REGISTER_SIZE_BITS))
        elif self.opcode == self.Opcode.LW:
            offset = regs[self.rs1] + self.mem_offset
            if (offset % 4) != 0:
                raise self.MemoryAlignError(f"0x{new_pc-4:08X}: Unaligned lw from address 0x{offset:08X}")
            if offset > len(memory) or offset < 0:
                raise self.MemoryAddressError(f"0x{new_pc-4:08X}: Attempted lw from address 0x{offset:08X} out of bounds for memory size 0x{len(memory):08X}")
            regs[self.rd] = int.from_bytes(memory[offset:offset+4], byteorder="little", signed=False)
        elif self.opcode == self.Opcode.LB:
            offset = regs[self.rs1] + self.mem_offset
            if offset > len(memory) or offset < 0:
                raise self.MemoryAddressError(f"0x{new_pc-4:08X}: Attempted lb from address 0x{offset:08X} out of bounds for memory size 0x{len(memory):08X}")
            regs[self.rd] = signed(int(memory[offset]), 8)
        elif self.opcode == self.Opcode.SW:
            offset = regs[self.rs1] + self.mem_offset
            if (offset % 4) != 0:
                raise self.MemoryAlignError(f"0x{new_pc-4:08X}: Unaligned sw to address 0x{offset:08X}")
            if offset > len(memory) or offset < 0:
                raise self.MemoryAddressError(f"0x{new_pc-4:08X}: Attempted sw to address 0x{offset:08X} out of bounds for memory size 0x{len(memory):08X}")
            memory[offset + 0] = bits(regs[self.rd],  7, 0)
            memory[offset + 1] = bits(regs[self.rd], 15, 8)
            memory[offset + 2] = bits(regs[self.rd], 23, 16)
            memory[offset + 3] = bits(regs[self.rd], 31, 24)
        elif self.opcode == self.Opcode.SB:
            offset = regs[self.rs1] + self.mem_offset
            if offset > len(memory) or offset < 0:
                raise self.MemoryAddressError(f"0x{new_pc-4:08X}: Attempted sb to address 0x{offset:08X} out of bounds for memory size 0x{len(memory):08X}")
            memory[offset] = bits(regs[self.rd], 7, 0)
        elif self.opcode == self.Opcode.JUMP:
            new_pc += self.jump_offset
        elif self.opcode == self.Opcode.JAL:
            if len(call_stack) == max_call_stack_depth:
                raise self.CallStackError("0x{new_pc-4:08X}: Max call stack depth exceeded")
            call_stack.append(new_pc)
            new_pc += self.jump_offset
        elif self.opcode == self.Opcode.JRET:
            if len(call_stack) > 0:
                new_pc = call_stack.pop()
            else:
                print("0x{new_pc-4:08X}: WARNING: jret from empty call stack!")
        elif self.opcode == self.Opcode.HALT:
            return (False, new_pc)
        else:
            raise self.OpcodeError(f"0x{new_pc-4:08X}: Unknown opcode 0x{self.opcode:08X}")

        regs = [unsigned(r, REGISTER_SIZE_BITS) for r in regs]

        # Copy back *without destroying the reference*
        for i, r in enumerate(regs[0:NUM_LOCAL_REGS]):
            local_regs[i] = r
        return (True, new_pc)

    def _str_rtype(self):
        rs1 = f"$r{self.rs1}"
        rs2 = f"$r{self.rs2}"
        rd = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        if self.opcode in (self.Opcode.JRET, self.Opcode.HALT): # 0 operands, no predicate
            return f"{self.Opcode.to_string(self.opcode)}"
        if self.opcode in (self.Opcode.OUT, self.Opcode.MACCL, self.Opcode.JRET, self.Opcode.HALT): # 0 operands
            return f"({pred}) {self.Opcode.to_string(self.opcode)}"
        if self.opcode == self.Opcode.SPR: # 1 operand, no predicate
            return f"{self.Opcode.to_string(self.opcode)} {rd}"
        if self.opcode in (self.Opcode.MACRD, self.Opcode.SPR, self.Opcode.SRP): # 1 operand
            return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}"
        if self.opcode == self.Opcode.MAC: # 2 operands
            return f"({pred}) {self.Opcode.to_string(self.opcode)} {rs1}, {rs2}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}, {rs1}, {rs2}"

    def _str_itype(self):
        rs1 = f"$r{self.rs1}"
        rd = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        if self.opcode in (self.Opcode.ANDI, self.Opcode.ORI, self.Opcode.XORI):
            imm = f"0x{self.zero_ext_imm13:X}"
        else:
            imm = f"0x{unsigned(self.sign_ext_imm13, 13):X}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}, {rs1}, {imm}"

    def _str_dtype(self):
        imm = f"0x{unsigned(self.imm16, 16):X}"
        rd = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}, {imm}"

    def _str_jtype(self):
        offset = f"0x{unsigned(self.jump_offset, 23):X}"
        pred = f"{self.pred:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {offset}"

    def _str_ptype(self):
        rs1 = f"$r{self.rs1}"
        rs2 = f"$r{self.rs2}"
        if self.opcode == self.Opcode.CLRP:
            return f"{self.Opcode.to_string(self.opcode)} {self.pred_data:03b}"
        pred = f"{self.pred:03b}"
        pred_dest = f"$p{int(math.log2(self.pred_data))}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {pred_dest}, {rs1}, {rs2}"

    def _str_mtype(self):
        reg_offset = f"$r{self.rs1}"
        mem_offset = f"{unsigned(self.mem_offset, 13)}"
        rds = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rds}, {mem_offset}[{reg_offset}]"

    def _str_stype(self):
        rs1 = f"$r{self.rs1}"
        shift = f"{self.shift}"
        rd = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}, {rs1}, {shift}"

    def __str__(self) -> str:
        if self.Opcode.to_type(self.opcode) == "R":
            return self._str_rtype()
        if self.Opcode.to_type(self.opcode) == "I":
            return self._str_itype()
        if self.Opcode.to_type(self.opcode) == "D":
            return self._str_dtype()
        if self.Opcode.to_type(self.opcode) == "J":
            return self._str_jtype()
        if self.Opcode.to_type(self.opcode) == "P":
            return self._str_ptype()
        if self.Opcode.to_type(self.opcode) == "M":
            return self._str_mtype()
        if self.Opcode.to_type(self.opcode) == "S":
            return self._str_stype()
        raise self.OpcodeError(f"Unknown opcode 0x{self.opcode:08X}")
