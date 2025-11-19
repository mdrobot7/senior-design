import random
from typing import Union
import os
import copy

from common.defs import *
from .core import Core
from .decode import Instruction

class CoreController:
    class ProgramError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    class MemError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    class RegError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    class HaltError(Exception):
        def __init__(self, *args: object) -> None:
            super().__init__(*args)

    def __init__(self, program_path: str, memory_path: Union[str, None],
                 global_registers_path: Union[str, None], tid: int) -> None:
        self.pc = 0
        self.next_pc = 4
        self.inst = None
        self.next_inst = None

        with open(program_path, "rb") as f:
            self.prog = f.read()
        if len(self.prog) % 4 != 0:
            raise self.ProgramError("Program length is not a multiple of words.")

        if memory_path:
            with open(memory_path, "rb") as f:
                self.memory = bytearray(f.read())
        else:
            # 1024 bytes of random nonsense (random.randbytes() doesn't exist in 3.6)
            self.memory = bytearray(os.urandom(1024))
        if len(self.memory) % 4 != 0:
            raise self.MemError("Memory length is not a multiple of words.")
        self.memory_size = len(self.memory)

        if global_registers_path:
            with open(global_registers_path, "rb") as f:
                global_regs_bytes = f.read()
            if len(global_regs_bytes) != NUM_GLOBAL_REGS * 4:
                raise self.RegError("Global reg file provided is not exactly 48 words long.")
            self.global_regs = [int.from_bytes(global_regs_bytes[i:i+4], byteorder="big") for i in range(0, NUM_GLOBAL_REGS*4, 4)]
        else:
            self.global_regs = [random.randrange(0, 0xFFFFFFFF, 1) for _ in range(NUM_GLOBAL_REGS)]

        self.core = Core(tid, self.global_regs, self.memory)

        self.next_inst = Instruction(self.prog[0:4])

    """
    Run the program from the current PC to the end.
    If step() is never called, it runs from the beginning to
    the end.
    """
    def run(self) -> None:
        try:
            self._read_inst()
            while not self._run_inst():
                pass
        except:
            raise

    """
    Step forward a single instruction.

    Return: True if the program ended with a halt, False otherwise.
    """
    def step(self) -> bool:
        self._read_inst()
        return self._run_inst()

    """
    Read an instruction from IMEM.
    """
    def _read_inst(self) -> None:
        self.pc = self.next_pc
        if self.pc > len(self.prog):
            raise self.ProgramError(f"Fatal error: PC reached instruction address outside of program memory. PC: 0x{self.pc:08X}")
        self.inst = copy.deepcopy(self.next_inst)
        if self.pc + 4 > len(self.prog):
            self.next_inst = None
        else:
            inst_bytes = self.prog[self.pc:self.pc+4]
            self.next_inst = Instruction(inst_bytes)

    """
    Run an instruction.

    Return: True if the program ended successfully (with a halt), False if the
    program should continue executing.
    """
    def _run_inst(self) -> bool:
        should_continue, next_pc = self.core.run(self.inst, self.pc)

        if not should_continue:
            return True
        else:
            self.next_pc = next_pc
            return False

    def dump_memory(self, path: str) -> None:
        with open(path, "wb") as f:
            f.write(self.memory)

    def core_to_str(self) -> str:
        return self.core.__str__()

    def __str__(self) -> str:
        return \
f"""\
PC: {self.pc:08X}
Next Instruction: {self.next_inst}\
"""
