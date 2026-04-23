#!/usr/bin/env python3
"""Convert verilog hex (objcopy -O verilog) to SLM word-addressed format for $readmemh."""
import sys

def hex_to_slm(input_file, output_file):
    word_addr = 0
    with open(input_file) as fin, open(output_file, 'w') as fout:
        for line in fin:
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            if line.startswith('@'):
                byte_addr = int(line[1:], 16)
                word_addr = byte_addr // 4  # byte address → word index
            else:
                # Parse space-separated hex bytes (objcopy -O verilog format)
                bytes_list = line.split()
                for i in range(0, len(bytes_list), 4):
                    if i + 3 < len(bytes_list):
                        # Little-endian: bytes [LSB, ..., MSB]
                        word = bytes_list[i+3] + bytes_list[i+2] + bytes_list[i+1] + bytes_list[i]
                        fout.write(f'@{word_addr:08x} {word}\n')
                        word_addr += 1

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.hex> <output.slm>")
        sys.exit(1)
    hex_to_slm(sys.argv[1], sys.argv[2])
    print(f"Converted {sys.argv[1]} -> {sys.argv[2]}")
