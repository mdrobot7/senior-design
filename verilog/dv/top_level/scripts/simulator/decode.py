from typing import List, Tuple
import math

from common.defs import *
from common.bits import bits, signed

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

    class Opcode:
        ADD = 0x0
        ADDI = 0x1
        SUB = 0x2
        MUL = 0x3
        MULI = 0x4
        AND = 0x5
        ANDI = 0x6
        OR = 0x7
        ORI = 0x8
        XOR = 0x9
        XORI = 0xA
        SLL = 0xB
        SRL = 0xC
        SRA = 0xD
        LUI = 0xE
        LLI = 0xF
        OUT = 0x10
        MAC = 0x11
        MACCL = 0x12
        MACRD = 0x13
        SPEQ = 0x14
        SPLT = 0x15
        CLRP = 0x16
        SPR = 0x17
        SREQ = 0x18
        SRLT = 0x19
        LW = 0x1A
        SW = 0x1B
        SB = 0x1C
        LWV = 0x1D
        SWV = 0x1E
        SBV = 0x1F
        JUMP = 0x20
        HALT = 0x21

        OPCODE_TO_STRING = {
            ADD:    "add",
            ADDI:   "addi",
            SUB:    "sub",
            MUL:    "mul",
            MULI:   "muli",
            AND:    "and",
            ANDI:   "andi",
            OR:     "or",
            ORI:    "ori",
            XOR:    "xor",
            XORI:   "xori",
            SLL:    "sll",
            SRL:    "srl",
            SRA:    "sra",
            LUI:    "lui",
            LLI:    "lli",
            OUT:    "out",
            MAC:    "mac",
            MACCL:  "maccl",
            MACRD:  "macrd",
            SPEQ:   "speq",
            SPLT:   "splt",
            CLRP:   "clrp",
            SPR:    "spr",
            SREQ:   "sreq",
            SRLT:   "srlt",
            LW:     "lw",
            SW:     "sw",
            SB:     "sb",
            LWV:    "lwv",
            SWV:    "swv",
            SBV:    "sbv",
            JUMP:   "jump",
            HALT:   "halt",
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
            LUI:    "D",
            LLI:    "D",
            OUT:    "R",
            MAC:    "R",
            MACCL:  "R",
            MACRD:  "R",
            SPEQ:   "P",
            SPLT:   "P",
            CLRP:   "P",
            SPR:    "R",
            SREQ:   "R",
            SRLT:   "R",
            LW:     "M",
            SW:     "M",
            SB:     "M",
            LWV:    "M",
            SWV:    "M",
            SBV:    "M",
            JUMP:   "J",
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
        self.imm13 = signed(bits(inst, 12, 0), 13)
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
    memory: SRAM, in a list of bytes.
    pc: Program counter

    Most parameters are pass-by-reference so the instruction can
    easily modify the calling core's state. Keep in mind: ints are
    immutable and cannot be modified inside a function call.

    Returns: Tuple of (should_continue, next_pc).
        should_continue: True if the program should keep running, False if halted
        next_pc: The PC that should be jumped to for the next instruction.
    """
    def run(self, local_regs: List[int], global_regs: List[int], predicate: List[int],\
            mac: List[int], outbox: List[int], memory: bytearray, pc: int) -> Tuple[bool, int]:
        regs = local_regs + global_regs
        new_pc = pc + 4

        if self.pred != predicate[0]:
            return (True, new_pc)
        elif self.opcode == self.Opcode.ADD:
            regs[self.rd] = regs[self.rs1] + regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.ADDI:
            regs[self.rd] = regs[self.rs1] + self.imm13
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.SUB:
            regs[self.rd] = regs[self.rs1] - regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.MUL:
            regs[self.rd] = (regs[self.rs1] * regs[self.rs2]) >> DECIMAL_POS
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.MULI:
            regs[self.rd] = (regs[self.rs1] * self.imm13) >> DECIMAL_POS
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.AND:
            regs[self.rd] = regs[self.rs1] & regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.ANDI:
            regs[self.rd] = regs[self.rs1] & self.imm13
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.OR:
            regs[self.rd] = regs[self.rs1] | regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.ORI:
            regs[self.rd] = regs[self.rs1] | self.imm13
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.XOR:
            regs[self.rd] = regs[self.rs1] ^ regs[self.rs2]
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.XORI:
            regs[self.rd] = regs[self.rs1] ^ self.imm13
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
        elif self.opcode == self.Opcode.LUI:
            regs[self.rd] = (regs[self.rd] & 0x0000FFFF) | (self.imm16 << 16)
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.LLI:
            regs[self.rd] = (regs[self.rd] & 0xFFFF0000) | self.imm16
            regs[self.rd] &= 0xFFFFFFFF
        elif self.opcode == self.Opcode.OUT:
            outbox[0] = regs[(self.rs1 + 0) % NUM_LOCAL_REGS]
            outbox[1] = regs[(self.rs1 + 1) % NUM_LOCAL_REGS]
            outbox[2] = regs[(self.rs1 + 2) % NUM_LOCAL_REGS]
            outbox[3] = regs[(self.rs1 + 3) % NUM_LOCAL_REGS]
            outbox[4] = regs[(self.rs1 + 4) % NUM_LOCAL_REGS]
            outbox[5] = regs[(self.rs1 + 5) % NUM_LOCAL_REGS]
            outbox[6] = regs[(self.rs1 + 6) % NUM_LOCAL_REGS]
            outbox[7] = regs[(self.rs1 + 7) % NUM_LOCAL_REGS]
        elif self.opcode == self.Opcode.MAC:
            mult = (regs[self.rs1] * regs[self.rs2]) >> DECIMAL_POS
            mac[0] += mult & 0xFFFFFFFF
        elif self.opcode == self.Opcode.MACCL:
            mac[0] = 0
        elif self.opcode == self.Opcode.MACRD:
            regs[self.rd] = mac[0]
        elif self.opcode == self.Opcode.SPEQ:
            cond = bool(regs[self.rs1] == regs[self.rs2])
            predicate[0] &= (1 << self.pred_data)
            predicate[0] |= (cond << self.pred_data)
        elif self.opcode == self.Opcode.SPLT:
            cond = bool(regs[self.rs1] < regs[self.rs2])
            predicate[0] &= (1 << self.pred_data)
            predicate[0] |= (cond << self.pred_data)
        elif self.opcode == self.Opcode.CLRP:
            predicate[0] &= ~self.pred_data
        elif self.opcode == self.Opcode.SPR:
            regs[self.rd] = predicate[0]
        elif self.opcode == self.Opcode.SREQ:
            regs[self.rd] = bool(self.rs1 == self.rs2)
        elif self.opcode == self.Opcode.SRLT:
            regs[self.rd] = bool(self.rs1 < self.rs2)
        elif self.opcode == self.Opcode.LW:
            offset = regs[self.rs1] + self.mem_offset
            print(offset)
            if (offset % 4) != 0:
                raise self.MemoryAlignError()
            if offset > len(memory):
                raise self.MemoryAddressError()
            regs[self.rd] = int.from_bytes(memory[offset:offset+4], byteorder="little", signed=False)
        elif self.opcode == self.Opcode.SW:
            offset = regs[self.rs1] + self.mem_offset
            if (offset % 4) != 0:
                raise self.MemoryAlignError()
            if offset > len(memory):
                raise self.MemoryAddressError()
            memory[offset + 0] = bits(regs[self.rd],  7, 0)
            memory[offset + 1] = bits(regs[self.rd], 15, 8)
            memory[offset + 2] = bits(regs[self.rd], 23, 16)
            memory[offset + 3] = bits(regs[self.rd], 31, 24)
        elif self.opcode == self.Opcode.SB:
            offset = regs[self.rs1] + self.mem_offset
            if offset > len(memory):
                raise self.MemoryAddressError()
            memory[offset] = bits(regs[self.rd], 7, 0)
        elif self.opcode == self.Opcode.LWV:
            pass # TODO
        elif self.opcode == self.Opcode.SWV:
            pass # TODO
        elif self.opcode == self.Opcode.SBV:
            pass # TODO
        elif self.opcode == self.Opcode.JUMP:
            new_pc += self.jump_offset + 4
        elif self.opcode == self.Opcode.HALT:
            return (False, new_pc)
        else:
            raise self.OpcodeError()

        # Copy back *without destroying the reference*
        for i, r in enumerate(regs[0:NUM_LOCAL_REGS]):
            local_regs[i] = r
        return (True, new_pc)

    def _str_rtype(self):
        rs1 = f"$r{self.rs1}"
        rs2 = f"$r{self.rs2}"
        rd = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        if self.opcode in (self.Opcode.MACCL, self.Opcode.HALT): # 0 operands
            return f"({pred}) {self.Opcode.to_string(self.opcode)}"
        if self.opcode in (self.Opcode.OUT, self.Opcode.MACRD, self.Opcode.SPR): # 1 operand
            return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}"
        if self.opcode == self.Opcode.MAC:
            return f"({pred}) {self.Opcode.to_string(self.opcode)} {rs1}, {rs2}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}, {rs1}, {rs2}"

    def _str_itype(self):
        rs1 = f"$r{self.rs1}"
        imm = f"0x{self.imm13:X}"
        rd = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}, {rs1}, {imm}"

    def _str_dtype(self):
        imm = f"0x{self.imm16:X}"
        rd = f"$r{self.rd}"
        pred = f"{self.pred:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {rd}, {imm}"

    def _str_jtype(self):
        offset = f"0x{self.jump_offset:X}"
        pred = f"{self.pred:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {offset}"

    def _str_ptype(self):
        rs1 = f"$r{self.rs1}"
        rs2 = f"$r{self.rs2}"
        pred_dest = f"$p{int(math.log2(self.pred_data))}"
        pred = f"{self.pred:03b}"
        if self.opcode == self.Opcode.CLRP:
            return f"({pred}) {self.Opcode.to_string(self.opcode)} {self.pred_data:03b}"
        return f"({pred}) {self.Opcode.to_string(self.opcode)} {pred_dest}, {rs1}, {rs2}"

    def _str_mtype(self):
        reg_offset = f"$r{self.rs1}"
        mem_offset = f"{self.mem_offset}"
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
