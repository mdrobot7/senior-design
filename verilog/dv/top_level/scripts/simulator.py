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
argparser.add_argument("shader_program", type=str, help="Path to shader program binary")
argparser.add_argument("-m", type=str, default=None, help="Path to memory binary (little-endian, must be word-aligned)")
argparser.add_argument("-g", type=str, default=None, help="Path to global register file binary (little-endian, must be 48 words long)")
argparser.add_argument("-tid", type=int, default=0, help="Core thread ID")
argparser.add_argument("-i", action="store_true", help="Interactive step-through mode")

args = argparser.parse_args()

if __name__ == "__main__":
    try:
        cc = CoreController(args.shader_program, args.m, args.g, args.tid)
        if args.i:
            while input("Step over [Enter], Quit [Ctrl-D]") and not cc.step():
                print(cc.core_to_str())
                print(cc)
            cc.dump_memory("memory.bin")
        else:
            cc.run()
            print(cc.core_to_str())
            print(cc)
            print("Program completed successfully.")
            cc.dump_memory("memory.bin")
    except (EOFError, KeyboardInterrupt):
        # Ctrl-D quit command or Ctrl-C
        pass
    except Exception as e:
        print(e)
        exit(1)
