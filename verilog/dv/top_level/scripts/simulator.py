import sys
import os
import argparse

from simulator.core_controller import CoreController

argparser = argparse.ArgumentParser(
    prog="simulator.py",
    description="""
    Shader core simulator -- simulate running shader programs.
    """,
    formatter_class=argparse.RawTextHelpFormatter
)
argparser.add_argument("shader_program.bin", type=str, help="Path to shader program binary")
argparser.add_argument("-m", type=str, default=None, help="Path to memory binary")
argparser.add_argument("-g", type=str, default=None, help="Path to global register file binary")
argparser.add_argument("-tid", type=int, default=0, help="Core thread ID")
argparser.add_argument("-i", action="store_true", help="Interactive step-through mode")

args = argparser.parse_args()

if __name__ == "__main__":
    try:
        # TODO: Disable multi-core simulation for now
        cc = CoreController(1, args.prog, args.m, args.g, args.tid)
        if (args.i)
    except Exception as e:
        print(e)
        exit(1)
