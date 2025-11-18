import random
from typing import Union
import os

from core import Core
from decode import Instruction
from utils import all_equal

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

    def __init__(self, num_cores: int, program_path: str, memory_path: Union[str, None],
                 global_registers_path: Union[str, None], tid: int) -> None:
        self.pc = 0
        self.cores = [Core(tid, self.global_regs, self.memory) for _ in range(num_cores)]
        self.inst = None

        with open(program_path, "rb") as f:
            self.prog = f.read()
        if len(self.prog) % 4 != 0:
            raise ProgramError("Program length is not a multiple of words.")

        if memory_path:
            with open(memory_path, "rb") as f:
                self.memory = f.read()
        else:
            # 1024 bytes of random nonsense (random.randbytes() doesn't exist in 3.6)
            self.memory = os.urandom(1024)
        if len(self.memory) % 4 != 0:
            raise MemError("Memory length is not a multiple of words.")
        self.memory_size = len(self.memory)

        if global_registers_path:
            with open(global_registers_path, "rb") as f:
                global_regs_bytes = f.read()
            if len(global_regs_bytes) != Core.NUM_GLOBAL_REGS * 4:
                raise RegError("Global reg file provided is not exactly 48 words long.")
            self.global_regs = [global_regs_bytes[i:i+4] for i in range(Core.NUM_GLOBAL_REGS)]
        else:
            self.global_regs = [random.randrange(0, 0xFFFFFFFF, 1) for _ in range(Core.NUM_GLOBAL_REGS)]

    """
    Run the program from the current PC to the end.
    If step() is never called, it runs from the beginning to
    the end.

    Return: True if the program ended successfully (with a halt), False if the program
    ran off of the end of the file.
    """
    def run(self) -> bool:
        try:
            self._read_inst()
            while not self._run_inst():
                pass
        except ProgramError:
            return False
        except:
            raise
        else:
            return True

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
    def _read_inst(self) -> Instruction:
        inst = self.prog[self.pc:self.pc+4]
        return Instruction(inst)

    """
    Run an instruction.

    Return: True if the program ended successfully (with a halt), False if the
    program should continue executing.
    """
    def _run_inst(self) -> bool:
        pcs = [0] * len(self.cores)
        should_continue = [False] * len(self.cores)
        for i, core in enumerate(self.cores):
            should_continue[i], pcs[i] = core.run(self.inst, self.pc)

        if not all_equal(should_continue):
            raise HaltError("Some cores halted, others didn't.")
        if not should_continue[0]:
            return True
        else:
            # Handle jumps: only jump if all cores agree to jump
            self.pc = pcs[0] if all_equal(pcs) else self.pc + 4
            if self.pc > len(self.prog):
                raise ProgramError("Fatal error: PC reached instruction address outside of program memory.")
            return False

    def __str__(self) -> str:
        return \
f"""
PC: {self.pc:08X}
Instruction: {self.inst}
"""
