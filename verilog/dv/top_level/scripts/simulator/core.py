import random
from typing import List, Tuple

from common.defs import *
from .decode import Instruction

class Core:
    # Pass all arguments by *reference*
    def __init__(self, tid: int, global_regs: List[int], memory: bytearray) -> None:
        # Initialize registers to garbage
        self.local_regs = [random.randrange(0, 0xFFFFFFFF, 1) for _ in range(NUM_LOCAL_REGS)]
        self.local_regs[0] = tid & 0xFFFFFFFF
        self.predicate = [0] # random.randrange(0, 0b111, 1)
        self.mac = [random.randrange(0, 0xFFFFFFFF, 1)]
        self.outbox = [random.randrange(0, 0xFFFFFFFF, 1) for _ in range(NUM_OUTBOX_REGS)]

        # References to global stuff
        self.global_regs = global_regs
        self.memory = memory

    def run(self, inst: Instruction, pc: int) -> Tuple[bool, int]:
        return inst.run(self.local_regs, self.global_regs, self.predicate, self.mac, self.outbox, self.memory, pc)

    def __str__(self) -> str:
        reg_strs = [f"$r{i}: {val:08X}\n" for i, val in enumerate(self.local_regs)]
        regs = ""
        for r in reg_strs:
            regs += r

        outbox_strs = [f"{i}: {val:08X}\n" for i, val in enumerate(self.outbox)]
        outbox = ""
        for o in outbox_strs:
            outbox += o

        return \
f"""\
Predicates: ({self.predicate[0]:03b})
MAC: 0x{self.mac[0]:08X}

Register File:
{regs}
Outbox:
{outbox}\
"""