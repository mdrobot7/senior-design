import random
from typing import List, Tuple

from common.defs import *
from .decode import Instruction

class Core:
    # Pass all arguments by *reference*
    def __init__(self, tid: int, global_regs: List[int], memory: bytearray, call_stack: List[int],\
                 max_call_stack_depth: int) -> None:
        # Initialize registers to garbage
        self.local_regs = [random.randrange(0, 0xFFFFFFFF, 1) for _ in range(NUM_LOCAL_REGS)]
        self.local_regs[0] = tid & 0xFFFFFFFF
        self.predicate = [random.randrange(0, 0b111, 1)]
        self.mac = [random.randrange(0, 0xFFFFFFFF, 1)]
        self.outbox = [random.randrange(0, 0xFFFFFFFF, 1) for _ in range(NUM_OUTBOX_REGS)]

        # References to global stuff
        self.global_regs = global_regs
        self.memory = memory
        self.call_stack = call_stack
        self.max_call_stack_depth = max_call_stack_depth

    def set_sp(self, sp: int):
        self.local_regs[15] = sp

    def run(self, inst: Instruction, pc: int) -> Tuple[bool, int]:
        return inst.run(self.local_regs, self.global_regs, self.predicate, self.mac,\
                        self.outbox, self.memory, self.call_stack, self.max_call_stack_depth, pc)

    def __str__(self) -> str:
        outbox_strs = [f"{i}: {val:08X}\n" for i, val in enumerate(self.outbox)]
        outbox = ""
        for o in outbox_strs:
            outbox += o

        return \
f"""\
Predicates: ({self.predicate[0]:03b})
MAC: 0x{self.mac[0]:08X}

Register File:
$r0/$tid: {self.local_regs[0]:08X}
     $r1: {self.local_regs[1]:08X}
     $r2: {self.local_regs[2]:08X}
     $r3: {self.local_regs[3]:08X}
     $r4: {self.local_regs[4]:08X}
     $r5: {self.local_regs[5]:08X}
     $r6: {self.local_regs[6]:08X}
     $r7: {self.local_regs[7]:08X}
     $r8: {self.local_regs[8]:08X}
     $r9: {self.local_regs[9]:08X}
    $r10: {self.local_regs[10]:08X}
    $r11: {self.local_regs[11]:08X}
    $r12: {self.local_regs[12]:08X}
    $r13: {self.local_regs[13]:08X}
    $r14: {self.local_regs[14]:08X}
$r15/$at: {self.local_regs[15]:08X}

Outbox:
{outbox}\
"""
