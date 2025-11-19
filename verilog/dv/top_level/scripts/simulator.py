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
argparser.add_argument("-tid", type=int, default=0, help="Core thread ID (default: 0)")
argparser.add_argument("-i", action="store_true", help="Interactive step-through mode")
argparser.add_argument("-n", type=int, default=1, help="Number of jobs to run (default: 1)")

args = argparser.parse_args()

SEPARATOR = "----------------------------------------"

if __name__ == "__main__":
    try:
        for i in range(args.n):
            cc = CoreController(args.shader_program, args.m, args.g, args.tid + i)
            if args.i:
                print(cc.core_to_str())
                print(cc)
                print(SEPARATOR)
                while input("Step over [Enter], Quit [Ctrl-C]") is not None and not cc.step():
                    print(cc.core_to_str())
                    print(cc)
                    print(SEPARATOR)
                cc.dump_memory("memory.bin")
            else:
                cc.run()
                print(cc.core_to_str())
                print(cc)
                print("Program completed successfully.")
                cc.dump_memory("memory.bin")
    except (EOFError, KeyboardInterrupt):
        # Ctrl-D quit command or Ctrl-C
        print()
        pass
    # except Exception as e:
    #     print(e)
    #     exit(1)
