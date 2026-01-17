import cocotb

def main():
    print("This is the main function.")

@cocotb.test()
def run_test(dut):
    pass

main()

import sys
print(sys.argv[1])
sys.exit(1)
